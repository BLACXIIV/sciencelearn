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
  classes: { name: string; code: string } | null;
}

export async function fetchEnrolledClasses(): Promise<EnrolledClass[]> {
  const { data, error } = await supabase
    .from("enrollments").select("class_id, status, classes(name, code)");
  if (error) throw error;
  return (data ?? []) as unknown as EnrolledClass[];
}

/** Returns {name, status} — 'pending' means the teacher must approve. */
export async function joinClass(code: string): Promise<{ name: string; status: string }> {
  const { data, error } = await supabase.rpc("join_class", { p_code: code });
  if (error) throw error;
  const r = data as { error?: string; name?: string; status?: string };
  if (r?.error) throw new Error(r.error);
  return { name: r?.name ?? "class", status: r?.status ?? "active" };
}
