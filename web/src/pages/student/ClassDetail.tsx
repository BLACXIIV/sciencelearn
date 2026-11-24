import { Link, useParams } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { Card, Chip, EmptyState, Icon, ListItemCard, ProgressBar, Thumbnail } from "../../design-system";
import { fetchPublishedLessons } from "../../services/learning";
import { fetchClass } from "../../services/classes";
import { getR2Url } from "../../services/storage";
import "./student.css";

function LessonThumb({ thumbKey }: { thumbKey: string | null }) {
  const url = useQuery({
    queryKey: ["r2-url", thumbKey],
    queryFn: () => getR2Url(thumbKey!),
    enabled: !!thumbKey,
    staleTime: 5 * 60 * 1000,
  });
  return <Thumbnail src={thumbKey ? url.data : null} />;
}

/** Student view of one class: its published lessons with progress. */
export default function StudentClassDetail() {
  const { id = "" } = useParams();
  const cls = useQuery({ queryKey: ["class", id], queryFn: () => fetchClass(id) });
  const lessons = useQuery({
    queryKey: ["pub-lessons", "class", id],
    queryFn: () => fetchPublishedLessons(null, id),
  });

  return (
    <div className="sd-stack">
      <Card>
        <div className="sd-row">
          <span className="sd-rowbody">
            <strong className="ds-title">{cls.data?.name ?? "Class"}</strong>
            <Chip className="sd-chip">Code: {cls.data?.code ?? "…"}</Chip>
          </span>
        </div>
      </Card>

      {lessons.isLoading && <p className="sd-dim">Loading lessons…</p>}
      {lessons.error && <p className="sd-err">{String(lessons.error)}</p>}
      {lessons.data?.length === 0 && (
        <Card>
          <EmptyState icon="lessons" title="No lessons here yet" body="Your teacher has not published any for this class." />
        </Card>
      )}
      {lessons.data?.map((l) => {
        const pct = l.lesson_progress[0]?.percent ?? 0;
        return (
          <ListItemCard
            key={l.id}
            to={`/student/lessons/${l.id}`}
            leading={<LessonThumb thumbKey={l.thumbnail_key} />}
            title={l.title}
            subtitle={
              <>
                Objectives: {l.objectives}
                <span className="ds-lic-progress">
                  <ProgressBar value={pct} size="sm" />
                  <span className="ds-caption">{pct}%</span>
                </span>
              </>
            }
            trailing={<Icon name="chevron" size={20} color="var(--ds-muted)" />}
          />
        );
      })}
      <p className="sd-dim"><Link to="/student/classes" className="sd-link">Back to My Classes</Link></p>
    </div>
  );
}
