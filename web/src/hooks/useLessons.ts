import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import type { Lesson, NewLessonInput } from "../types";
import { createLesson, fetchLessons, setLessonPublished } from "../services/lessons";

const KEY = ["lessons"];

/** Lesson list + the mutations that operate on it. Components stay free of query/service details. */
export function useLessons() {
  const qc = useQueryClient();
  const invalidate = () => qc.invalidateQueries({ queryKey: KEY });

  const lessons = useQuery({ queryKey: KEY, queryFn: fetchLessons });

  const create = useMutation({
    mutationFn: (input: NewLessonInput) => createLesson(input, (lessons.data?.length ?? 0) + 1),
    onSuccess: invalidate,
  });

  const togglePublish = useMutation({
    mutationFn: (lesson: Lesson) => setLessonPublished(lesson.id, !lesson.is_published),
    onSuccess: invalidate,
  });

  return { lessons, create, togglePublish };
}
