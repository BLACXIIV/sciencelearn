import { Link, useNavigate, useParams } from "react-router-dom";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useAuth } from "../../hooks/useAuth";
import { fetchLesson, fetchLessonActivities, fetchMyAttemptScores, setLessonProgress } from "../../services/learning";
import { getR2Url } from "../../services/storage";
import { I } from "../../components/icons";

export default function StudentLessonDetail() {
  const { id = "" } = useParams();
  const nav = useNavigate();
  const qc = useQueryClient();
  const { session } = useAuth();
  const uid = session?.user.id;

  const lesson = useQuery({ queryKey: ["lesson", id], queryFn: () => fetchLesson(id) });
  const activities = useQuery({ queryKey: ["lesson-activities", id], queryFn: () => fetchLessonActivities(id) });
  const scores = useQuery({ queryKey: ["my-attempt-scores"], queryFn: () => fetchMyAttemptScores(uid!), enabled: !!uid });
  const complete = useMutation({
    mutationFn: () => setLessonProgress(uid!, id, 100),
    onSuccess: async () => {
      await Promise.all([
        qc.invalidateQueries({ queryKey: ["pub-lessons"] }),
        qc.invalidateQueries({ queryKey: ["my-progress"] }),
        qc.invalidateQueries({ queryKey: ["recent"] }),
      ]);
      nav(lesson.data?.class_id ? `/student/classes/${lesson.data.class_id}` : "/student/classes");
    },
  });

  async function openMaterial() {
    const url = await getR2Url(lesson.data!.content_key!);
    window.open(url, "_blank", "noopener");
  }

  if (lesson.isLoading) return <p>Loading lesson…</p>;
  if (lesson.error) return <p className="err">{String(lesson.error)}</p>;
  const l = lesson.data!;

  return (
    <article className="card">
      <Link to={l.class_id ? `/student/classes/${l.class_id}` : "/student/classes"} className="link-btn">← Back to class</Link>
      <h2>{l.title}</h2>
      <p><strong>Objectives:</strong> {l.objectives}</p>
      <hr />
      <p className="lesson-content">{l.content_md}</p>
      {(activities.data?.length ?? 0) > 0 && (
        <>
          <hr />
          <h3>Activities</h3>
          {activities.data?.map((a) => (
            <Link key={a.id} to={`/student/quiz/${a.id}?t=${encodeURIComponent(a.title)}`} className="card lesson-row">
              <span className="lesson-ico"><I name="quiz" size={22} /></span>
              <span className="lesson-body">
                <strong>{a.title}</strong>
                <small>{a.description}</small>
              </span>
              {scores.data?.[a.id] != null && <span className="score-chip">{Math.round(scores.data[a.id])}%</span>}
              <span className="chev"><I name="chevron" size={20} /></span>
            </Link>
          ))}
        </>
      )}
      {l.content_key && (
        <button className="secondary" onClick={openMaterial}>
          Open lesson material <I name="openExternal" size={16} />
        </button>
      )}{" "}
      <button onClick={() => complete.mutate()} disabled={complete.isPending}>
        {complete.isPending ? "Saving…" : "Mark as completed"}
      </button>
      {complete.error && <p className="err">{String(complete.error)}</p>}
    </article>
  );
}
