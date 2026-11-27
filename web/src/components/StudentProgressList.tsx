import { Avatar, ListItemCard, ProgressBar } from "../design-system";
import type { StudentProgress } from "../types";

export default function StudentProgressList({ students }: { students: StudentProgress[] }) {
  return (
    <div className="td-stack">
      {students.map((s) => (
        <ListItemCard
          key={s.student_id}
          leading={<Avatar name={s.full_name || "?"} />}
          title={s.full_name}
          subtitle={`Quiz average ${s.quizzes_pct ?? "–"}%`}
          trailing={
            <span className="td-row" style={{ flexWrap: "nowrap" }}>
              <span style={{ width: 96 }}>
                <ProgressBar size="sm" value={s.lessons_pct ?? 0} />
              </span>
              <strong>{s.lessons_pct ?? 0}%</strong>
            </span>
          }
        />
      ))}
    </div>
  );
}
