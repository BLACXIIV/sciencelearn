import { Link, useParams } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { fetchPublishedLessons } from "../../services/learning";
import { fetchClass } from "../../services/classes";
import { getR2Url } from "../../services/storage";
import { I } from "../../components/icons";

function LessonThumb({ thumbKey }: { thumbKey: string | null }) {
  const url = useQuery({
    queryKey: ["r2-url", thumbKey],
    queryFn: () => getR2Url(thumbKey!),
    enabled: !!thumbKey,
    staleTime: 5 * 60 * 1000,
  });
  if (!thumbKey || !url.data) return <span className="lesson-ico"><I name="science" size={26} /></span>;
  return <img className="thumb" src={url.data} alt="" loading="lazy" />;
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
    <>
      <div className="card">
        <div className="perf">
          <span>
            <strong>{cls.data?.name ?? "Class"}</strong>
            <small className="kind">Code: {cls.data?.code ?? "…"}</small>
          </span>
        </div>
      </div>

      {lessons.isLoading && <p className="empty">Loading lessons…</p>}
      {lessons.error && <p className="err">{String(lessons.error)}</p>}
      {lessons.data?.length === 0 && (
        <div className="card"><p className="empty">No lessons here yet, your teacher has not published any for this class.</p></div>
      )}
      {lessons.data?.map((l) => {
        const pct = l.lesson_progress[0]?.percent ?? 0;
        return (
          <Link key={l.id} to={`/student/lessons/${l.id}`} className="card lesson-row">
            <LessonThumb thumbKey={l.thumbnail_key} />
            <span className="lesson-body">
              <strong>{l.title}</strong>
              <small>Objectives: {l.objectives}</small>
              <span className="bar-row">
                <span className="bar"><div style={{ width: `${pct}%` }} /></span>
                <small>{pct}%</small>
              </span>
            </span>
            <span className="chev"><I name="chevron" size={20} /></span>
          </Link>
        );
      })}
      <p className="empty"><Link to="/student/classes">← Back to My Classes</Link></p>
    </>
  );
}
