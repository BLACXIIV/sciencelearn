import { useState } from "react";
import { Link, useNavigate, useParams, useSearchParams } from "react-router-dom";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { fetchQuestions, submitAttempt } from "../../services/learning";
import type { AttemptResult } from "../../types";

export default function StudentQuiz() {
  const { id = "" } = useParams();
  const [params] = useSearchParams();
  const title = params.get("t") ?? "Quiz";
  const nav = useNavigate();
  const qc = useQueryClient();

  const questions = useQuery({ queryKey: ["questions", id], queryFn: () => fetchQuestions(id) });
  const [answers, setAnswers] = useState<Record<string, number>>({});
  const [result, setResult] = useState<AttemptResult | null>(null);

  const submit = useMutation({
    mutationFn: () => submitAttempt(id, answers),
    onSuccess: async (r) => {
      setResult(r);
      await qc.invalidateQueries({ queryKey: ["my-progress"] });
    },
  });

  if (result) {
    return (
      <div className="quiz-page">
        <div className="card result">
          <div className="result-icon">🏆</div>
          <div className="score">{result.score}%</div>
          <p>{result.correct} / {result.total} correct</p>
          <button onClick={() => nav("/student/assessments")}>Done</button>
        </div>
      </div>
    );
  }

  const qs = questions.data ?? [];
  const answered = Object.keys(answers).length;

  return (
    <div className="quiz-page">
      <Link to="/student/assessments" className="link-btn">← Back to Assessment Center</Link>
      <h2>{title}</h2>
      {questions.isLoading && <p className="empty">Loading questions…</p>}
      {questions.error && <p className="err">{String(questions.error)}</p>}
      {qs.map((q, i) => (
        <fieldset key={q.id} className="card q-block">
          <legend className="q-prompt">{i + 1}. {q.prompt}</legend>
          {q.choices.map((c, ci) => (
            <label key={ci} className="choice">
              <input
                type="radio"
                name={q.id}
                checked={answers[q.id] === ci}
                onChange={() => setAnswers((a) => ({ ...a, [q.id]: ci }))}
              />
              {c}
            </label>
          ))}
        </fieldset>
      ))}
      {qs.length > 0 && (
        <div className="card">
          <p className="empty-sm">{answered} of {qs.length} answered</p>
          <button disabled={submit.isPending || answered < qs.length} onClick={() => submit.mutate()}>
            {submit.isPending ? "Submitting…" : "Submit Answers"}
          </button>
          {submit.error && <p className="err">{String(submit.error)}</p>}
        </div>
      )}
    </div>
  );
}
