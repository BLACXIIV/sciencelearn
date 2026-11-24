import { Link, useNavigate, useParams } from "react-router-dom";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Badge, Button, Card, Divider, Icon } from "../../design-system";
import { useAuth } from "../../hooks/useAuth";
import { fetchLesson, fetchLessonActivities, fetchMyAttemptScores, setLessonProgress } from "../../services/learning";
import { getR2Url } from "../../services/storage";
import "./student.css";

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

  if (lesson.isLoading) return <p className="sd-dim">Loading lesson…</p>;
  if (lesson.error) return <p className="sd-err">{String(lesson.error)}</p>;
  const l = lesson.data!;

  return (
    <Card>
      <Link to={l.class_id ? `/student/classes/${l.class_id}` : "/student/classes"} className="sd-link">
        <Icon name="back" size={16} /> Back to class
      </Link>
      <h2 className="ds-h2">{l.title}</h2>
      <p className="ds-body"><strong>Objectives:</strong> {l.objectives}</p>
      <Divider />
      <p className="sd-pre">{l.content_md}</p>
      {(activities.data?.length ?? 0) > 0 && (
        <>
          <Divider />
          <h3 className="ds-h3">Activities</h3>
          <div className="sd-stack">
            {activities.data?.map((a) => (
              <Link key={a.id} to={`/student/quiz/${a.id}?t=${encodeURIComponent(a.title)}`} className="sd-cardlink">
                <Card>
                  <span className="sd-row">
                    <Icon name="quiz" size={22} color="var(--ds-blue)" />
                    <span className="sd-rowbody">
                      <strong>{a.title}</strong>
                      <small className="ds-caption">{a.description}</small>
                    </span>
                    {scores.data?.[a.id] != null && <Badge tone="mint">{Math.round(scores.data[a.id])}%</Badge>}
                    <Icon name="chevron" size={20} color="var(--ds-muted)" />
                  </span>
                </Card>
              </Link>
            ))}
          </div>
        </>
      )}
      <div className="sd-actions">
        {l.content_key && (
          <Button variant="outline" leadingIcon="openExternal" onClick={openMaterial}>
            Open lesson material
          </Button>
        )}
        <Button loading={complete.isPending} onClick={() => complete.mutate()}>
          Mark as completed
        </Button>
      </div>
      {complete.error && <p className="sd-err">{String(complete.error)}</p>}
    </Card>
  );
}
