import { Link, useNavigate, useParams } from "react-router-dom";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useAuth } from "../../hooks/useAuth";
import { fetchLesson, setLessonProgress } from "../../services/learning";
import { getR2Url } from "../../services/storage";
import { I } from "../../components/icons";

export default function StudentLessonDetail() {
  const { id = "" } = useParams();
  const nav = useNavigate();
  const qc = useQueryClient();
  const { session } = useAuth();
  const uid = session?.user.id;

  const lesson = useQuery({ queryKey: ["lesson", id], queryFn: () => fetchLesson(id) });
  const complete = useMutation({
    mutationFn: () => setLessonProgress(uid!, id, 100),
    onSuccess: async () => {
      await Promise.all([
        qc.invalidateQueries({ queryKey: ["pub-lessons"] }),
        qc.invalidateQueries({ queryKey: ["my-progress"] }),
        qc.invalidateQueries({ queryKey: ["recent"] }),
      ]);
      nav("/student/lessons");
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
      <Link to="/student/lessons" className="link-btn">← Back to lessons</Link>
      <h2>{l.title}</h2>
      <p><strong>Objectives:</strong> {l.objectives}</p>
      <hr />
      <p className="lesson-content">{l.content_md}</p>
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
