import { supabase } from "../lib/supabase";
import type { Lesson, NewLessonInput } from "../types";
import { uploadToR2 } from "./storage";

export async function fetchLessons(classId: string): Promise<Lesson[]> {
  const { data, error } = await supabase
    .from("lessons").select("*").eq("class_id", classId).order("position");
  if (error) throw error;
  return (data ?? []) as Lesson[];
}

/** Uploads any attached files to R2, then inserts the lesson row into the class. */
export async function createLesson(classId: string, input: NewLessonInput, position: number): Promise<void> {
  const thumbnail_key = input.thumbnail ? await uploadToR2(input.thumbnail, "thumbnails") : null;
  const content_key = input.material ? await uploadToR2(input.material, "lessons") : null;
  const { error } = await supabase.from("lessons").insert({
    class_id: classId,
    title: input.title,
    subject: input.subject,
    objectives: input.objectives,
    thumbnail_key,
    content_key,
    position,
    is_published: false,
  });
  if (error) throw error;
}

export async function setLessonPublished(lessonId: string, publish: boolean): Promise<void> {
  const { error } = await supabase.from("lessons").update({ is_published: publish }).eq("id", lessonId);
  if (error) throw error;
}

/** Edit a lesson's fields; uploads replace the stored R2 keys only when a
 *  new file was picked (absent file = keep the existing key). */
export async function updateLesson(lessonId: string, input: NewLessonInput): Promise<void> {
  const thumbnail_key = input.thumbnail ? await uploadToR2(input.thumbnail, "thumbnails") : undefined;
  const content_key = input.material ? await uploadToR2(input.material, "lessons") : undefined;
  const { error } = await supabase.from("lessons").update({
    title: input.title,
    subject: input.subject,
    objectives: input.objectives,
    ...(thumbnail_key ? { thumbnail_key } : {}),
    ...(content_key ? { content_key } : {}),
  }).eq("id", lessonId);
  if (error) throw error;
}

/** Delete a lesson row. lesson_progress cascades; assessments detach
 *  (ON DELETE SET NULL) — callers must block when activities exist.
 *  R2 objects are intentionally left in place. */
export async function deleteLesson(lessonId: string): Promise<void> {
  const { error } = await supabase.from("lessons").delete().eq("id", lessonId);
  if (error) throw error;
}

/** lesson_id → count of submitted attempts on that lesson's assessments.
 *  Drives the unpublish confirm (warn when students already took it). */
export async function fetchLessonAttemptCounts(
  classId: string,
): Promise<Record<string, number>> {
  const { data: acts, error } = await supabase
    .from("assessments")
    .select("id, lesson_id, lessons!inner(class_id)")
    .eq("lessons.class_id", classId);
  if (error) throw error;
  const rows = (acts ?? []) as { id: string; lesson_id: string | null }[];
  const ids = rows.map((a) => a.id);
  if (ids.length === 0) return {};
  const { data: atts, error: e2 } = await supabase
    .from("attempts").select("assessment_id")
    .in("assessment_id", ids).not("submitted_at", "is", null);
  if (e2) throw e2;
  const lessonOf = new Map(rows.map((a) => [a.id, a.lesson_id] as const));
  const counts: Record<string, number> = {};
  for (const a of (atts ?? []) as { assessment_id: string }[]) {
    const lid = lessonOf.get(a.assessment_id);
    if (lid) counts[lid] = (counts[lid] ?? 0) + 1;
  }
  return counts;
}
