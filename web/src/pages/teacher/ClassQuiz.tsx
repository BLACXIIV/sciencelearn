import { useState } from "react";
import { Link, useParams } from "react-router-dom";
import { useLessons } from "../../hooks/useLessons";
import { ActivitiesBuilder } from "../LessonActivities";
import { Card, EmptyState, Select } from "../../design-system";
import "../teacher.css";

/** Create Quiz: pick a lesson, then build assessments inside it —
 *  quizzes attach to lessons per the schema. */
export default function ClassQuiz() {
  const { classId = "" } = useParams();
  const { lessons } = useLessons(classId);
  const [lessonId, setLessonId] = useState("");
  const list = lessons.data ?? [];
  const chosen = lessonId || list[0]?.id || "";

  if (lessons.isLoading) return <p className="ds-body">Loading lessons…</p>;
  if (lessons.error) return <p className="td-err">{String(lessons.error)}</p>;

  if (list.length === 0) {
    return (
      <Card variant="white">
        <EmptyState icon="lessons" title="No lessons yet"
          body="Quizzes attach to lessons — create a lesson first."
          action={<Link to={`/teacher/c/${classId}/lessons`} className="td-link">Go to Lessons →</Link>} />
      </Card>
    );
  }

  return (
    <div className="td-stack">
      <Card variant="white">
        <Select
          label="Which lesson is this for?"
          value={chosen}
          onChange={(e) => setLessonId(e.target.value)}
          options={list.map((l) => ({ value: l.id, label: `${l.title} — ${l.subject}` }))}
        />
      </Card>
      <ActivitiesBuilder key={chosen} lessonId={chosen} />
    </div>
  );
}
