import type { IconName } from "../components/icons";
import type { StudentProgress } from "../types";

export interface StatItem {
  label: string;
  value: string | number;
  icon?: IconName;
  color?: string;
}

/** Derives the dashboard stat cards from raw progress rows. Pure — safe to unit test. */
export function computeClassStats(students: StudentProgress[], completedLessons: number): StatItem[] {
  const scored = students.filter((s) => s.quizzes_pct != null);
  const avg = scored.length ? Math.round(scored.reduce((a, s) => a + (s.quizzes_pct ?? 0), 0) / scored.length) : 0;
  const both = students.filter((s) => s.pre_score != null && s.post_score != null);
  const gain = both.length ? Math.round(both.reduce((a, s) => a + (s.post_score! - s.pre_score!), 0) / both.length) : 0;

  return [
    { label: "Total Students", value: students.length, icon: "students", color: "var(--ds-chart-2)" },
    { label: "Completed Lessons", value: completedLessons, icon: "done", color: "var(--ds-chart-4)" },
    { label: "Average Score", value: `${avg}%`, icon: "progress", color: "var(--ds-chart-1)" },
    { label: "Class Gain", value: `${gain >= 0 ? "+" : ""}${gain}%`, icon: "gain", color: "color-mix(in srgb, var(--ds-pastel-purple) 65%, var(--ds-navy))" },
  ];
}
