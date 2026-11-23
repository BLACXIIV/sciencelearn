import { useState } from "react";
import { Link } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { fetchPublishedLessons } from "../../services/learning";
import { getR2Url } from "../../services/storage";
import { I } from "../../components/icons";
import { SUBJECTS, type Subject } from "../../types";

/** R2 thumbnail — resolves the object key to a signed URL; icon box otherwise. */
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

export default function StudentLessons() {
  const [subject, setSubject] = useState<Subject | null>(null);
  const lessons = useQuery({
    queryKey: ["pub-lessons", subject],
    queryFn: () => fetchPublishedLessons(subject),
  });

  return (
    <>
      <div className="chips">
        {[null, ...SUBJECTS].map((s) => (
          <button key={s ?? "all"} className={`chip ${subject === s ? "active" : ""}`} onClick={() => setSubject(s)}>
            {s ?? "All"}
          </button>
        ))}
      </div>

      {lessons.isLoading && <p className="empty">Loading lessons…</p>}
      {lessons.error && <p className="err">{String(lessons.error)}</p>}
      {lessons.data?.length === 0 && (
        <div className="card"><p className="empty">No lessons here yet, try another subject, or check back soon.</p></div>
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
    </>
  );
}
