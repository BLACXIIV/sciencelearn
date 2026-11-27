/** List/reorder + numeric-input helpers shared by the activity builder. */

/** Move the item at `from` to `to` (indexes clamped to the list). */
export function moveInList<T>(list: T[], from: number, to: number): T[] {
  const n = list.length;
  if (n === 0) return [...list];
  const f = Math.max(0, Math.min(n - 1, from));
  const t = Math.max(0, Math.min(n - 1, to));
  if (f === t) return [...list];
  const next = [...list];
  const [x] = next.splice(f, 1);
  next.splice(t, 0, x);
  return next;
}

/** Client-side shape of "move to part": drop the id from `fromList` and
 *  append it at the end of `toList` (its new position). */
export function moveBetween(
  fromList: string[], toList: string[], id: string,
): { from: string[]; to: string[] } {
  return {
    from: fromList.filter((x) => x !== id),
    to: [...toList.filter((x) => x !== id), id],
  };
}

/** Number-input parse that never returns NaN — blank/unparseable -> fallback. */
export function numOr(value: string, fallback: number): number {
  if (value.trim() === "") return fallback;
  const n = Number(value);
  return Number.isFinite(n) ? n : fallback;
}
