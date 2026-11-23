import { useQuery } from "@tanstack/react-query";
import { useClassDashboard } from "../hooks/useClassDashboard";
import { fetchMyClasses } from "../services/classes";
import Ring from "../components/Ring";
import StatCards from "../components/StatCards";
import StudentProgressList from "../components/StudentProgressList";
import type { StudentProgress } from "../types";

/** Class-wide averages rendered as progress rings (same visual system as student progress). */
function ClassChart({ students }: { students: StudentProgress[] }) {
  const avg = (vals: (number | null)[]) => {
    const have = vals.filter((v): v is number => v != null);
    return have.length ? Math.round(have.reduce((a, b) => a + b, 0) / have.length) : null;
  };
  const rings = [
    { label: "Lessons", pct: avg(students.map((s) => s.lessons_pct)), color: "#f5c518" },
    { label: "Quizzes", pct: avg(students.map((s) => s.quizzes_pct)), color: "#4c8dff" },
    { label: "Pre-Test", pct: avg(students.map((s) => s.pre_score)), color: "#f0759c" },
    { label: "Post-Test", pct: avg(students.map((s) => s.post_score)), color: "#2ed3b7" },
  ];
  return (
    <div className="card">
      <h3>Class Averages</h3>
      {students.length === 0 ? (
        <p className="empty">No student data yet.</p>
      ) : (
        <div className="rings-row">
          {rings.map((r) => (
            <div key={r.label} className="ring-item">
              <Ring pct={r.pct ?? 0} color={r.color} />
              <small className="ring-label">{r.pct == null ? `${r.label} (no data)` : r.label}</small>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

export default function Dashboard() {
  const { data, stats, isLoading, error } = useClassDashboard();
  const classes = useQuery({ queryKey: ["my-classes"], queryFn: fetchMyClasses });
  const allStats = [
    ...stats,
    { label: "Classes", value: classes.data?.length ?? 0, icon: "students" as const, color: "#f0759c" },
  ];

  if (isLoading) return <p>Loading class dashboard…</p>;
  if (error) return <p className="err">{String(error)}</p>;

  return (
    <>
      <StatCards stats={allStats} />
      <ClassChart students={data?.students ?? []} />
      <h2>Student Performance</h2>
      <StudentProgressList students={data?.students ?? []} />
    </>
  );
}
