import { useState } from "react";
import { Link, useNavigate, useParams, useSearchParams } from "react-router-dom";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  Button, Card, EmptyState, Icon, QuizCard, QuizOption, RingChart, TextField,
} from "../../design-system";
import { fetchQuestions, submitAttempt } from "../../services/learning";
import type { AnswerValue, AttemptResult, QuizQuestion } from "../../types";
import "./student.css";

const LETTERS = "ABCDEFGH";

const TYPE_LABEL: Record<string, string> = {
  multiple_choice: "Multiple choice",
  true_false: "True or false",
  fill_blank: "Fill in the blank",
  identification: "Identification",
  enumeration: "Enumeration",
};

/** Per-question input for one qtype. Reports changes as AnswerValue payloads. */
function AnswerInput({ q, value, onChange }: {
  q: QuizQuestion; value: AnswerValue | undefined; onChange: (v: AnswerValue) => void;
}) {
  switch (q.qtype) {
    case "multiple_choice":
      return (
        <>
          {(q.choices ?? []).map((c, ci) => (
            <QuizOption
              key={ci}
              letter={LETTERS[ci]}
              state={(value as { i: number })?.i === ci ? "selected" : "default"}
              onClick={() => onChange({ i: ci })}
            >
              {c}
            </QuizOption>
          ))}
        </>
      );
    case "true_false":
      return (
        <>
          {[true, false].map((v, i) => (
            <QuizOption
              key={String(v)}
              letter={LETTERS[i]}
              state={(value as { b: boolean })?.b === v ? "selected" : "default"}
              onClick={() => onChange({ b: v })}
            >
              {v ? "True" : "False"}
            </QuizOption>
          ))}
        </>
      );
    case "fill_blank":
    case "identification":
      return (
        <TextField
          label="Your answer"
          type="text"
          value={(value as { t: string })?.t ?? ""}
          onChange={(e) => onChange({ t: e.target.value })}
        />
      );
    case "enumeration": {
      const n = q.meta?.n ?? 3;
      const items = (value as { items: string[] })?.items ?? Array(n).fill("");
      return (
        <>
          {Array.from({ length: n }, (_, i) => (
            <TextField
              key={i}
              label={`Item ${i + 1}`}
              type="text"
              value={items[i] ?? ""}
              onChange={(e) => {
                const next = [...items];
                next[i] = e.target.value;
                onChange({ items: next });
              }}
            />
          ))}
        </>
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
  const [qi, setQi] = useState(0);

  const submit = useMutation({
    mutationFn: () => submitAttempt(id, answers),
    onSuccess: async (r) => {
      setResult(r);
      await qc.invalidateQueries({ queryKey: ["my-progress"] });
    },
  });

  if (result) {
    return (
      <Card>
        <div className="sd-center">
          {result.score != null ? (
            <>
              <RingChart size={140} slices={[
                { value: result.score, series: 1 },
                { value: 100 - result.score, series: 0 },
              ]}>
                <span className="ds-h2">{Math.round(result.score)}%</span>
              </RingChart>
              <p className="ds-body-sm">{result.total} questions</p>
            </>
          ) : (
            <EmptyState
              icon="done"
              title="Submitted"
              body="Your score will appear once your teacher releases it."
            />
          )}
          <Button onClick={() => nav("/student/assessments")}>Done</Button>
        </div>
      </Card>
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
  const q = qs[qi];

  return (
    <div className="sd-stack">
      <p className="sd-dim">
        <Link to="/student/assessments" className="sd-link">
          <Icon name="back" size={16} /> Back to Assessment Center
        </Link>
      </p>
      <h2 className="ds-h2">{title}</h2>
      {questions.isLoading && <p className="sd-dim">Loading questions…</p>}
      {questions.error && <p className="sd-err">{String(questions.error)}</p>}
      {q && (
        <>
          <QuizCard
            tag={`Question ${qi + 1} of ${qs.length} · ${TYPE_LABEL[q.qtype] ?? "Question"}`}
            title={q.prompt}
            footer={<span>{answered} of {qs.length} answered</span>}
          >
            <AnswerInput
              key={q.id}
              q={q}
              value={answers[q.id]}
              onChange={(v) => setAnswers((a) => ({ ...a, [q.id]: v }))}
            />
          </QuizCard>
          <div className="sd-actions">
            <Button variant="outline" disabled={qi === 0} onClick={() => setQi(qi - 1)}>
              Back
            </Button>
            {qi < qs.length - 1 ? (
              <Button onClick={() => setQi(qi + 1)}>Next</Button>
            ) : (
              <Button
                loading={submit.isPending}
                disabled={answered < qs.length}
                onClick={() => submit.mutate()}
              >
                Submit answers
              </Button>
            )}
          </div>
          {submit.error && <p className="sd-err">{String(submit.error)}</p>}
        </>
      )}
    </div>
  );
}
