import { useLessons } from "../hooks/useLessons";
import LessonForm from "../components/LessonForm";
import LessonList from "../components/LessonList";

export default function ManageLessons() {
  const { lessons, create, togglePublish } = useLessons();

  return (
    <>
      <LessonForm onCreate={create.mutateAsync} pending={create.isPending} error={create.error} />
      {lessons.error && <p className="err">{String(lessons.error)}</p>}
      <LessonList lessons={lessons.data ?? []} onTogglePublish={togglePublish.mutate} />
    </>
  );
}
