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

// ---------- student report ----------

/** Guard: this student's enrollment row in this class (null = not enrolled). */
export async function fetchMembership(classId: string, studentId: string): Promise<ClassMember | null> {
  const { data, error } = await supabase
    .from("enrollments").select("student_id, status, profiles(full_name)")
    .eq("class_id", classId).eq("student_id", studentId).maybeSingle();
  if (error) throw error;
  return data as unknown as ClassMember | null;
}

export interface ReportAssessment {
  id: string;
  title: string;
  kind: string;
  /** Latest submitted score; null = "Not taken". */
  score: number | null;
  /** false when release is manual and scores_released is still false. */
  released: boolean;
}

/** This class's published assessments + the student's latest score on each.
 *  Teacher RLS reads all attempts; unreleased ones get the "Not released" chip. */
export async function fetchStudentAssessmentRows(
  classId: string, studentId: string,
): Promise<ReportAssessment[]> {
  const [{ data: acts, error: e1 }, { data: atts, error: e2 }] = await Promise.all([
    supabase.from("assessments")
      .select("id, title, kind, release_scores, scores_released, lessons!inner(class_id)")
      .eq("lessons.class_id", classId).eq("is_published", true).order("created_at"),
    supabase.from("attempts")
      .select("assessment_id, score, submitted_at")
      .eq("student_id", studentId).not("submitted_at", "is", null)
      .order("submitted_at", { ascending: false }),
  ]);
  if (e1) throw e1;
  if (e2) throw e2;
  const latest = new Map<string, number>();
  for (const a of (atts ?? []) as { assessment_id: string; score: number | null }[]) {
    if (a.score != null && !latest.has(a.assessment_id)) latest.set(a.assessment_id, a.score);
  }
  return ((acts ?? []) as unknown as {
    id: string; title: string; kind: string;
    release_scores: string; scores_released: boolean;
  }[]).map((a) => ({
    id: a.id,
    title: a.title,
    kind: a.kind,
    score: latest.get(a.id) ?? null,
    released: a.release_scores !== "manual" || a.scores_released === true,
  }));
}

export interface ReportLesson {
  id: string;
  title: string;
  /** 0 when the student never opened the lesson. */
  percent: number;
}

/** This class's published lessons + the student's lesson_progress percent. */
export async function fetchStudentLessonRows(
  classId: string, studentId: string,
): Promise<ReportLesson[]> {
  const [{ data: lessons, error: e1 }, { data: prog, error: e2 }] = await Promise.all([
    supabase.from("lessons").select("id, title")
      .eq("class_id", classId).eq("is_published", true).order("position"),
    supabase.from("lesson_progress").select("lesson_id, percent")
      .eq("student_id", studentId),
  ]);
  if (e1) throw e1;
  if (e2) throw e2;
  const pct = new Map(
    (prog ?? []).map((p) => [p.lesson_id as string, p.percent as number]),
  );
  return (lessons ?? []).map((l) => ({
    id: l.id as string,
    title: l.title as string,
    percent: pct.get(l.id as string) ?? 0,
  }));
}

// ---------- class report ----------

export interface ClassAssessmentRow {
  id: string;
  title: string;
  kind: string;
  /** Mean of each student's LATEST submitted score; null = no attempts. */
  avg: number | null;
  /** Distinct students with at least one submitted attempt. */
  attempts: number;
  /** false when release is manual and scores_released is still false. */
  released: boolean;
}

/** Class-wide assessment rollup: published assessments + every student's
 *  submitted attempts, reduced to latest-per-student average + attempt count. */
export async function fetchClassAssessmentRows(
  classId: string,
): Promise<ClassAssessmentRow[]> {
  const { data: acts, error } = await supabase
    .from("assessments")
    .select("id, title, kind, release_scores, scores_released, lessons!inner(class_id)")
    .eq("lessons.class_id", classId).eq("is_published", true).order("created_at");
  if (error) throw error;
  const rows = (acts ?? []) as unknown as {
    id: string; title: string; kind: string;
    release_scores: string; scores_released: boolean;
  }[];
  const ids = rows.map((a) => a.id);
  if (ids.length === 0) return [];

  const [{ data: atts, error: e2 }, { data: memberRows, error: e3 }] =
    await Promise.all([
      supabase.from("attempts")
        .select("assessment_id, student_id, score, submitted_at")
        .in("assessment_id", ids).not("submitted_at", "is", null)
        .order("submitted_at", { ascending: false }),
      supabase.from("enrollments").select("student_id")
        .eq("class_id", classId).eq("status", "active"),
    ]);
  if (e2) throw e2;
  if (e3) throw e3;
  // Only active members count — removed students' attempts stay out of the
  // rollup, consistent with the rest of the portal.
  const activeIds = new Set(
    ((memberRows ?? []) as { student_id: string }[]).map((m) => m.student_id));

  // Latest score per student per assessment (rows arrive newest-first).
  const latest = new Map<string, Map<string, number>>();
  for (const a of (atts ?? []) as {
    assessment_id: string; student_id: string; score: number | null;
  }[]) {
    if (a.score == null || !activeIds.has(a.student_id)) continue;
    const per = latest.get(a.assessment_id) ?? new Map<string, number>();
    if (!per.has(a.student_id)) per.set(a.student_id, a.score);
    latest.set(a.assessment_id, per);
  }
  return rows.map((a) => {
    const per = latest.get(a.id);
    const scores = per ? [...per.values()] : [];
    const avg = scores.length
      ? Math.round(scores.reduce((s, v) => s + v, 0) / scores.length)
      : null;
    return {
      id: a.id,
      title: a.title,
      kind: a.kind,
      avg,
      attempts: scores.length,
      released: a.release_scores !== "manual" || a.scores_released === true,
    };
  });
}

export interface ClassLessonAvg {
  id: string;
  title: string;
  /** Mean lesson_progress percent across ACTIVE members (unstarted = 0). */
  avg: number;
}

/** Class-wide lesson rollup: published lessons + all member progress rows,
 *  averaged across active enrollments so unstarted lessons count as 0. */
export async function fetchClassLessonAvgs(
  classId: string,
): Promise<ClassLessonAvg[]> {
  const [{ data: lessons, error: e1 }, { data: memberRows, error: e2 }] =
    await Promise.all([
      supabase.from("lessons").select("id, title")
        .eq("class_id", classId).eq("is_published", true).order("position"),
      supabase.from("enrollments").select("student_id")
        .eq("class_id", classId).eq("status", "active"),
    ]);
  if (e1) throw e1;
  if (e2) throw e2;
  // lesson_progress rows outlive enrollment removal — only sum progress from
  // currently-active students so the average can never exceed 100%.
  const activeIds = new Set(
    ((memberRows ?? []) as { student_id: string }[]).map((m) => m.student_id));
  const members = Math.max(1, activeIds.size);
  const rows = (lessons ?? []) as { id: string; title: string }[];
  const ids = rows.map((l) => l.id);
  if (ids.length === 0) return [];

  const { data: prog, error: e3 } = await supabase
    .from("lesson_progress").select("lesson_id, student_id, percent")
    .in("lesson_id", ids);
  if (e3) throw e3;
  const sum = new Map<string, number>();
  for (const p of (prog ?? []) as {
    lesson_id: string; student_id: string; percent: number | null;
  }[]) {
    if (!activeIds.has(p.student_id)) continue;
    sum.set(p.lesson_id, (sum.get(p.lesson_id) ?? 0) + (p.percent ?? 0));
  }
  return rows.map((l) => ({
    id: l.id,
    title: l.title,
    avg: Math.round((sum.get(l.id) ?? 0) / members),
  }));
}

/** Per-lesson assessment counts for the curriculum rows ("N activities").
 *  One joined query grouped client-side — teacher RLS reads all assessments. */
export async function fetchLessonActivityCounts(
  classId: string,
): Promise<Record<string, number>> {
  const { data, error } = await supabase
    .from("assessments")
    .select("lesson_id, lessons!inner(class_id)")
    .eq("lessons.class_id", classId);
  if (error) throw error;
  const counts: Record<string, number> = {};
  for (const row of (data ?? []) as { lesson_id: string | null }[]) {
    if (row.lesson_id) counts[row.lesson_id] = (counts[row.lesson_id] ?? 0) + 1;
  }
  return counts;
}
