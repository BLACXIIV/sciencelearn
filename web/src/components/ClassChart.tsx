import { Card, RingChart } from "../design-system";
import type { StudentProgress } from "../types";
import "../pages/teacher.css";

/** Class-wide averages as progress rings. Mockup: Lessons is sun, the
 *  other three are blue; a metric with no data shows an empty track + "—". */
export default function ClassChart({ students }: { students: StudentProgress[] }) {
  const avg = (vals: (number | null)[]) => {
    const have = vals.filter((v): v is number => v != null);
    return have.length ? Math.round(have.reduce((a, b) => a + b, 0) / have.length) : null;
  };
  const rings: { label: string; pct: number | null; series: 1 | 2 }[] = [
    { label: "Lessons", pct: avg(students.map((s) => s.lessons_pct)), series: 1 },
    { label: "Quizzes", pct: avg(students.map((s) => s.quizzes_pct)), series: 2 },
  ];
  return (
    <Card variant="white">
      <h3 className="ds-h3" style={{ marginTop: 0 }}>Class averages</h3>
      <p className="ds-caption" style={{ color: "var(--ds-muted)", marginTop: -6 }}>
        Rings fill as students take tests.
      </p>
      <div className="td-rings bento-cols">
        {rings.map((r) => (
          <div key={r.label} className="td-ring">
            <RingChart
              slices={
                r.pct == null
                  ? []
                  : [
                      { value: r.pct, series: r.series },
                      { value: Math.max(0, 100 - r.pct), series: 0 },
                    ]
              }
              size={96}
              thickness={12}
            >
              <span className="ds-title">{r.pct == null ? "—" : `${r.pct}%`}</span>
            </RingChart>
            <span className="ds-caption">{r.label}</span>
          </div>
        ))}
      </div>
    </Card>
  );
}
