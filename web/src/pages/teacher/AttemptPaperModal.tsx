import { Fragment } from "react";
import { useQuery } from "@tanstack/react-query";
import { Icon, Modal } from "../../design-system";
import { fetchAttemptPaper, type AttemptPaper, type PaperAnswer } from "../../services/classes";
import { fmtPts } from "../../utils/stats";

const LETTERS = "ABCDEFGH";

/** Student-facing prompt: the editor's [blank] marker renders as a line. */
const showPrompt = (s: string) => s.replace(/\[blank\]/gi, "________");

/** Student-facing context card — navy panel; a "X:" line prefix renders in
 *  sun-yellow like the design's equation labels, the rest white. */
const ctxBlock = (ctx: string) => (
  <div className="sr-ctx">
    {ctx.split("\n").map((line, i) => {
      const m = line.match(/^(\S+:)\s*(.*)$/);
      return (
        <p key={i} className="sr-ctx-line">
          {m
            ? <><span className="sr-ctx-key">{m[1]}</span> {m[2]}</>
            : line}
        </p>
      );
    })}
  </div>
);

/** Prompt with the [blank] slot filled by the correct word (green inline). */
const promptView = (prompt: string, fillText?: string) => {
  const parts = prompt.split(/\[blank\]/i);
  if (parts.length < 2) return showPrompt(prompt);
  return parts.map((part, i) => (
    <Fragment key={i}>
      {i > 0 &&
        (fillText ? <span className="sr-blank">{fillText}</span> : "________")}
      {part}
    </Fragment>
  ));
};

const fmtDate = (iso: string | null | undefined) =>
  iso
    ? new Date(iso).toLocaleDateString(undefined, {
        year: "numeric", month: "short", day: "numeric",
      })
    : "—";

/** Score cell: "7 / 10 pts" for points-era attempts, "%" fallback for older ones. */
const fmtScore = (a: NonNullable<AttemptPaper["attempt"]>) =>
  a.points_total != null
    ? `${fmtPts(a.points_earned)} / ${fmtPts(a.points_total)} pts`
    : a.score == null
      ? "—"
      : `${Math.round(a.score)}%`;

type StudentPick = { i?: number; b?: boolean; t?: string; items?: string[];
  sel?: number[]; z?: number[]; o?: number[] };

/** One lettered option row: green = correct answer, red = the student's
 *  missed pick. A correct pick gets both (green row + check). */
function PaperOption({ letter, text, correct, pickedWrong }: {
  letter: string; text: string; correct: boolean; pickedWrong: boolean;
}) {
  return (
    <div className={`sr-opt${correct ? " sr-opt-ok" : pickedWrong ? " sr-opt-bad" : ""}`}>
      <span className="sr-opt-letter">{letter}</span>
      <span className="sr-opt-text">{text}</span>
      {correct && <Icon name="check" size={16} className="sr-opt-mark-ok" />}
      {pickedWrong && <Icon name="close" size={16} className="sr-opt-mark-bad" />}
    </div>
  );
}

function PaperQuestion({ n, q, ans }: {
  n: number; q: AttemptPaper["questions"][number]; ans?: PaperAnswer;
}) {
  const stu = (ans?.answer ?? null) as StudentPick | null;
  const ok = ans?.is_correct === true;
  let body;
  switch (q.qtype) {
    case "multi_select": {
      const keys = q.answer?.indexes ?? [];
      const picks = stu?.sel ?? [];
      body = (q.choices ?? []).map((c, i) => (
        <PaperOption key={i} letter={LETTERS[i]} text={c}
          correct={keys.includes(i)}
          pickedWrong={picks.includes(i) && !keys.includes(i)} />
      ));
      break;
    }
    case "true_false": {
      const ci = q.answer?.correct === true ? 0 : 1;
      const si = stu?.b == null ? null : stu.b ? 0 : 1;
      body = ["True", "False"].map((t, i) => (
        <PaperOption key={t} letter={LETTERS[i]} text={t}
          correct={i === ci} pickedWrong={i === si && !ok} />
      ));
      break;
    }
    case "fill_blank":
      if (q.choices?.length) {
        // Options mode (v2): pick the option that fills the blank.
        const ci = q.correct_index ?? -1;
        const si = stu?.i ?? null;
        body = (q.choices ?? []).map((c, i) => (
          <PaperOption key={i} letter={LETTERS[i]} text={c}
            correct={i === ci} pickedWrong={i === si && !ok} />
        ));
        break;
      }
      // fall through — legacy typed fill_blank
    case "identification": {
      const accepted = q.answer?.accepted ?? [];
      const got = (stu?.t ?? "").trim();
      body = (
        <>
          <div className={`sr-ans ${ok ? "sr-ans-ok" : "sr-ans-bad"}`}>
            Student answer: {got || "—"}
            {ok && <Icon name="check" size={16} className="sr-opt-mark-ok" />}
            {!ok && ans && <Icon name="close" size={16} className="sr-opt-mark-bad" />}
          </div>
          {!ok && (
            <div className="sr-ans sr-ans-ok">
              Correct answer{accepted.length > 1 ? "s" : ""}: {accepted.join(" / ")}
            </div>
          )}
        </>
      );
      break;
    }
    case "classification": {
      const buckets = q.answer?.buckets ?? [];
      const zones = q.answer?.zones ?? [];
      const ctx = q.answer?.context ?? "";
      const zs = stu?.z ?? [];
      const bName = (z: number | undefined) =>
        z != null && z >= 0 ? (buckets[z] ?? `Bucket ${z + 1}`) : "—";
      body = (
        <>
          {ctx !== "" && ctxBlock(ctx)}
          {(q.choices ?? []).map((c, i) => {
            const wrong = zs[i] != null && zs[i] !== zones[i];
            return (
              <div key={i}
                className={`sr-ans ${wrong ? "sr-ans-bad" : "sr-ans-ok"}`}>
                {c} → {bName(zones[i])}
                {!wrong && <Icon name="check" size={16} className="sr-opt-mark-ok" />}
                {wrong && (
                  <>
                    <Icon name="close" size={16} className="sr-opt-mark-bad" />
                    {" "}· student: {bName(zs[i])}
                  </>
                )}
              </div>
            );
          })}
        </>
      );
      break;
    }
    case "ordering": {
      const correct = Array.isArray(q.answer?.correct)
        ? (q.answer!.correct as number[]) : [];
      const os = stu?.o ?? [];
      const at = (p: number, list: number[]) =>
        p < list.length ? ((q.choices ?? [])[list[p]] ?? "—") : "—";
      body = (
        <>
          {correct.map((_, p) => {
            const wrong = os[p] != null && os[p] !== correct[p];
            return (
              <div key={p}
                className={`sr-ans ${wrong ? "sr-ans-bad" : "sr-ans-ok"}`}>
                {p + 1}. {at(p, correct)}
                {!wrong && <Icon name="check" size={16} className="sr-opt-mark-ok" />}
                {wrong && (
                  <>
                    <Icon name="close" size={16} className="sr-opt-mark-bad" />
                    {" "}· student: {at(p, os)}
                  </>
                )}
              </div>
            );
          })}
        </>
      );
      break;
    }
    case "enumeration": {
      const exp = q.answer?.items ?? [];
      const got = (stu?.items ?? []).filter((s) => s.trim() !== "");
      const earned = ans?.earned ?? 0;
      body = (
        <>
          <div className={`sr-ans ${ok ? "sr-ans-ok" : "sr-ans-bad"}`}>
            Yours: {got.length ? got.join(", ") : "—"} · {Math.round(earned * 100)}%
          </div>
          <div className="sr-ans sr-ans-ok">
            Expected: {exp.join(", ")}{q.answer?.ordered ? " (in order)" : ""}
          </div>
        </>
      );
      break;
    }
    default: { // multiple_choice
      const ci = q.correct_index ?? -1;
      const si = stu?.i ?? null;
      body = (q.choices ?? []).map((c, i) => (
        <PaperOption key={i} letter={LETTERS[i]} text={c}
          correct={i === ci} pickedWrong={i === si && !ok} />
      ));
    }
  }
  return (
    <div className="sr-q">
      <p className="sr-q-prompt">
        <span className="sr-q-num">{n}.</span>{" "}
        {q.qtype === "fill_blank"
          ? promptView(q.prompt, q.choices?.[q.correct_index ?? -1])
          : showPrompt(q.prompt)}
      </p>
      <div className="sr-q-opts">{body}</div>
    </div>
  );
}

/** The student's paper for one assessment, laid out like a graded test paper:
 *  meta header (lesson, teacher, student, dates, score), then per-part
 *  questions with correct answers highlighted green and missed picks red. */
export function AttemptPaperModal({ open, onClose, assessmentId, studentId,
    studentName, teacherName, released }: {
  open: boolean; onClose: () => void;
  assessmentId: string | null; studentId: string;
  studentName: string; teacherName: string; released: boolean;
}) {
  const paper = useQuery({
    queryKey: ["attempt-paper", assessmentId, studentId],
    queryFn: () => fetchAttemptPaper(assessmentId!, studentId),
    enabled: open && assessmentId != null,
  });
  const p = paper.data;

  const groups: { part: AttemptPaper["parts"][number] | null; qs: AttemptPaper["questions"] }[] = [];
  if (p) {
    const byPart = new Map<string | null, AttemptPaper["questions"]>();
    for (const q of p.questions) {
      const k = q.part_id ?? null;
      byPart.set(k, [...(byPart.get(k) ?? []), q]);
    }
    for (const part of p.parts) {
      if (byPart.has(part.id)) {
        groups.push({ part, qs: byPart.get(part.id)! });
        byPart.delete(part.id);
      }
    }
    // Ungrouped questions plus orphans whose part was deleted.
    const rest = [...byPart.values()].flat();
    if (rest.length) groups.push({ part: null, qs: rest });
  }

  return (
    <Modal open={open} onClose={onClose} size="wide"
      title={p?.assessmentTitle ?? "Test paper"}>
      {paper.isLoading && <p className="ds-body">Loading paper…</p>}
      {paper.error != null && (
        <p className="td-err">Couldn't load the paper: {String(paper.error)}</p>
      )}
      {p && (
        <>
          <div className="sr-paper-meta">
            <span><b>Lesson</b>{p.lessonTitle}</span>
            <span><b>Teacher</b>{teacherName}</span>
            <span><b>Student</b>{studentName}</span>
            <span><b>Published</b>{fmtDate(p.publishedAt)}</span>
            <span><b>Answered</b>{fmtDate(p.attempt?.submitted_at)}</span>
            <span><b>Score</b>
              {p.attempt == null ? "Not taken" : fmtScore(p.attempt)}
              {p.attempt != null && !released && (
                <em className="sr-paper-note"> (not released to student)</em>
              )}
            </span>
          </div>
          {groups.map(({ part, qs }, gi) => (
            <section key={part?.id ?? "ungrouped"} className="sr-paper-part">
              <h4 className="sr-paper-part-title">
                {part ? `Activity ${gi + 1}${part.title ? ` — ${part.title}` : ""}` : "Questions"}
                {part && part.scored && part.points != null && (
                  <em className="sr-paper-note"> ({fmtPts(part.points)} pt{part.points === 1 ? "" : "s"} each)</em>
                )}
                {part && !part.scored && <em className="sr-paper-note"> (not scored)</em>}
              </h4>
              {part?.directions && (
                <p className="sr-paper-part-dir">{part.directions}</p>
              )}
              {qs.map((q, i) => (
                <PaperQuestion key={q.id} n={i + 1} q={q} ans={p.answers[q.id]} />
              ))}
            </section>
          ))}
          {p.questions.length === 0 && (
            <p className="ds-body" style={{ color: "var(--ds-muted)" }}>
              No questions in this activity yet.
            </p>
          )}
        </>
      )}
    </Modal>
  );
}
