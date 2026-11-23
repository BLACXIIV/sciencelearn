import type { CSSProperties } from "react";
import { Link } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { fetchAssessments } from "../../services/learning";
import type { Assessment } from "../../types";

const KIND_LABEL: Record<string, string> = {
  pre_test: "PRE-TEST",
  post_test: "POST-TEST",
  topic_quiz: "QUIZ",
  problem_solving: "EXERCISE",
  final_challenge: "FINAL",
  practice: "PRACTICE",
};

function Tile({ a }: { a: Assessment }) {
  return (
    <Link to={`/student/quiz/${a.id}?t=${encodeURIComponent(a.title)}`} className="card lesson-row">
      <span className="kind">{KIND_LABEL[a.kind] ?? "QUIZ"}</span>
      <span className="lesson-body">
        <strong>{a.title}</strong>
        <small>{a.description}</small>
      </span>
      <span className="chev">›</span>
    </Link>
  );
}

export default function StudentAssessments() {
  const assessments = useQuery({ queryKey: ["assessments"], queryFn: fetchAssessments });

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
              <Link key={a.id} to={`/student/quiz/${a.id}?t=${encodeURIComponent(a.title)}`}
                className="tile" style={{ "--tile-bg": isPre ? "#dbeafe" : "#fef3c7" } as CSSProperties}>
                <span className="glyph">{isPre ? "📋" : "🏆"}</span>
                <strong>{isPre ? "Pre-Test" : "Post-Test"}</strong>
                <small>{isPre ? "Before Learning" : "After Learning"}</small>
              </Link>
            );
          })}
        </div>
      )}
      <h3>Quizzes & Exercises</h3>
      {quizzes.map((a) => <Tile key={a.id} a={a} />)}
      {quizzes.length === 0 && <p className="empty">No quizzes published yet.</p>}
    </>
  );
}
