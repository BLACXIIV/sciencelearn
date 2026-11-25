import { useParams } from "react-router-dom";
import { useLessons } from "../../hooks/useLessons";
import LessonForm from "../../components/LessonForm";
import LessonList from "../../components/LessonList";
import "../teacher.css";

/** The class curriculum: create lessons, order them, publish, drill into activities. */
export default function ClassLessons() {
  const { classId = "" } = useParams();
  const { lessons, create, togglePublish } = useLessons(classId);

  return (
    <div className="td-stack">
      <LessonForm onCreate={create.mutateAsync} pending={create.isPending} error={create.error} />
      {lessons.error && <p className="td-err">{String(lessons.error)}</p>}
      <LessonList lessons={lessons.data ?? []} onTogglePublish={togglePublish.mutate} />
    </div>
  );
}
