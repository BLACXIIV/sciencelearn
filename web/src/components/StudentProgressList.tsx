import type { StudentProgress } from "../types";

export default function StudentProgressList({ students }: { students: StudentProgress[] }) {
  return (
    <div className="card">
      {students.map((s) => (
        <div key={s.student_id} className="perf">
          <span className="avatar">{(s.full_name || "?")[0].toUpperCase()}</span>
          <span>{s.full_name}</span>
          <div className="bar"><div style={{ width: `${s.lessons_pct}%` }} /></div>
          <span>{s.lessons_pct}%</span>
          <small>Pre {s.pre_score ?? "–"} → Post {s.post_score ?? "–"}</small>
        </div>
      ))}
      {students.length === 0 && <p>No students yet.</p>}
    </div>
  );
}
