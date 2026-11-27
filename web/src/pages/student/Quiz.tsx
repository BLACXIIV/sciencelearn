import { Fragment, useState } from "react";
import { Link, useNavigate, useParams, useSearchParams } from "react-router-dom";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  Button, Card, Chip, EmptyState, Icon, ListItemCard, Modal,
  ProgressBar, QuizCard, QuizNav, QuizOption, RingChart, TextField,
} from "../../design-system";
import { fetchPartsPublic, fetchQuestions, reviewAttempt, submitAttempt } from "../../services/learning";
import type {
  AnswerValue, AssessmentPart, AttemptResult, QuizQuestion, ReviewItem, ReviewResult,
} from "../../types";
import { fmtPts } from "../../utils/stats";
import { isAnswered, sortQuestionsByPart } from "../../utils/quiz";
import "./student.css";

const LETTERS = "ABCDEFGH";

export const TYPE_LABEL: Record<string, string> = {
  multiple_choice: "Multiple choice",
  true_false: "True or false",
  fill_blank: "Fill in the blank",
  identification: "Identification",
  enumeration: "Enumeration",
  multi_select: "Multi-select",
  classification: "Classification",
  ordering: "Ordering",
};

const shuffleIdx = (n: number) => {
  const a = Array.from({ length: n }, (_, i) => i);
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
};

/** Ordering: items shown (re)shuffled, student reorders via up/down.
 *  Answer = the arrangement's choice indexes top -> bottom. Seeded on
 *  mount so an untouched arrangement still counts as answered. */
/** Ordering slot→pool input: N dashed "Step" slots on top, a "Tap in order"
 *  chip pool below — each tap fills the next slot; tapping a placed chip pulls
 *  it back into the pool (later chips compact up). `o` = choice indexes in
 *  slot order, empty until the student starts placing. */
function OrderingInput({ q, value, onChange }: {
  q: QuizQuestion; value: AnswerValue | undefined;
  onChange: (v: AnswerValue) => void;
}) {
  const items = q.choices ?? [];
  const n = items.length;
  // Pool display order — the saved scramble, or reshuffled per open.
  const [seed] = useState(() =>
    q.meta?.shuffle === false
      ? Array.from({ length: n }, (_, i) => i)
      : shuffleIdx(n));
  const placed = (value as { o: number[] })?.o ?? [];
  const pool = seed.filter((c) => !placed.includes(c));
  const chip = (c: number, onTap: () => void) => (
    <button type="button" key={c} className="sd-cls-chip" onClick={onTap}>
      {items[c]}
    </button>
  );
  return (
    <div className="sd-ord">
      {Array.from({ length: n }, (_, p) => (
        <div key={p} className="sd-ord-slot">
          <p className="sd-ord-slot-label">Step {p + 1}</p>
          {placed[p] != null && (
            <div className="sd-ord-slot-body">
              {chip(placed[p], () =>
                // pulling a chip compacts the slots above the pool
                onChange({ o: placed.filter((_, x) => x !== p) }))}
            </div>
          )}
        </div>
      ))}
      <div className="sd-cls-pool">
        <p className="sd-cls-hint">Tap in order</p>
        <div className="sd-cls-items">
          {pool.length > 0
            ? pool.map((c) => chip(c, () => onChange({ o: [...placed, c] })))
            : <span className="sd-cls-done">All steps placed.</span>}
        </div>
      </div>
    </div>
  );
}

/** Classification pool→zone input: tap an item chip, then tap a zone card —
 *  the chip moves into it. Tapping a placed chip re-selects it to move it. */
function ClassificationInput({ q, value, onChange }: {
  q: QuizQuestion; value: AnswerValue | undefined;
  onChange: (v: AnswerValue) => void;
}) {
  const buckets = q.meta?.buckets ?? [];
  const ctx = q.meta?.context ?? "";
  const items = q.choices ?? [];
  const zs = (value as { z: number[] })?.z ?? [];
  const [sel, setSel] = useState<number | null>(null);
  const zoneOf = (i: number) => zs[i] ?? -1;
  const place = (zone: number) => {
    if (sel == null) return;
    const next = items.map((_, i) => zoneOf(i));
    next[sel] = zone;
    onChange({ z: next });
    setSel(null);
  };
  const chip = (i: number) => (
    <button type="button" key={i}
      className={`sd-cls-chip${sel === i ? " sd-cls-chip-sel" : ""}`}
      onClick={(e) => {
        // keep the enclosing zone's tap from placing the item again.
        e.stopPropagation();
        setSel(sel === i ? null : i);
      }}>
      {items[i]}
    </button>
  );
  const all = items.map((_, i) => i);
  const unplaced = all.filter((i) => zoneOf(i) < 0);
  return (
    <div className="sd-cls">
      {ctx !== "" && ctxBlock(ctx)}
      <div className="sd-cls-pool">
        <p className="sd-cls-hint">Tap an item, then tap a zone</p>
        <div className="sd-cls-items">
          {unplaced.length > 0
            ? unplaced.map(chip)
            : <span className="sd-cls-done">All items sorted.</span>}
        </div>
      </div>
      {buckets.map((b, bi) => (
        <div key={bi} role="button" tabIndex={0}
          className="sd-cls-zone"
          onClick={() => place(bi)}
          onKeyDown={(e) => {
            if (e.key === "Enter" || e.key === " ") {
              e.preventDefault();
              place(bi);
            }
          }}>
          <p className="sd-cls-zone-label">{b}</p>
          <div className="sd-cls-items">
            {all.filter((i) => zoneOf(i) === bi).map(chip)}
          </div>
        </div>
      ))}
    </div>
  );
}

/** Student-facing prompt: the editor's [blank] marker renders as a line. */
export const showPrompt = (s: string) => s.replace(/\[blank\]/gi, "________");

/** Prompt with the [blank] slot live-filled: `fill.text` (the student's pick
 *  or the correct word) renders inline styled; unset keeps the blank line. */
export const promptView = (prompt: string, fill?: { text?: string; ok?: boolean }) => {
  const parts = prompt.split(/\[blank\]/i);
  if (parts.length < 2) return showPrompt(prompt);
  return parts.map((part, i) => (
    <Fragment key={i}>
      {i > 0 &&
        (fill?.text ? (
          <span className={`sd-blank${fill.ok ? " sd-blank-ok" : ""}`}>
            {fill.text}
          </span>
        ) : (
          "________"
        ))}
      {part}
    </Fragment>
  ));
};

/** Student-facing context card — navy panel; a "X:" line prefix renders in
 *  sun-yellow like the design's equation labels, the rest white. */
export const ctxBlock = (ctx: string) => (
  <div className="sd-ctx">
    {ctx.split("\n").map((line, i) => {
      const m = line.match(/^(\S+:)\s*(.*)$/);
      return (
        <p key={i} className="sd-ctx-line">
          {m
            ? <><span className="sd-ctx-key">{m[1]}</span> {m[2]}</>
            : line}
        </p>
      );
    })}
  </div>
);

/** Per-question input for one qtype. Reports changes as AnswerValue payloads.
 *  Exported for the teacher preview (same inputs, nothing saved). */
export function AnswerInput({ q, value, onChange }: {
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
    case "multi_select": {
      const sel = (value as { sel: number[] })?.sel ?? [];
      const max = q.meta?.max ?? (q.choices ?? []).length;
      return (
        <>
          <p className="ds-caption" style={{ margin: "0 0 8px" }}>
            Select {q.meta?.min ?? 0}–{max} answers.
          </p>
          {(q.choices ?? []).map((c, ci) => (
            <QuizOption
              key={ci}
              letter={LETTERS[ci]}
              marker={
                <span className={`ds-ms-box${sel.includes(ci) ? " on" : ""}`}>
                  {sel.includes(ci) && <Icon name="check" size={14} />}
                </span>
              }
              state={sel.includes(ci) ? "selected" : "default"}
              onClick={() => onChange({ sel: sel.includes(ci)
                ? sel.filter((x) => x !== ci)
                : sel.length < max ? [...sel, ci] : sel })}
            >
              {c}
            </QuizOption>
          ))}
        </>
      );
    }
    case "true_false":
      return (
        <>
          {[true, false].map((v, i) => (
            <QuizOption
              key={String(v)}
              letter={LETTERS[i]}
              marker={
                <span className="ds-tf-badge">
                  <Icon name={v ? "check" : "close"} size={18} />
                </span>
              }
              state={(value as { b: boolean })?.b === v ? "selected" : "default"}
              onClick={() => onChange({ b: v })}
            >
              {v ? "True" : "False"}
            </QuizOption>
          ))}
        </>
      );
    case "fill_blank":
      // v2 cloze: pick the option that fills the blank (choices present);
      // legacy fill_blank (no choices) keeps the typed-answer field.
      if (q.choices?.length) {
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
      }
      return (
        <TextField
          label="Your answer"
          type="text"
          value={(value as { t: string })?.t ?? ""}
          onChange={(e) => onChange({ t: e.target.value })}
        />
      );
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
    case "classification":
      return <ClassificationInput q={q} value={value} onChange={onChange} />;
    case "ordering":
      return <OrderingInput q={q} value={value} onChange={onChange} />;
  }
}

/** Read-only review rows: correct pick highlighted, a missed pick marked wrong. */
function ReviewRows({ q, item }: { q: QuizQuestion; item?: ReviewItem }) {
  const ok = item?.is_correct === true;
  const student = item?.student;
  const mark = (
    <Icon name={ok ? "check" : "close"} size={18}
      className={ok ? "sd-rev-ok" : "sd-rev-bad"} />
  );
  switch (q.qtype) {
    case "multiple_choice": {
      const ci = item?.correct_index ?? -1;
      const si = student && "i" in student ? student.i : null;
      return (
        <>
          {(q.choices ?? []).map((c, i) => (
            <QuizOption key={i} letter={LETTERS[i]}
              state={i === ci ? "correct" : i === si && !ok ? "wrong" : "default"}>
              {c}
            </QuizOption>
          ))}
        </>
      );
    }
    case "multi_select": {
      const keys = item?.key?.indexes ?? [];
      const picks = student && "sel" in student ? student.sel : [];
      return (
        <>
          {(q.choices ?? []).map((c, i) => (
            <QuizOption key={i} letter={LETTERS[i]}
              state={keys.includes(i) ? "correct"
                : picks.includes(i) ? "wrong" : "default"}>
              {c}
            </QuizOption>
          ))}
        </>
      );
    }
    case "true_false": {
      const ci = item?.key?.correct === true ? 0 : 1;
      const si = student && "b" in student ? (student.b ? 0 : 1) : null;
      return (
        <>
          {[true, false].map((v, i) => (
            <QuizOption key={String(v)} letter={LETTERS[i]}
              marker={
                <span className="ds-tf-badge">
                  <Icon name={v ? "check" : "close"} size={18} />
                </span>
              }
              state={i === ci ? "correct" : i === si && !ok ? "wrong" : "default"}>
              {v ? "True" : "False"}
            </QuizOption>
          ))}
        </>
      );
    }
    case "enumeration": {
      const exp = item?.key?.items ?? [];
      const got = (student && "items" in student ? student.items : [])
        .filter((s) => s.trim() !== "");
      const earned = item?.earned ?? 0;
      return (
        <ListItemCard
          leading={mark}
          title={`Expected: ${exp.join(", ")}${item?.key?.ordered ? " (in order)" : ""}`}
          subtitle={`Yours: ${got.length ? got.join(", ") : "—"} · ${Math.round(earned * 100)}%`}
        />
      );
    }
    case "fill_blank": {
      if (q.choices?.length) {
        const ci = item?.correct_index ?? -1;
        const si = student && "i" in student ? student.i : null;
        return (
          <>
            {(q.choices ?? []).map((c, i) => (
              <QuizOption key={i} letter={LETTERS[i]}
                state={i === ci ? "correct" : i === si && !ok ? "wrong" : "default"}>
                {c}
              </QuizOption>
            ))}
          </>
        );
      }
      const accepted = item?.key?.accepted ?? [];
      const got = (student && "t" in student ? student.t : "").trim();
      return (
        <ListItemCard
          leading={mark}
          title={got || "—"}
          subtitle={ok
            ? "Your answer — correct"
            : `Your answer · Correct: ${accepted.join(" / ")}`}
        />
      );
    }
    case "classification": {
      const buckets = item?.key?.buckets ?? q.meta?.buckets ?? [];
      const zones = item?.key?.zones ?? [];
      const ctx = item?.key?.context ?? q.meta?.context ?? "";
      const zs = student && "z" in student ? student.z : [];
      const bName = (z: number | undefined) =>
        z != null && z >= 0 ? (buckets[z] ?? `Bucket ${z + 1}`) : "—";
      return (
        <>
          {ctx !== "" && ctxBlock(ctx)}
          {(q.choices ?? []).map((c, i) => {
            const wrong = zs[i] != null && zs[i] !== zones[i];
            return (
              <ListItemCard key={i}
                leading={
                  <Icon name={wrong ? "close" : "check"} size={18}
                    className={wrong ? "sd-rev-bad" : "sd-rev-ok"} />
                }
                title={`${c} → ${bName(zones[i])}`}
                subtitle={wrong ? `Yours: ${bName(zs[i])}` : undefined}
              />
            );
          })}
        </>
      );
    }
    case "ordering": {
      const correct = Array.isArray(item?.key?.correct)
        ? (item!.key!.correct as number[]) : [];
      const os = student && "o" in student ? student.o : [];
      const at = (p: number, list: number[]) =>
        p < list.length ? ((q.choices ?? [])[list[p]] ?? "—") : "—";
      return (
        <>
          {correct.map((_, p) => {
            const wrong = os[p] != null && os[p] !== correct[p];
            return (
              <ListItemCard key={p}
                leading={
                  <Icon name={wrong ? "close" : "check"} size={18}
                    className={wrong ? "sd-rev-bad" : "sd-rev-ok"} />
                }
                title={`${p + 1}. ${at(p, correct)}`}
                subtitle={wrong ? `Yours: ${at(p, os)}` : undefined}
              />
            );
          })}
        </>
      );
    }
    default: { // identification
      const accepted = item?.key?.accepted ?? [];
      const got = (student && "t" in student ? student.t : "").trim();
      return (
        <ListItemCard
          leading={mark}
          title={got || "—"}
          subtitle={ok
            ? "Your answer — correct"
            : `Your answer · Correct: ${accepted.join(" / ")}`}
        />
      );
    }
  }
}

/** Post-submit screen: score card + per-question review (keys only once released). */
function ReviewScreen({ qs, ps, review, onDone }: {
  qs: QuizQuestion[]; ps: AssessmentPart[]; review: ReviewResult; onDone: () => void;
}) {
  const items = new Map((review.items ?? []).map((it) => [it.question_id, it]));
  const partIndex = new Map(ps.map((p, i) => [p.id, i + 1]));
  const partMeta = new Map(ps.map((p) => [p.id, p]));
  return (
    <div className="sd-stack">
      <Card>
        <div className="sd-center">
          {review.released && review.score != null ? (
            <>
              <RingChart size={140} slices={[
                { value: review.score, series: 1 },
                { value: 100 - review.score, series: 0 },
              ]}>
                <span className="ds-h2">
                  {review.points_total != null
                    ? `${fmtPts(review.points_earned)}/${fmtPts(review.points_total)}`
                    : `${Math.round(review.score)}%`}
                </span>
              </RingChart>
              <p className="ds-body-sm">
                {review.points_total != null ? "points · " : ""}{review.total} questions
              </p>
            </>
          ) : (
            <EmptyState
              icon="done"
              title={review.released ? "Submitted" : "Already submitted"}
              body={review.released
                ? "Your answers are below."
                : "Your score will appear once your teacher releases it."}
            />
          )}
          <Button onClick={onDone}>Done</Button>
        </div>
      </Card>
      {review.released && qs.map((q, i) => {
        const item = items.get(q.id);
        const part = q.part_id ? partMeta.get(q.part_id) : undefined;
        return (
          <Card key={q.id}>
            <p className="ds-label sd-rev-head">
              Question {i + 1}
              <Icon name={item?.is_correct === true ? "check" : "close"} size={14}
                className={item?.is_correct === true ? "sd-rev-ok" : "sd-rev-bad"} />
              {part && (
                <span className="sd-dim">
                  · Activity {partIndex.get(part.id)}{part.title ? ` — ${part.title}` : ""}
                </span>
              )}
              {part && !part.scored && (
                <> <Chip variant="pastel" pastelColor="yellow">Not scored</Chip></>
              )}
            </p>
            <p className="ds-title">
              {q.qtype === "fill_blank"
                ? promptView(q.prompt, {
                    text: q.choices?.[item?.correct_index ?? -1],
                    ok: true,
                  })
                : showPrompt(q.prompt)}
            </p>
            <div className="sd-rev-rows">
              <ReviewRows q={q} item={item} />
            </div>
          </Card>
        );
      })}
    </div>
  );
}

export default function StudentQuiz() {
  const { id = "" } = useParams();
  const [params] = useSearchParams();
  const title = params.get("t") ?? "Quiz";
  const nav = useNavigate();
  const qc = useQueryClient();

  const questions = useQuery({ queryKey: ["questions", id], queryFn: () => fetchQuestions(id) });
  const parts = useQuery({ queryKey: ["parts", id], queryFn: () => fetchPartsPublic(id) });
  const review = useQuery({ queryKey: ["review", id], queryFn: () => reviewAttempt(id) });
  const [answers, setAnswers] = useState<Record<string, AnswerValue>>({});
  const [result, setResult] = useState<AttemptResult | null>(null);
  const [reviewNow, setReviewNow] = useState<ReviewResult | null>(null);
  const [showReview, setShowReview] = useState(false);
  const [qi, setQi] = useState(0);
  const [confirming, setConfirming] = useState(false);

  const submit = useMutation({
    mutationFn: () => submitAttempt(id, answers),
    onSuccess: async (r) => {
      setResult(r);
      // Fetch review eagerly so "Review answers" renders without a refetch gap.
      if (r.released) setReviewNow(await reviewAttempt(id));
      await qc.invalidateQueries({ queryKey: ["my-progress"] });
      await qc.invalidateQueries({ queryKey: ["review", id] });
    },
  });

  const reviewData = reviewNow ?? review.data;

  // Part-aware order — positions are per-part, a flat sort interleaves parts.
  const ps = parts.data ?? [];
  const qs = sortQuestionsByPart(questions.data ?? [], ps);

  if (result && !showReview) {
    return (
      <Card>
        <div className="sd-center">
          {result.score != null ? (
            <>
              <RingChart size={140} slices={[
                { value: result.score, series: 1 },
                { value: 100 - result.score, series: 0 },
              ]}>
                <span className="ds-h2">
                  {result.points_total != null
                    ? `${fmtPts(result.points_earned)}/${fmtPts(result.points_total)}`
                    : `${Math.round(result.score)}%`}
                </span>
              </RingChart>
              <p className="ds-body-sm">
                {result.points_total != null ? "points · " : ""}{result.total} questions
              </p>
            </>
          ) : (
            <EmptyState
              icon="done"
              title="Submitted"
              body="Your score will appear once your teacher releases it."
            />
          )}
          {result.released && (
            <Button variant="outline" onClick={() => setShowReview(true)}>
              Review answers
            </Button>
          )}
          <Button onClick={() => nav("/student/assessments")}>Done</Button>
        </div>
      </Card>
    );
  }

  // One-shot: a submitted attempt turns the page into review mode (no retake).
  if (reviewData?.attempted === true) {
    return (
      <ReviewScreen
        qs={qs}
        ps={ps}
        review={reviewData}
        onDone={() => nav("/student/assessments")}
      />
    );
  }

  /** part_id -> 1-based display index. */
  const partIndex = new Map(ps.map((p, i) => [p.id, i + 1]));
  const partOf = (qq: QuizQuestion | undefined) =>
    qq?.part_id ? ps.find((p) => p.id === qq.part_id) : undefined;
  const answered = qs.filter((q) => isAnswered(q, answers[q.id])).length;
  const q = qs[qi];
  const trySubmit = () => {
    if (answered < qs.length) setConfirming(true);
    else submit.mutate();
  };

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
          <div className="sd-quizhead">
            <span className="ds-label">Question {qi + 1} of {qs.length}</span>
            <ProgressBar value={(answered / qs.length) * 100} size="sm" />
          </div>
          <QuizNav
            count={qs.length}
            current={qi}
            answered={qs.map((qq) => isAnswered(qq, answers[qq.id]))}
            onSelect={setQi}
          />
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
            // A part's mode wins over the item's qtype for the tag — a
            // classification item inside a "Matching" part reads "Matching".
            // A bare classification tags by what it carries: a context block
            // = equation labeling, else zone count (binary vs multi).
            tag={partOf(q)?.mode === "matching"
              ? "Matching"
              : q.qtype === "classification"
                ? ((q.meta?.context ?? "") !== ""
                    ? "Equation labeling"
                    : (q.meta?.buckets?.length ?? 2) <= 2
                      ? "Binary classification"
                      : "Multi-category")
                : (TYPE_LABEL[q.qtype] ?? "Question")}
            // fill_blank: the picked option fills the [blank] slot inline.
            title={q.qtype === "fill_blank"
              ? promptView(q.prompt, {
                  text: (() => {
                    const v = answers[q.id];
                    return v && "i" in v ? q.choices?.[v.i] : undefined;
                  })(),
                })
              : showPrompt(q.prompt)}
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
              <Button loading={submit.isPending} onClick={trySubmit}>
                Submit answers
              </Button>
            )}
          </div>
          {submit.error && <p className="sd-err">{String(submit.error)}</p>}
          <Modal
            open={confirming}
            onClose={() => setConfirming(false)}
            title="Submit anyway?"
            actions={
              <>
                <Button variant="outline" onClick={() => setConfirming(false)}>
                  Keep going
                </Button>
                <Button
                  loading={submit.isPending}
                  onClick={() => { setConfirming(false); submit.mutate(); }}
                >
                  Submit
                </Button>
              </>
            }
          >
            {qs.length - answered} {qs.length - answered === 1 ? "question" : "questions"} unanswered.
            Submit anyway?
          </Modal>
        </>
      )}
    </div>
  );
}
