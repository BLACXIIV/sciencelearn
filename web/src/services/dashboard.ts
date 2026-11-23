import { supabase } from "../lib/supabase";
import type { ClassDashboard, StudentProgress } from "../types";

/** Class-wide student progress plus the count of fully completed lesson_progress rows. */
export async function fetchClassDashboard(): Promise<ClassDashboard> {
  const [{ data: students, error: e1 }, { count, error: e2 }] = await Promise.all([
    supabase.from("v_student_progress").select("*").order("full_name"),
    supabase.from("lesson_progress").select("*", { count: "exact", head: true }).eq("percent", 100),
  ]);
  if (e1 || e2) throw e1 ?? e2;
  return { students: (students ?? []) as StudentProgress[], completedLessons: count ?? 0 };
}
