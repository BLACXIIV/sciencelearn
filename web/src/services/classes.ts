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
const PICKED_ID_KEY = "sl-class-id";

/** Set when the user leaves /select-classroom by entering (or creating) a class.
 *  sessionStorage = survives reloads within the tab session; a fresh tab
 *  re-gates, matching "choose a classroom after sign-in". The id lets /teacher
 *  deep-route straight into the picked class portal. */
export const markClassPicked = (classId?: string) => {
  sessionStorage.setItem(PICKED_KEY, "1");
  if (classId) sessionStorage.setItem(PICKED_ID_KEY, classId);
};

/** Route guards bounce to /select-classroom until this is true. */
export const hasPickedClass = () => sessionStorage.getItem(PICKED_KEY) === "1";

/** The class the teacher opened this session, if any. */
export const pickedClassId = () => sessionStorage.getItem(PICKED_ID_KEY);

/** Forget the picked class (sign-out, class deleted) — re-gates the portal. */
export const clearPickedClass = () => {
  sessionStorage.removeItem(PICKED_KEY);
  sessionStorage.removeItem(PICKED_ID_KEY);
};

// ---------- class-scoped dashboard ----------

/** One row per active member: lessons/quiz/pre-post metrics filtered to
 *  this class's own lessons (v_class_student_progress, migration 0011). */
export interface ClassStudentProgress {
  class_id: string;
  student_id: string;
  full_name: string;
  lessons_pct: number;
  quizzes_pct: number | null;
  pre_score: number | null;
  post_score: number | null;
}

export async function fetchClassStudentProgress(classId: string): Promise<ClassStudentProgress[]> {
  const { data, error } = await supabase
    .from("v_class_student_progress")
    .select("*")
    .eq("class_id", classId)
    .order("full_name");
  if (error) throw error;
  return (data ?? []) as ClassStudentProgress[];
}

/** Fully-completed lesson_progress rows inside this class only. */
export async function fetchClassCompletedCount(classId: string): Promise<number> {
  const { count, error } = await supabase
    .from("lesson_progress")
    .select("*, lessons!inner(class_id)", { count: "exact", head: true })
    .eq("lessons.class_id", classId)
    .eq("percent", 100);
  if (error) throw error;
  return count ?? 0;
}
