import { useQuery } from "@tanstack/react-query";
import { useClassDashboard } from "../hooks/useClassDashboard";
import { fetchMyClasses } from "../services/classes";
import { Card, EmptyState, RingChart, StatCard } from "../design-system";
import StudentProgressList from "../components/StudentProgressList";
import type { StudentProgress } from "../types";
import "./teacher.css";

/** Class-wide averages rendered as progress rings (same visual system as student progress). */
function ClassChart({ students }: { students: StudentProgress[] }) {
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

export default function Dashboard() {
  const { data, stats, isLoading, error } = useClassDashboard();
  const classes = useQuery({ queryKey: ["my-classes"], queryFn: fetchMyClasses });
  const allStats = [
    ...stats,
    { label: "Classes", value: classes.data?.length ?? 0, icon: "students" as const, pastel: "mint" as const },
  ];

  if (isLoading) return <p className="ds-body">Loading class dashboard…</p>;
  if (error) return <p className="td-err">{String(error)}</p>;

  const students = data?.students ?? [];
  return (
    <>
      <div className="td-stats">
        {allStats.map((s) => (
          <StatCard key={s.label} icon={s.icon!} value={String(s.value)} label={s.label} pastelColor={s.pastel} />
        ))}
      </div>
      <ClassChart students={students} />
      <h2 className="ds-h2 td-heading">Student Performance</h2>
      {students.length === 0 ? (
        <Card variant="white">
          <EmptyState icon="students" title="No students yet" body="Students appear here after they join a class." />
        </Card>
      ) : (
        <StudentProgressList students={students} />
      )}
    </>
  );
}
