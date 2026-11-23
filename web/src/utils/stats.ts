import type { StudentProgress } from "../types";

export interface StatItem {
  label: string;
  value: string | number;
  icon?: string;
  color?: string;
}

/** Derives the dashboard stat cards from raw progress rows. Pure — safe to unit test. */
export function computeClassStats(students: StudentProgress[], completedLessons: number): StatItem[] {
  const scored = students.filter((s) => s.quizzes_pct != null);
  const avg = scored.length ? Math.round(scored.reduce((a, s) => a + (s.quizzes_pct ?? 0), 0) / scored.length) : 0;
  const both = students.filter((s) => s.pre_score != null && s.post_score != null);
  const gain = both.length ? Math.round(both.reduce((a, s) => a + (s.post_score! - s.pre_score!), 0) / both.length) : 0;

  return [
    { label: "Total Students", value: students.length, icon: "👥", color: "#2563eb" },
    { label: "Completed Lessons", value: completedLessons, icon: "✅", color: "#15803d" },
    { label: "Average Score", value: `${avg}%`, icon: "📊", color: "#d97706" },
    { label: "Class Gain", value: `${gain >= 0 ? "+" : ""}${gain}%`, icon: "📈", color: "#7c3aed" },
  ];
}
