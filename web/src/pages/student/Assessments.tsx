import { Link } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { E, I } from "../../components/icons";
import { fetchAssessments, fetchMyAttemptScores } from "../../services/learning";
import { useAuth } from "../../hooks/useAuth";
import type { Assessment } from "../../types";

const KIND_LABEL: Record<string, string> = {
  pre_test: "PRE-TEST",
  post_test: "POST-TEST",
  topic_quiz: "QUIZ",
  problem_solving: "EXERCISE",
  final_challenge: "FINAL",
  practice: "PRACTICE",
};

function Tile({ a, score }: { a: Assessment; score?: number }) {
  return (
    <Link to={`/student/quiz/${a.id}?t=${encodeURIComponent(a.title)}`} className="card lesson-row">
      <span className="kind">{KIND_LABEL[a.kind] ?? "QUIZ"}</span>
      <span className="lesson-body">
        <strong>{a.title}</strong>
        <small>{a.description}</small>
      </span>
      {score != null && <span className="score-chip">{Math.round(score)}%</span>}
      <span className="chev"><I name="chevron" size={20} /></span>
    </Link>
  );
}

export default function StudentAssessments() {
  const { session } = useAuth();
  const uid = session?.user.id;
  const assessments = useQuery({ queryKey: ["assessments"], queryFn: fetchAssessments });
  const scores = useQuery({ queryKey: ["my-attempt-scores"], queryFn: () => fetchMyAttemptScores(uid!), enabled: !!uid });

  if (assessments.isLoading) return <p>Loading assessments…</p>;
  if (assessments.error) return <p className="err">{String(assessments.error)}</p>;

  const rows = assessments.data ?? [];
  const tests = rows.filter((a) => a.kind === "pre_test" || a.kind === "post_test");
  const quizzes = rows.filter((a) => a.kind !== "pre_test" && a.kind !== "post_test");

  return (
    <>
      {tests.length > 0 && (
        <div className="tiles narrow">
          {tests.map((a) => {
            const isPre = a.kind === "pre_test";
            return (
              <Link key={a.id} to={`/student/quiz/${a.id}?t=${encodeURIComponent(a.title)}`} className="tile">
                <E name={isPre ? "preTest" : "postTest"} size={44} />
                <strong>{isPre ? "Pre-Test" : "Post-Test"}</strong>
                <small>{isPre ? "Before Learning" : "After Learning"}</small>
              </Link>
            );
          })}
        </div>
      )}
      <h3>Quizzes & Exercises</h3>
      {quizzes.map((a) => <Tile key={a.id} a={a} score={scores.data?.[a.id]} />)}
      {quizzes.length === 0 && <p className="empty">No quizzes published yet.</p>}
    </>
  );
}
