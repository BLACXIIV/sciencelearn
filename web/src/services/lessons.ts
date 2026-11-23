import { supabase } from "../lib/supabase";
import type { Lesson, NewLessonInput } from "../types";
import { uploadToR2 } from "./storage";

export async function fetchLessons(): Promise<Lesson[]> {
  const { data, error } = await supabase.from("lessons").select("*").order("position");
  if (error) throw error;
  return (data ?? []) as Lesson[];
}

/** Uploads any attached files to R2, then inserts the lesson row. */
export async function createLesson(input: NewLessonInput, position: number): Promise<void> {
  const thumbnail_key = input.thumbnail ? await uploadToR2(input.thumbnail, "thumbnails") : null;
  const content_key = input.material ? await uploadToR2(input.material, "lessons") : null;
  const { error } = await supabase.from("lessons").insert({
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
