import { useNavigate } from "react-router-dom";
import { Button, EmptyState, ListItemCard } from "../design-system";
import type { Lesson } from "../types";

interface Props {
  lessons: Lesson[];
  onTogglePublish: (lesson: Lesson) => void;
}

export default function LessonList({ lessons, onTogglePublish }: Props) {
  const nav = useNavigate();
  if (lessons.length === 0) {
    return <EmptyState icon="lessons" title="No lessons yet" body="Create the first one above." />;
  }
  return (
    <div className="td-stack">
      {lessons.map((l) => (
        <ListItemCard
          key={l.id}
          title={l.title}
          subtitle={`${l.subject} · ${l.is_published ? "Published" : "Draft"}`}
          trailing={
            <span className="td-actions">
              <Button variant="outline" size="sm"
                onClick={() => nav(`/teacher/c/${l.class_id}/lessons/${l.id}/activities`)}>
                Activities
              </Button>
              <Button variant="outline" size="sm" onClick={() => onTogglePublish(l)}>
                {l.is_published ? "Unpublish" : "Publish"}
              </Button>
            </span>
          }
        />
      ))}
    </div>
  );
}
