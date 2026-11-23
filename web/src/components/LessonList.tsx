import type { Lesson } from "../types";

interface Props {
  lessons: Lesson[];
  onTogglePublish: (lesson: Lesson) => void;
}

export default function LessonList({ lessons, onTogglePublish }: Props) {
  return (
    <div className="card">
      <h3>Lessons</h3>
      {lessons.map((l) => (
        <div key={l.id} className="perf">
          <span>{l.title} <small>({l.subject})</small></span>
          <button onClick={() => onTogglePublish(l)}>{l.is_published ? "Unpublish" : "Publish"}</button>
        </div>
      ))}
    </div>
  );
}
