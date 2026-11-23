import { useState } from "react";
import { Link, useNavigate, useParams, useSearchParams } from "react-router-dom";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { fetchQuestions, submitAttempt } from "../../services/learning";
import { E } from "../../components/icons";
import type { AnswerValue, AttemptResult, QuizQuestion } from "../../types";

/** Per-question input for one qtype. Reports changes as AnswerValue payloads. */
function AnswerInput({ q, value, onChange }: {
  q: QuizQuestion; value: AnswerValue | undefined; onChange: (v: AnswerValue) => void;
}) {
  switch (q.qtype) {
    case "multiple_choice":
      return (
        <>
          {(q.choices ?? []).map((c, ci) => (
            <label key={ci} className="choice">
              <input type="radio" name={q.id} checked={(value as { i: number })?.i === ci}
                onChange={() => onChange({ i: ci })} />
              {c}
            </label>
          ))}
        </>
      );
    case "true_false":
      return (
        <div className="tf-row">
          {[true, false].map((v) => (
            <label key={String(v)} className="choice">
              <input type="radio" name={q.id} checked={(value as { b: boolean })?.b === v}
                onChange={() => onChange({ b: v })} />
              {v ? "True" : "False"}
            </label>
          ))}
        </div>
      );
    case "fill_blank":
    case "identification":
      return (
        <input className="text-answer" type="text" placeholder="Your answer"
          value={(value as { t: string })?.t ?? ""}
          onChange={(e) => onChange({ t: e.target.value })} />
      );
    case "enumeration": {
      const n = q.meta?.n ?? 3;
      const items = (value as { items: string[] })?.items ?? Array(n).fill("");
      return (
        <div className="enum-list">
          {Array.from({ length: n }, (_, i) => (
            <input key={i} className="text-answer" type="text" placeholder={`${i + 1}.`}
              value={items[i] ?? ""}
              onChange={(e) => {
                const next = [...items];
                next[i] = e.target.value;
                onChange({ items: next });
              }} />
          ))}
        </div>
      );
    }
  }
}

export default function StudentQuiz() {
  const { id = "" } = useParams();
  const [params] = useSearchParams();
  const title = params.get("t") ?? "Quiz";
  const nav = useNavigate();
  const qc = useQueryClient();

  const questions = useQuery({ queryKey: ["questions", id], queryFn: () => fetchQuestions(id) });
  const [answers, setAnswers] = useState<Record<string, AnswerValue>>({});
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
          <div className="result-icon"><E name="postTest" size={72} /></div>
          {result.score != null ? (
            <>
              <div className="score">{result.score}%</div>
              <p>{result.total} questions</p>
            </>
          ) : (
            <>
              <h2>Submitted</h2>
              <p className="muted-center">Your score will appear once your teacher releases it.</p>
            </>
          )}
          <button onClick={() => nav("/student/assessments")}>Done</button>
        </div>
      </div>
    );
  }

  const qs = questions.data ?? [];
  const isAnswered = (v: AnswerValue | undefined) => {
    if (!v) return false;
    if ("t" in v) return v.t.trim() !== "";
    if ("items" in v) return v.items.some((s) => s.trim() !== "");
    return true;
  };
  const answered = qs.filter((q) => isAnswered(answers[q.id])).length;

  return (
    <div className="quiz-page">
      <Link to="/student/assessments" className="link-btn">← Back to Assessment Center</Link>
      <h2>{title}</h2>
      {questions.isLoading && <p className="empty">Loading questions…</p>}
      {questions.error && <p className="err">{String(questions.error)}</p>}
      {qs.map((q, i) => (
        <fieldset key={q.id} className="card q-block">
          <legend className="q-prompt">
            {i + 1}. {q.prompt}
            <small className="q-kind">{q.qtype.replace(/_/g, " ")}</small>
          </legend>
          <AnswerInput q={q} value={answers[q.id]}
            onChange={(v) => setAnswers((a) => ({ ...a, [q.id]: v }))} />
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
