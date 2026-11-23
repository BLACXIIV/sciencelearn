import { useQuery } from "@tanstack/react-query";
import { supabase } from "../lib/supabase";

type Row = { student_id: string; full_name: string; lessons_pct: number; quizzes_pct: number | null; pre_score: number | null; post_score: number | null };

export default function Dashboard() {
  const { data, isLoading, error } = useQuery({
    queryKey: ["class-dashboard"],
    queryFn: async () => {
      const [{ data: students, error: e1 }, { count, error: e2 }] = await Promise.all([
        supabase.from("v_student_progress").select("*").order("full_name"),
        supabase.from("lesson_progress").select("*", { count: "exact", head: true }).eq("percent", 100),
      ]);
      if (e1 || e2) throw e1 ?? e2;
      return { students: (students ?? []) as Row[], completed: count ?? 0 };
    },
  });

  if (isLoading) return <p>Loading…</p>;
  if (error) return <p className="err">{String(error)}</p>;
  const { students, completed } = data!;

  const scored = students.filter((s) => s.quizzes_pct != null);
  const avg = scored.length ? Math.round(scored.reduce((a, s) => a + (s.quizzes_pct ?? 0), 0) / scored.length) : 0;
  const both = students.filter((s) => s.pre_score != null && s.post_score != null);
  const gain = both.length ? Math.round(both.reduce((a, s) => a + (s.post_score! - s.pre_score!), 0) / both.length) : 0;

  const stats = [
    { label: "Total Students", value: students.length },
    { label: "Completed Lessons", value: completed },
    { label: "Average Score", value: `${avg}%` },
    { label: "Class Gain", value: `${gain >= 0 ? "+" : ""}${gain}%` },
  ];

  return (
    <>
      <section className="stats">
        {stats.map((s) => (
          <div key={s.label} className="card stat"><span>{s.label}</span><strong>{s.value}</strong></div>
        ))}
      </section>

      <h3>Student Performance</h3>
      <div className="card">
        {students.map((s) => (
          <div key={s.student_id} className="perf">
            <span>{s.full_name}</span>
            <div className="bar"><div style={{ width: `${s.lessons_pct}%` }} /></div>
            <span>{s.lessons_pct}%</span>
            <small>Pre {s.pre_score ?? "–"} → Post {s.post_score ?? "–"}</small>
          </div>
        ))}
        {students.length === 0 && <p>No students yet.</p>}
      </div>
    </>
  );
}
