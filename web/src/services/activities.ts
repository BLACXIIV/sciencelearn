import { supabase } from "../lib/supabase";
import { cleanDeep, cleanText } from "../utils/text";
import type {
  ActivityMode, Assessment, AssessmentKind, AssessmentPart, Question, QuestionType,
  QuizQuestion,
} from "../types";

// Teacher activity builder — reads questions with answer keys (teacher RLS)
// and writes assessments/questions directly.

export async function fetchLessonAssessments(lessonId: string): Promise<Assessment[]> {
  const { data, error } = await supabase
    .from("assessments").select("*, assessment_parts(count), questions(count)")
    .eq("lesson_id", lessonId).order("created_at");
  if (error) throw error;
  type Row = Assessment & {
    assessment_parts?: { count: number }[];
    questions?: { count: number }[];
  };
  return ((data ?? []) as Row[]).map(({ assessment_parts, questions, ...a }) => ({
    ...a,
    part_count: assessment_parts?.[0]?.count ?? 0,
    question_count: questions?.[0]?.count ?? 0,
  }));
}

/** One assessment row — the builder header reads title/release/publish. */
export async function fetchAssessment(id: string): Promise<Assessment> {
  const { data, error } = await supabase
    .from("assessments").select("*").eq("id", id).single();
  if (error) throw error;
  return data as Assessment;
}

export async function createAssessment(input: {
  lesson_id: string; kind: AssessmentKind; mode?: ActivityMode;
  title: string; description?: string;
}): Promise<Assessment> {
  const { data, error } = await supabase.from("assessments")
    .insert({
      ...input,
      title: cleanText(input.title),
      description: cleanText(input.description ?? ""),
    })
    .select().single();
  if (error) throw error;
  return data as Assessment;
}

export async function setAssessmentPublished(id: string, published: boolean): Promise<void> {
  const { error } = await supabase.from("assessments").update({ is_published: published }).eq("id", id);
  if (error) throw error;
}

export async function setScoreRelease(id: string, mode: "immediate" | "manual"): Promise<void> {
  const { error } = await supabase.from("assessments").update({ release_scores: mode }).eq("id", id);
  if (error) throw error;
}

export async function releaseScores(id: string): Promise<void> {
  const { error } = await supabase.from("assessments").update({ scores_released: true }).eq("id", id);
  if (error) throw error;
}

export async function deleteAssessment(id: string): Promise<void> {
  const { error } = await supabase.from("assessments").delete().eq("id", id);
  if (error) throw error;
}

// ---------- parts (LP-style "Activity 1 / Activity 2" inside an activity) ----------

export async function fetchParts(assessmentId: string): Promise<AssessmentPart[]> {
  const { data, error } = await supabase
    .from("assessment_parts").select("*")
    .eq("assessment_id", assessmentId).order("position");
  if (error) throw error;
  return (data ?? []) as AssessmentPart[];
}

export interface PartInput {
  id?: string;
  assessment_id: string;
  title: string;
  directions: string;
  mode: ActivityMode;
  scored: boolean;
  /** Points each item in this part is worth. */
  points: number;
  position: number;
}

/** Insert/update a part — resolves to the part's id (for selecting a new one). */
export async function upsertPart(p: PartInput): Promise<string> {
  const row = {
    assessment_id: p.assessment_id,
    title: cleanText(p.title),
    directions: cleanText(p.directions),
    mode: p.mode,
    scored: p.scored,
    points: p.points,
    position: p.position,
  };
  const { data, error } = p.id
    ? await supabase.from("assessment_parts").update(row).eq("id", p.id)
        .select("id").single()
    : await supabase.from("assessment_parts").insert(row).select("id").single();
  if (error) throw error;
  return (data as { id: string }).id;
}

/** Deletes the part AND its questions (FK cascade). */
export async function deletePart(id: string): Promise<void> {
  const { error } = await supabase.from("assessment_parts").delete().eq("id", id);
  if (error) throw error;
}

export async function fetchQuestionsFull(assessmentId: string): Promise<Question[]> {
  const { data, error } = await supabase
    .from("questions").select("*").eq("assessment_id", assessmentId).order("position");
  if (error) throw error;
  return (data ?? []) as Question[];
}

export interface QuestionInput {
  id?: string;
  assessment_id: string;
  part_id?: string | null;
  qtype: QuestionType;
  prompt: string;
  position: number;
  choices?: string[] | null;
  correct_index?: number | null;
  answer?: Question["answer"];
}

export async function upsertQuestion(q: QuestionInput): Promise<void> {
  const row = {
    assessment_id: q.assessment_id,
    part_id: q.part_id ?? null,
    qtype: q.qtype,
    prompt: cleanText(q.prompt),
    position: q.position,
    choices: q.choices?.map(cleanText) ?? null,
    correct_index: q.correct_index ?? null,
    answer: q.answer ? cleanDeep(q.answer) : null,
  };
  const { error } = q.id
    ? await supabase.from("questions").update(row).eq("id", q.id)
    : await supabase.from("questions").insert(row);
  if (error) throw error;
}

export async function deleteQuestion(id: string): Promise<void> {
  const { error } = await supabase.from("questions").delete().eq("id", id);
  if (error) throw error;
}

// ---------- builder helpers (0032) ----------

/** UPDATEs title/description only — everything else on the row is untouched. */
export async function renameAssessment(
  id: string, fields: { title: string; description?: string },
): Promise<void> {
  const row: { title: string; description?: string } = {
    title: cleanText(fields.title),
  };
  if (fields.description !== undefined)
    row.description = cleanText(fields.description);
  const { error } = await supabase.from("assessments").update(row).eq("id", id);
  if (error) throw error;
}

/** Teacher-readable count of attempts (drives the delete guard pre-check). */
export async function assessmentAttemptCount(id: string): Promise<number> {
  const { count, error } = await supabase.from("attempts")
    .select("id", { count: "exact", head: true }).eq("assessment_id", id);
  if (error) throw error;
  return count ?? 0;
}

/** Reassigns a question to a different part, appended at `position`. */
export async function moveQuestionToPart(
  questionId: string, partId: string | null, position: number,
): Promise<void> {
  const { error } = await supabase.from("questions")
    .update({ part_id: partId, position }).eq("id", questionId);
  if (error) throw error;
}

/** Rewrites part positions to the dense order given (ids in display order). */
export async function reorderPartPositions(orderedIds: string[]): Promise<void> {
  for (let i = 0; i < orderedIds.length; i++) {
    const { error } = await supabase.from("assessment_parts")
      .update({ position: i }).eq("id", orderedIds[i]);
    if (error) throw error;
  }
}

/** Rewrites question positions within one scope to the dense order given. */
export async function reorderQuestionPositions(orderedIds: string[]): Promise<void> {
  for (let i = 0; i < orderedIds.length; i++) {
    const { error } = await supabase.from("questions")
      .update({ position: i }).eq("id", orderedIds[i]);
    if (error) throw error;
  }
}

export interface PreviewPayload {
  parts: AssessmentPart[];
  questions: QuizQuestion[];
}

/**
 * Teacher preview — same student-view payload as questions_public +
 * parts_public, via the teacher-gated RPC (0032). Fails gracefully until
 * the migration lands.
 */
export async function fetchPreview(assessmentId: string): Promise<PreviewPayload> {
  const { data, error } = await supabase
    .rpc("preview_questions", { p_assessment: assessmentId });
  if (error) {
    if (error.code === "PGRST202"
        || /could not find|does not exist/i.test(error.message))
      throw new Error("Preview is not available yet");
    throw error;
  }
  const payload = data as {
    error?: string; parts?: AssessmentPart[]; questions?: QuizQuestion[];
  } | null;
  if (payload?.error) throw new Error(payload.error);
  return {
    parts: payload?.parts ?? [],
    questions: payload?.questions ?? [],
  };
}
