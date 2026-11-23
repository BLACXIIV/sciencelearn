import { supabase } from "../lib/supabase";
import type { Assessment, AssessmentKind, Question, QuestionType } from "../types";

// Teacher activity builder — reads questions with answer keys (teacher RLS)
// and writes assessments/questions directly.

export async function fetchLessonAssessments(lessonId: string): Promise<Assessment[]> {
  const { data, error } = await supabase
    .from("assessments").select("*").eq("lesson_id", lessonId).order("created_at");
  if (error) throw error;
  return (data ?? []) as Assessment[];
}

export async function createAssessment(input: {
  lesson_id: string; kind: AssessmentKind; title: string; description?: string;
}): Promise<Assessment> {
  const { data, error } = await supabase.from("assessments")
    .insert({ ...input, description: input.description ?? "" })
    .select().single();
  if (error) throw error;
  return data as Assessment;
}

export async function setAssessmentPublished(id: string, published: boolean): Promise<void> {
  const { error } = await supabase.from("assessments").update({ is_published: published }).eq("id", id);
  if (error) throw error;
}

export async function deleteAssessment(id: string): Promise<void> {
  const { error } = await supabase.from("assessments").delete().eq("id", id);
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
    qtype: q.qtype,
    prompt: q.prompt,
    position: q.position,
    choices: q.choices ?? null,
    correct_index: q.correct_index ?? null,
    answer: q.answer ?? null,
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
