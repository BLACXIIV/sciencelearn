import { useQuery } from "@tanstack/react-query";
import { Link, useParams } from "react-router-dom";
import {
  fetchClassCompletedCount, fetchClassMembers, fetchClassStudentProgress,
} from "../../services/classes";
import { computeClassStats } from "../../utils/stats";
import ClassChart from "../../components/ClassChart";
import { Avatar, Card, EmptyState, ListItemCard, StatCard } from "../../design-system";
import "../teacher.css";

/** Class-scoped dashboard: is THIS class on track? Stats, averages,
 *  and the students who need attention. Roster detail lives in Students. */
export default function ClassDashboard() {
  const { classId = "" } = useParams();
  const students = useQuery({ queryKey: ["class-progress", classId], queryFn: () => fetchClassStudentProgress(classId) });
  const members = useQuery({ queryKey: ["class-members", classId], queryFn: () => fetchClassMembers(classId) });
  const completed = useQuery({ queryKey: ["class-completed", classId], queryFn: () => fetchClassCompletedCount(classId) });

  const rows = students.data ?? [];
  const pending = (members.data ?? []).filter((m) => m.status === "pending").length;
  const stats = [
    ...computeClassStats(rows, completed.data ?? 0),
    { label: "Pending requests", value: pending, icon: "pending" as const, pastel: "yellow" as const },
  ];

  // Lowest scores first — nulls (no attempts) sort below 0 so they surface first.
  const attention = [...rows]
    .sort((a, b) => (a.quizzes_pct ?? -1) - (b.quizzes_pct ?? -1))
    .filter((r) => r.quizzes_pct == null || r.quizzes_pct < 70)
    .slice(0, 5);

  if (students.isLoading) return <p className="ds-body">Loading class dashboard…</p>;
  if (students.error) return <p className="td-err">{String(students.error)}</p>;

  return (
    <>
      <div className="td-stats">
        {stats.map((s) => (
          <StatCard key={s.label} icon={s.icon!} value={String(s.value)} label={s.label} pastelColor={s.pastel} />
        ))}
      </div>
      <ClassChart students={rows} />

      <h2 className="ds-h2 td-heading">Needs attention</h2>
      {attention.length === 0 ? (
        <Card variant="white">
          <EmptyState icon="done" title="Everyone's on track"
            body="No students are behind on quizzes right now." />
        </Card>
      ) : (
        <div className="td-stack">
          {attention.map((s) => (
            <ListItemCard
              key={s.student_id}
              leading={<Avatar name={s.full_name || "?"} />}
              title={s.full_name}
              subtitle={s.quizzes_pct == null ? "No quiz attempts yet" : `Quiz average ${s.quizzes_pct}%`}
            />
          ))}
          <Link to={`/teacher/c/${classId}/students`} className="td-link">View all students →</Link>
        </div>
      )}
    </>
  );
}
