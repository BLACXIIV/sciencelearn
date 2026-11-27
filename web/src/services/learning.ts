import { supabase } from "../lib/supabase";
import type {
  AnswerValue, Assessment, AssessmentPart, AttemptResult, Flashcard, Formula, KeyTerm,
  QuizQuestion, Lesson, LessonWithProgress, RecentActivity, ReviewResult, StudentProgress, Subject,
} from "../types";

// Student-facing data — mirrors the mobile app's Repo (same tables, same RLS).

export async function fetchMyProgress(uid: string): Promise<StudentProgress | null> {
  const { data, error } = await supabase
    .from("v_student_progress").select("*").eq("student_id", uid).maybeSingle();
  if (error) throw error;
  return data as StudentProgress | null;
}

export async function fetchRecentActivity(uid: string): Promise<RecentActivity[]> {
  const { data, error } = await supabase
    .from("lesson_progress")
    .select("percent, updated_at, lessons(title)")
    .eq("student_id", uid)
    .order("updated_at", { ascending: false })
    .limit(3);
  if (error) throw error;
  return (data ?? []) as unknown as RecentActivity[];
}

export async function fetchPublishedLessons(subject?: Subject | null, classId?: string): Promise<LessonWithProgress[]> {
  let q = supabase.from("lessons").select("*, lesson_progress(percent)").eq("is_published", true);
  if (classId) q = q.eq("class_id", classId);
  if (subject) q = q.eq("subject", subject);
  const { data, error } = await q.order("position");
  if (error) throw error;
  return (data ?? []) as unknown as LessonWithProgress[];
}

export async function fetchLesson(id: string): Promise<Lesson> {
  const { data, error } = await supabase.from("lessons").select("*").eq("id", id).single();
  if (error) throw error;
  return data as Lesson;
}

export async function setLessonProgress(uid: string, lessonId: string, percent: number): Promise<void> {
  const { error } = await supabase.from("lesson_progress").upsert({
    student_id: uid,
    lesson_id: lessonId,
    percent,
    updated_at: new Date().toISOString(),
    ...(percent >= 100 ? { completed_at: new Date().toISOString() } : {}),
  });
  if (error) throw error;
}

export async function fetchAssessments(): Promise<Assessment[]> {
  const { data, error } = await supabase
    .from("assessments").select("*").eq("is_published", true).order("created_at");
  if (error) throw error;
  return (data ?? []) as Assessment[];
}

/** assessment_id -> latest released score for this student.
 *  RLS only returns released attempts, so withheld scores never reach the client. */
export async function fetchMyAttemptScores(uid: string): Promise<Record<string, number>> {
  const { data, error } = await supabase
    .from("attempts").select("assessment_id, score, submitted_at")
    .eq("student_id", uid).order("submitted_at");
  if (error) throw error;
  const m: Record<string, number> = {};
  for (const r of data ?? []) {
    if (r.score != null) m[r.assessment_id as string] = r.score as number;
  }
  return m;
}

export async function fetchQuestions(assessmentId: string): Promise<QuizQuestion[]> {
  const { data, error } = await supabase
    .from("questions_public").select("*").eq("assessment_id", assessmentId).order("position");
  if (error) throw error;
  return (data ?? []) as QuizQuestion[];
}

/** Parts of a published assessment (student view — directions + mode, no keys). */
export async function fetchPartsPublic(assessmentId: string): Promise<AssessmentPart[]> {
  const { data, error } = await supabase
    .from("parts_public").select("*").eq("assessment_id", assessmentId).order("position");
  if (error) throw error;
  return (data ?? []) as AssessmentPart[];
}

export async function submitAttempt(assessmentId: string, answers: Record<string, AnswerValue>): Promise<AttemptResult> {
  const { data, error } = await supabase
    .rpc("submit_attempt", { p_assessment: assessmentId, p_answers: answers });
  if (error) throw error;
  const r = data as AttemptResult & { error?: string };
  if (r?.error) throw new Error(r.error);
  return r;
}

/** Post-submit review: attempted/released/score + per-question picks & keys
 *  (keys only once scores are released — see migration 0020). */
export async function reviewAttempt(assessmentId: string): Promise<ReviewResult> {
  const { data, error } = await supabase
    .rpc("review_attempt", { p_assessment: assessmentId });
  if (error) throw error;
  return data as ReviewResult;
}

/** Published activities inside one lesson (student view, RLS hides drafts). */
export async function fetchLessonActivities(lessonId: string): Promise<Assessment[]> {
  const { data, error } = await supabase
    .from("assessments").select("*").eq("lesson_id", lessonId)
    .eq("is_published", true).order("created_at");
  if (error) throw error;
  return (data ?? []) as Assessment[];
}

export async function fetchFlashcards(): Promise<Flashcard[]> {
  const { data, error } = await supabase.from("flashcards").select("*");
  if (error) throw error;
  return (data ?? []) as Flashcard[];
}

export async function fetchFormulas(): Promise<Formula[]> {
  const { data, error } = await supabase.from("formulas").select("*");
  if (error) throw error;
  return (data ?? []) as Formula[];
}

export async function fetchKeyTerms(): Promise<KeyTerm[]> {
  const { data, error } = await supabase.from("key_terms").select("*");
  if (error) throw error;
  return (data ?? []) as KeyTerm[];
}
