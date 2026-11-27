import type { IconName } from "../design-system";
import type { StudentProgress } from "../types";

/** Formats a point value without trailing zeros: 7 → "7", 2.5 → "2.5". */
export function fmtPts(v: number | null | undefined): string {
  if (v == null) return "—";
  return Number.isInteger(v) ? String(v) : (+v.toFixed(2)).toString();
}

export interface StatItem {
  label: string;
  value: string | number;
  icon?: IconName;
  pastel?: "blue" | "yellow" | "purple" | "mint";
}

/** Derives the dashboard stat cards from raw progress rows. Pure — safe to unit test. */
export function computeClassStats(students: StudentProgress[], completedLessons: number): StatItem[] {
  const scored = students.filter((s) => s.quizzes_pct != null);
  const avg = scored.length ? Math.round(scored.reduce((a, s) => a + (s.quizzes_pct ?? 0), 0) / scored.length) : 0;
  const both = students.filter((s) => s.pre_score != null && s.post_score != null);
  const gain = both.length ? Math.round(both.reduce((a, s) => a + (s.post_score! - s.pre_score!), 0) / both.length) : 0;

  return [
    { label: "Total Students", value: students.length, icon: "students", pastel: "blue" },
    { label: "Completed Lessons", value: completedLessons, icon: "done", pastel: "mint" },
    { label: "Average Score", value: `${avg}%`, icon: "progress", pastel: "yellow" },
    { label: "Class Gain", value: `${gain >= 0 ? "+" : ""}${gain}%`, icon: "gain", pastel: "purple" },
  ];
}
