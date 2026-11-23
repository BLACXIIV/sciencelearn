import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import type { Lesson, NewLessonInput } from "../types";
import { createLesson, fetchLessons, setLessonPublished } from "../services/lessons";

/** Class-scoped lesson list + the mutations that operate on it. */
export function useLessons(classId: string) {
  const qc = useQueryClient();
  const KEY = ["lessons", classId];
  const invalidate = () => qc.invalidateQueries({ queryKey: KEY });

  const lessons = useQuery({ queryKey: KEY, queryFn: () => fetchLessons(classId) });

  const create = useMutation({
    mutationFn: (input: NewLessonInput) =>
      createLesson(classId, input, (lessons.data?.length ?? 0) + 1),
    onSuccess: invalidate,
  });

  const togglePublish = useMutation({
    mutationFn: (lesson: Lesson) => setLessonPublished(lesson.id, !lesson.is_published),
    onSuccess: invalidate,
  });

  return { lessons, create, togglePublish };
}
