import { useClassDashboard } from "../hooks/useClassDashboard";
import StatCards from "../components/StatCards";
import StudentProgressList from "../components/StudentProgressList";

export default function Dashboard() {
  const { data, stats, isLoading, error } = useClassDashboard();

  if (isLoading) return <p>Loading class dashboard…</p>;
  if (error) return <p className="err">{String(error)}</p>;

  return (
    <>
      <StatCards stats={stats} />
      <h2>Student Performance</h2>
      <StudentProgressList students={data?.students ?? []} />
    </>
  );
}
