/** Question ordering + answered checks shared by the runner and the preview. */

import type { AnswerValue, QuizQuestion } from "../types";

interface Partish { id: string }
interface Qish { id: string; part_id: string | null; position: number }

/**
 * Part-aware order: questions grouped by their part's position, ordered by
 * question position inside each part; ungrouped items last. Positions are
 * per-part, so a flat order-by-position interleaves parts — this is the
 * canonical fix (runner + preview sort client-side over the fetched parts).
 */
export function sortQuestionsByPart<Q extends Qish, P extends Partish>(
  questions: Q[], parts: P[],
): Q[] {
  const rank = new Map(parts.map((p, i) => [p.id, i]));
  const key = (q: Q) =>
    q.part_id != null ? (rank.get(q.part_id) ?? Number.MAX_SAFE_INTEGER)
                      : Number.MAX_SAFE_INTEGER;
  return [...questions].sort((a, b) =>
    key(a) - key(b) || a.position - b.position || a.id.localeCompare(b.id));
}

/** One question counts as answered when its value clears the type's bar. */
export function isAnswered(q: QuizQuestion, v: AnswerValue | undefined): boolean {
  if (!v) return false;
  if ("t" in v) return v.t.trim() !== "";
  if ("items" in v) return v.items.some((s) => s.trim() !== "");
  if ("sel" in v) {
    // meta.min can be NaN from a legacy editor save — fall back to 1 so the
    // question isn't permanently unanswerable.
    const min = Number.isFinite(q.meta?.min) ? (q.meta!.min as number) : 1;
    return v.sel.length >= min;
  }
  if ("z" in v)
    return v.z.length >= (q.choices ?? []).length && v.z.every((z) => z >= 0);
  if ("o" in v) return v.o.length >= (q.choices ?? []).length;
  return true;
}
