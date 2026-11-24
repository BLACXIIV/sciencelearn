import { Link } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import {
  Badge, Card, Chip, EmptyState, Icon, ListItemCard, type IconName,
} from "../../design-system";
import { fetchAssessments, fetchMyAttemptScores } from "../../services/learning";
import { useAuth } from "../../hooks/useAuth";
import type { Assessment } from "../../types";
import "./student.css";

const KIND_LABEL: Record<string, string> = {
  pre_test: "Pre-test",
  post_test: "Post-test",
  topic_quiz: "Quiz",
  problem_solving: "Exercise",
  final_challenge: "Final",
  practice: "Practice",
};

const KIND_ICON: Record<string, IconName> = {
  pre_test: "preTest",
  post_test: "postTest",
  problem_solving: "puzzle",
  final_challenge: "award",
};

const kindIcon = (kind: string) => KIND_ICON[kind] ?? "quiz";

function Tile({ a, score }: { a: Assessment; score?: number }) {
  return (
    <ListItemCard
      to={`/student/quiz/${a.id}?t=${encodeURIComponent(a.title)}`}
      leading={<Icon name={kindIcon(a.kind)} size={22} color="var(--ds-blue)" />}
      title={a.title}
      subtitle={
        <>
          <Chip>{KIND_LABEL[a.kind] ?? "Quiz"}</Chip> {a.description}
        </>
      }
      trailing={
        <>
          {score != null && <Badge tone="mint">{Math.round(score)}%</Badge>}
          <Icon name="chevron" size={20} color="var(--ds-muted)" />
        </>
      }
    />
  );
}

export default function StudentAssessments() {
  const { session } = useAuth();
  const uid = session?.user.id;
  const assessments = useQuery({ queryKey: ["assessments"], queryFn: fetchAssessments });
  const scores = useQuery({ queryKey: ["my-attempt-scores"], queryFn: () => fetchMyAttemptScores(uid!), enabled: !!uid });

  if (assessments.isLoading) return <p className="sd-dim">Loading assessments…</p>;
  if (assessments.error) return <p className="sd-err">{String(assessments.error)}</p>;

  const rows = assessments.data ?? [];
  const tests = rows.filter((a) => a.kind === "pre_test" || a.kind === "post_test");
  const quizzes = rows.filter((a) => a.kind !== "pre_test" && a.kind !== "post_test");

  return (
    <div className="sd-stack">
      {tests.length > 0 && (
        <div className="sd-tiles">
          {tests.map((a) => {
            const isPre = a.kind === "pre_test";
            return (
              <Link key={a.id} to={`/student/quiz/${a.id}?t=${encodeURIComponent(a.title)}`} className="sd-cardlink">
                <Card variant="pastel" pastelColor={isPre ? "blue" : "yellow"} tilt>
                  <span className="sd-tile">
                    <Icon name={isPre ? "preTest" : "postTest"} size={36} />
                    <span className="ds-label">{isPre ? "Pre-test" : "Post-test"}</span>
                    <span className="ds-caption">{isPre ? "Before learning" : "After learning"}</span>
                  </span>
                </Card>
              </Link>
            );
          })}
        </div>
      )}
      <h3 className="ds-h3">Quizzes & exercises</h3>
      {quizzes.map((a) => <Tile key={a.id} a={a} score={scores.data?.[a.id]} />)}
      {quizzes.length === 0 && (
        <Card>
          <EmptyState icon="assessment" title="No quizzes published yet" />
        </Card>
      )}
    </div>
  );
}
