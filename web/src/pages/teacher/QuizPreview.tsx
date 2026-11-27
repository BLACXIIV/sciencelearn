import { useState } from "react";
import { Link, useParams } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { fetchPreview } from "../../services/activities";
import {
  Button, Card, Chip, EmptyState, Icon, ProgressBar, QuizCard, QuizNav,
} from "../../design-system";
import type { AnswerValue, QuizQuestion } from "../../types";
import { isAnswered, sortQuestionsByPart } from "../../utils/quiz";
import {
  AnswerInput, TYPE_LABEL, promptView, showPrompt,
} from "../student/Quiz";
import "../teacher.css";

/**
 * Teacher preview — renders the exact student view (parts_public +
 * questions_public projection via preview_questions), read-only. Teachers
 * can step through and tap answers (nothing is submitted or saved).
 */
export default function QuizPreview() {
  const { classId = "", assessmentId = "" } = useParams();
  const preview = useQuery({
    queryKey: ["preview", assessmentId],
    queryFn: () => fetchPreview(assessmentId),
    retry: false,
  });
  const [answers, setAnswers] = useState<Record<string, AnswerValue>>({});
  const [qi, setQi] = useState(0);

  const back = `/teacher/c/${classId}/quiz/a/${assessmentId}`;

  if (preview.isLoading) {
    return <p className="ds-body">Loading preview…</p>;
  }
  if (preview.error) {
    // Graceful pre-migration state + real errors share one panel.
    return (
      <div className="td-stack">
        <p className="sd-dim">
          <Link to={back} className="td-link"><Icon name="back" size={16} /> Back</Link>
        </p>
        <Card variant="white">
          <EmptyState icon="assessment" title="Preview is not available yet"
            body={preview.error instanceof Error && preview.error.message !== ""
              ? preview.error.message
              : "The preview service hasn't been enabled for this class yet."} />
        </Card>
      </div>
    );
  }

  const ps = preview.data?.parts ?? [];
  const qs = sortQuestionsByPart(preview.data?.questions ?? [], ps);
  const q = qs[qi];
  const partIndex = new Map(ps.map((p, i) => [p.id, i + 1]));
  const partOf = (qq: QuizQuestion | undefined) =>
    qq?.part_id ? ps.find((p) => p.id === qq.part_id) : undefined;
  const answered = qs.filter((x) => isAnswered(x, answers[x.id])).length;

  return (
    <div className="td-stack">
      <p className="sd-dim">
        <Link to={back} className="td-link"><Icon name="back" size={16} /> Back to builder</Link>
      </p>
      <div className="td-prev-banner" role="status">
        <Icon name="show" size={18} />
        <span><strong>Preview</strong> — view only, answers are not saved.</span>
      </div>

      {qs.length === 0 ? (
        <Card variant="white">
          <EmptyState icon="assessment" title="Nothing to preview"
            body="Add questions in the builder first." />
        </Card>
      ) : (
        <>
          <div className="sd-quizhead">
            <span className="ds-label">Question {qi + 1} of {qs.length}</span>
            <ProgressBar value={(answered / qs.length) * 100} size="sm" />
          </div>
          <div style={{ pointerEvents: "none" }}>
            <QuizNav
              count={qs.length}
              current={qi}
              answered={qs.map((qq) => isAnswered(qq, answers[qq.id]))}
              onSelect={setQi}
            />
          </div>
          {(() => {
            const part = partOf(q);
            return part ? (
              <div>
                <span className="ds-label">
                  Activity {partIndex.get(part.id)}{part.title ? ` — ${part.title}` : ""}
                </span>{" "}
                {!part.scored && <Chip variant="pastel" pastelColor="yellow">Not scored</Chip>}
                {part.directions !== "" && (
                  <p className="ds-caption" style={{ color: "var(--ds-muted)", margin: "4px 0 0" }}>
                    {part.directions}
                  </p>
                )}
              </div>
            ) : null;
          })()}
          <QuizCard
            tag={partOf(q)?.mode === "matching"
              ? "Matching"
              : q!.qtype === "classification"
                ? ((q!.meta?.context ?? "") !== ""
                    ? "Equation labeling"
                    : (q!.meta?.buckets?.length ?? 2) <= 2
                      ? "Binary classification"
                      : "Multi-category")
                : (TYPE_LABEL[q!.qtype] ?? "Question")}
            title={q!.qtype === "fill_blank"
              ? promptView(q!.prompt, {
                  text: (() => {
                    const v = answers[q!.id];
                    return v && "i" in v ? q!.choices?.[v.i] : undefined;
                  })(),
                })
              : showPrompt(q!.prompt)}
            footer={<span>{answered} of {qs.length} answered</span>}
          >
            <div style={{ pointerEvents: "none" }}>
              <AnswerInput
                key={q!.id}
                q={q!}
                value={answers[q!.id]}
                onChange={(v) => setAnswers((a) => ({ ...a, [q!.id]: v }))}
              />
            </div>
          </QuizCard>
          <div className="sd-actions">
            <Link to={back} className="td-link">Exit preview</Link>
            <span style={{ flex: 1 }} />
            <Button disabled={qi >= qs.length - 1} onClick={() => setQi(qi + 1)}>
              Next
            </Button>
          </div>
          {/* view-only: no answering, no back-nav, no submit */}
        </>
      )}
    </div>
  );
}
