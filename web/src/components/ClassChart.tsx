import { Card, EmptyState, RingChart } from "../design-system";
import type { StudentProgress } from "../types";
import "../pages/teacher.css";

/** Class-wide averages rendered as progress rings (same visual system as student progress). */
export default function ClassChart({ students }: { students: StudentProgress[] }) {
  const avg = (vals: (number | null)[]) => {
    const have = vals.filter((v): v is number => v != null);
    return have.length ? Math.round(have.reduce((a, b) => a + b, 0) / have.length) : null;
  };
  const rings: { label: string; pct: number | null; series: 1 | 2 | 3 | 4 }[] = [
    { label: "Lessons", pct: avg(students.map((s) => s.lessons_pct)), series: 1 },
    { label: "Quizzes", pct: avg(students.map((s) => s.quizzes_pct)), series: 2 },
    { label: "Pre-Test", pct: avg(students.map((s) => s.pre_score)), series: 3 },
    { label: "Post-Test", pct: avg(students.map((s) => s.post_score)), series: 4 },
  ];
  return (
    <Card variant="white">
      <h3 className="ds-h3" style={{ marginTop: 0 }}>Class Averages</h3>
      {students.length === 0 ? (
        <EmptyState icon="students" title="No student data yet" />
      ) : (
        <div className="td-rings">
          {rings.map((r) => (
            <div key={r.label} className="td-ring">
              <RingChart
                slices={[
                  { value: r.pct ?? 0, series: r.series },
                  { value: Math.max(0, 100 - (r.pct ?? 0)), series: 0 },
                ]}
                size={84}
              >
                <span className="ds-label">{r.pct ?? 0}%</span>
              </RingChart>
              <span className="ds-caption">{r.pct == null ? `${r.label} (no data)` : r.label}</span>
            </div>
          ))}
        </div>
      )}
    </Card>
  );
}
