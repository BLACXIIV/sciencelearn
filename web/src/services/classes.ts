import { supabase } from "../lib/supabase";

// Class management — teacher creates classes (auto join code, join_policy
// 'open'|'approval'), students join by code via the join_class RPC.
// enrollments.status: 'active' | 'pending'.

export interface ClassRow {
  id: string;
  name: string;
  code: string;
  teacher_id: string;
  join_policy: "open" | "approval";
  enrollments: { status: string }[];
}

export interface ClassMember {
  student_id: string;
  status: "active" | "pending";
  profiles: { full_name: string } | null;
}

export async function fetchMyClasses(): Promise<ClassRow[]> {
  const uid = (await supabase.auth.getUser()).data.user?.id;
  const { data, error } = await supabase
    .from("classes")
    .select("id, name, code, teacher_id, join_policy, enrollments(status)")
    .eq("teacher_id", uid ?? "")
    .order("created_at");
  if (error) throw error;
  return (data ?? []) as unknown as ClassRow[];
}

export async function fetchClass(id: string): Promise<ClassRow> {
  const { data, error } = await supabase
    .from("classes")
    .select("id, name, code, teacher_id, join_policy, enrollments(status)")
    .eq("id", id).single();
  if (error) throw error;
  return data as unknown as ClassRow;
}

export async function createClass(name: string, joinPolicy: "open" | "approval"): Promise<ClassRow> {
  const uid = (await supabase.auth.getUser()).data.user?.id;
  const { data, error } = await supabase
    .from("classes").insert({ name, teacher_id: uid, join_policy: joinPolicy })
    .select("id, name, code, teacher_id, join_policy").single();
  if (error) throw error;
  return data as ClassRow;
}

export async function fetchClassMembers(classId: string): Promise<ClassMember[]> {
  const { data, error } = await supabase
    .from("enrollments").select("student_id, status, profiles(full_name)").eq("class_id", classId);
  if (error) throw error;
  return (data ?? []) as unknown as ClassMember[];
}

export async function approveMember(classId: string, studentId: string): Promise<void> {
  const { error } = await supabase
    .from("enrollments").update({ status: "active" })
    .eq("class_id", classId).eq("student_id", studentId);
  if (error) throw error;
}

/** Reject a pending request or remove an enrolled student. */
export async function removeMember(classId: string, studentId: string): Promise<void> {
  const { error } = await supabase
    .from("enrollments").delete()
    .eq("class_id", classId).eq("student_id", studentId);
  if (error) throw error;
}

export async function deleteClass(id: string): Promise<void> {
  const { error } = await supabase.from("classes").delete().eq("id", id);
  if (error) throw error;
}

// ---------- student ----------

export interface EnrolledClass {
  class_id: string;
  status: "active" | "pending";
  classes: {
    name: string;
    code: string;
    profiles: { full_name: string } | null;
    enrollments: { status: string }[];
  } | null;
}

export async function fetchEnrolledClasses(): Promise<EnrolledClass[]> {
  const { data, error } = await supabase
    .from("enrollments")
    .select("class_id, status, classes(name, code, profiles!classes_teacher_id_fkey(full_name), enrollments(status))");
  if (error) throw error;
  return (data ?? []) as unknown as EnrolledClass[];
}

/** class_id -> count of published assessments the student hasn't attempted
 *  ("N to do" on the picker's class cards). */
export async function fetchAwaitingByClass(): Promise<Record<string, number>> {
  const [{ data: acts, error: e1 }, { data: done, error: e2 }] = await Promise.all([
    supabase.from("assessments").select("id, lessons!inner(class_id)").eq("is_published", true),
    supabase.from("attempts").select("assessment_id"),
  ]);
  if (e1) throw e1;
  if (e2) throw e2;
  const doneSet = new Set((done ?? []).map((r) => (r as { assessment_id: string }).assessment_id));
  const m: Record<string, number> = {};
  for (const a of (acts ?? []) as unknown as {
    id: string;
    lessons: { class_id: string | null } | { class_id: string | null }[] | null;
  }[]) {
    if (doneSet.has(a.id)) continue;
    const lesson = Array.isArray(a.lessons) ? a.lessons[0] : a.lessons;
    const cid = lesson?.class_id;
    if (!cid) continue;
    m[cid] = (m[cid] ?? 0) + 1;
  }
  return m;
}

/** Returns {name, status} — 'pending' means the teacher must approve. */
export async function joinClass(code: string): Promise<{ name: string; status: string }> {
  const { data, error } = await supabase.rpc("join_class", { p_code: code });
  if (error) throw error;
  const r = data as { error?: string; name?: string; status?: string };
  if (r?.error) throw new Error(r.error);
  return { name: r?.name ?? "class", status: r?.status ?? "active" };
}

// ---------- classroom gate ----------

const PICKED_KEY = "sl-class-picked";

/** Set when the user leaves /select-classroom by entering (or creating) a class.
 *  sessionStorage = survives reloads within the tab session; a fresh tab
 *  re-gates, matching "choose a classroom after sign-in". */
export const markClassPicked = () => sessionStorage.setItem(PICKED_KEY, "1");

/** Route guards bounce to /select-classroom until this is true. */
export const hasPickedClass = () => sessionStorage.getItem(PICKED_KEY) === "1";
