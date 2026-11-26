import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import type { Lesson, NewLessonInput } from "../types";
import {
  createLesson, deleteLesson, fetchLessonAttemptCounts, fetchLessons,
  setLessonPublished, updateLesson,
} from "../services/lessons";
import { fetchLessonActivityCounts } from "../services/classes";

/** Class-scoped lesson list + the mutations that operate on it. */
export function useLessons(classId: string) {
  const qc = useQueryClient();
  const KEY = ["lessons", classId];
  const invalidate = () => qc.invalidateQueries({ queryKey: KEY });

  const lessons = useQuery({ queryKey: KEY, queryFn: () => fetchLessons(classId) });
  const counts = useQuery({
    queryKey: ["lesson-activity-counts", classId],
    queryFn: () => fetchLessonActivityCounts(classId),
  });

  const create = useMutation({
    mutationFn: (input: NewLessonInput) =>
      createLesson(classId, input, (lessons.data?.length ?? 0) + 1),
    onSuccess: invalidate,
  });

  const togglePublish = useMutation({
    mutationFn: (lesson: Lesson) => setLessonPublished(lesson.id, !lesson.is_published),
    onSuccess: invalidate,
  });

  const update = useMutation({
    mutationFn: ({ id, input }: { id: string; input: NewLessonInput }) =>
      updateLesson(id, input),
    onSuccess: invalidate,
  });

  const remove = useMutation({
    mutationFn: (id: string) => deleteLesson(id),
    onSuccess: invalidate,
  });

  // Submitted-attempt count per lesson — gates the unpublish confirm.
  const attemptCounts = useQuery({
    queryKey: ["lesson-attempt-counts", classId],
    queryFn: () => fetchLessonAttemptCounts(classId),
  });

  return { lessons, counts, attemptCounts, create, update, remove, togglePublish };
}
