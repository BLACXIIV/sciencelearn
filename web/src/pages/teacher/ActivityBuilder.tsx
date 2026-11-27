import { useEffect, useLayoutEffect, useRef, useState, type ReactNode } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { fetchLesson } from "../../services/learning";
import {
  deletePart, deleteQuestion, fetchAssessment, fetchParts, fetchQuestionsFull,
  releaseScores, renameAssessment, reorderPartPositions, reorderQuestionPositions,
  setAssessmentPublished, setScoreRelease, upsertPart, upsertQuestion,
} from "../../services/activities";
import {
  Button, Card, Checkbox, Chip, Icon, IconButton, Modal, Select,
  StatusBadge, Switch, TextArea, TextField, Toast,
} from "../../design-system";
import PopoverMenu from "../../components/PopoverMenu";
import type { ActivityMode, AssessmentPart, Question, QuestionType } from "../../types";
import { fmtPts } from "../../utils/stats";
import { moveInList, numOr } from "../../utils/reorder";
import { cleanChars } from "../../utils/text";
import "../teacher.css";

/** Quiz modes offered when creating a part. `supported` = the question
 *  editor and student runner can handle it today; others are "(soon)". */
const MODES: { value: ActivityMode; label: string; supported: boolean }[] = [
  { value: "multiple_choice", label: "Multiple Choice", supported: true },
  { value: "true_false", label: "True or False", supported: true },
  { value: "fill_blank", label: "Fill in the Blank", supported: true },
  { value: "identification", label: "Identification", supported: true },
  { value: "enumeration", label: "Enumeration", supported: true },
  { value: "multi_select", label: "Multi-Select", supported: true },
  { value: "classification", label: "Classification", supported: true },
  { value: "matching", label: "Matching", supported: true },
  { value: "ordering", label: "Ordering", supported: true },
  { value: "table_fill", label: "Table Fill-in", supported: false },
  { value: "hotspot", label: "Spot the Item", supported: false },
  { value: "scenario", label: "Scenario / Decision", supported: false },
];

const modeLabel = (m?: string | null) =>
  m == null ? "Multiple Choice" : MODES.find((x) => x.value === m)?.label ?? m.replace(/_/g, " ");

/** Supabase errors are plain objects ({message, details, hint}), not Error
 *  instances — String(e) prints "[object Object]". Unwrap for display. */
const errText = (e: unknown): string =>
  e instanceof Error ? e.message
    : typeof e === "object" && e != null && "message" in e
      ? String((e as { message: unknown }).message)
    : String(e);

const MODE_TO_QTYPE: Partial<Record<ActivityMode, QuestionType>> = {
  multiple_choice: "multiple_choice",
  multi_select: "multi_select",
  true_false: "true_false",
  fill_blank: "fill_blank",
  identification: "identification",
  enumeration: "enumeration",
  classification: "classification",
  matching: "classification",
  ordering: "ordering",
};

const QTYPES: { value: QuestionType; label: string }[] = [
  { value: "multiple_choice", label: "Multiple Choice" },
  { value: "multi_select", label: "Multi-Select" },
  { value: "true_false", label: "True or False" },
  { value: "fill_blank", label: "Fill in the Blank" },
  { value: "identification", label: "Identification" },
  { value: "enumeration", label: "Enumeration" },
  { value: "classification", label: "Classification" },
  { value: "ordering", label: "Ordering" },
];

/** Editable draft of one question, in form-friendly shape. */
interface Draft {
  id?: string;
  part_id: string | null;
  qtype: QuestionType;
  prompt: string;
  position: number;
  choices: string[];
  correct: number;
  sel: number[];
  minSel: number;
  maxSel: number;
  boolAnswer: boolean;
  accepted: string[];
  items: string[];
  ordered: boolean;
  partial: boolean;
  buckets: string[];
  zones: number[];
  context: string;
  shuffle: boolean;
}

const emptyDraft = (pos: number, qtype: QuestionType = "multiple_choice",
  partId: string | null = null): Draft => ({
  part_id: partId, qtype, prompt: "", position: pos,
  choices: ["", "", "", ""], correct: 0,
  sel: [], minSel: 1, maxSel: 2,
  boolAnswer: true,
  accepted: [""], items: ["", "", ""], ordered: false, partial: true,
  buckets: ["", ""], zones: [0, 0, 0], context: "", shuffle: true,
});

const toDraft = (q: Question): Draft => ({
  id: q.id, part_id: q.part_id ?? null, qtype: q.qtype, prompt: q.prompt, position: q.position,
  choices: q.choices
    ?? (q.qtype === "fill_blank" && q.answer?.accepted?.length
      ? [...q.answer.accepted, "", "", "", ""].slice(0, Math.max(4, q.answer.accepted.length))
      : ["", "", "", ""]),
  correct: q.correct_index ?? 0,
  sel: q.answer?.indexes ?? [],
  minSel: q.answer?.min ?? 1,
  maxSel: q.answer?.max ?? Math.max(q.answer?.indexes?.length ?? 0, 1),
  boolAnswer: q.answer?.correct === true,
  accepted: q.answer?.accepted ?? [""],
  items: q.qtype === "classification"
    ? [...(q.choices ?? []), "", "", ""].slice(0, Math.max(3, q.choices?.length ?? 0))
    : q.qtype === "ordering"
      ? (() => {
          const key = Array.isArray(q.answer?.correct)
            ? (q.answer!.correct as number[]) : [];
          const un = key.length
            ? key.map((c) => q.choices?.[c] ?? "")
            : [...(q.choices ?? [])];
          return [...un, "", "", ""].slice(0, Math.max(3, un.length));
        })()
      : (q.answer?.items ?? ["", "", ""]),
  ordered: q.answer?.ordered ?? false,
  partial: q.answer?.partial ?? true,
  buckets: q.answer?.buckets?.length ? q.answer.buckets : ["", ""],
  zones: q.answer?.zones ?? [0, 0, 0],
  context: q.answer?.context ?? "",
  shuffle: q.answer?.shuffle !== false,
});

function draftValid(d: Draft): string | null {
  if (!d.prompt.trim()) return "Enter the question prompt.";
  switch (d.qtype) {
    case "multiple_choice": {
      const filled = d.choices.filter((c) => c.trim() !== "");
      if (filled.length < 2) return "Add at least two choices.";
      if (!d.choices[d.correct]?.trim()) return "Pick which choice is correct.";
      return null;
    }
    case "multi_select": {
      const filled = d.choices.filter((c) => c.trim() !== "");
      if (filled.length < 2) return "Add at least two choices.";
      if (!d.sel.some((i) => d.choices[i]?.trim()))
        return "Tick at least one correct choice.";
      if (d.minSel < 0 || d.minSel > d.maxSel)
        return "Required selections: min must be 0 or more and no more than max.";
      if (d.maxSel < 1 || d.maxSel > filled.length)
        return `Max selections must be between 1 and ${filled.length}.`;
      return null;
    }
    case "fill_blank": {
      if (!d.prompt.includes("[blank]"))
        return "Insert [blank] where the gap is.";
      const filled = d.choices.filter((c) => c.trim() !== "");
      if (filled.length < 2) return "Add at least two options.";
      if (!d.choices[d.correct]?.trim()) return "Pick which option is correct.";
      return null;
    }
    case "identification":
      return d.accepted.some((a) => a.trim()) ? null : "Add at least one accepted answer.";
    case "enumeration":
      return d.items.filter((i) => i.trim()).length >= 2 ? null : "Add at least two expected items.";
    case "classification": {
      if (d.buckets.length < 2 || d.buckets.some((b) => !b.trim()))
        return "Name every zone (at least two).";
      if (d.items.filter((i) => i.trim()).length < 2) return "Add at least two items.";
      return null;
    }
    case "ordering":
      return d.items.filter((i) => i.trim()).length >= 2
        ? null
        : "Add at least two items to order.";
    default:
      return null;
  }
}

/** One-line summary of a question's answer key for the row's hint text. */
function answerHint(q: Question): string {
  switch (q.qtype) {
    case "multiple_choice":
    case "fill_blank": {
      const c = q.choices?.[q.correct_index ?? -1];
      return c ? `Answer: ${c}` : "No key set";
    }
    case "true_false":
      return `Answer: ${q.answer?.correct === true ? "True" : "False"}`;
    case "identification": {
      const acc = q.answer?.accepted ?? [];
      return acc.length ? `Answer: ${acc[0]}${acc.length > 1 ? ` +${acc.length - 1}` : ""}` : "No key set";
    }
    case "multi_select":
      return `${(q.answer?.indexes ?? []).length} correct`;
    case "enumeration":
      return `${(q.answer?.items ?? []).length} items`;
    case "classification":
      return `${(q.answer?.buckets ?? []).length} zones`;
    case "ordering":
      return `${(q.choices ?? []).length} steps`;
    default:
      return "";
  }
}

/** Auto-growing textarea for answer fields — rows=1, `field-sizing: content`
 *  where supported with a scrollHeight resize as the fallback. No scrollbars,
 *  no manual resize handle. */
function AutoTextArea({ clean, ...props }:
  React.TextareaHTMLAttributes<HTMLTextAreaElement> & { clean?: boolean }) {
  const ref = useRef<HTMLTextAreaElement>(null);
  useLayoutEffect(() => {
    const el = ref.current;
    if (!el) return;
    el.style.height = "auto";
    el.style.height = `${el.scrollHeight}px`;
  }, [props.value]);
  return (
    <textarea rows={1} {...props} ref={ref}
      onChange={(e) => {
        if (clean) e.target.value = cleanChars(e.target.value);
        props.onChange?.(e);
      }} />
  );
}

/** Bordered answer field — auto-growing textarea with the remove "×" inside
 *  its trailing edge (44px tap target). `correct` tints the border teal. */
function AnsField({ value, placeholder, correct, removeDisabled, onText, onRemove }: {
  value: string; placeholder: string; correct?: boolean;
  removeDisabled?: boolean;
  onText: (v: string) => void; onRemove: () => void;
}) {
  return (
    <div className={`td-afield${correct ? " correct" : ""}`}>
      <AutoTextArea clean value={value} placeholder={placeholder}
        aria-label={placeholder}
        onChange={(e) => onText(e.target.value)} />
      <button type="button" className="td-ax" aria-label={`Remove ${placeholder}`}
        disabled={removeDisabled} onClick={onRemove}>
        <Icon name="close" size={18} />
      </button>
    </div>
  );
}

/** Index marker shared by non-choice answer lists. */
const ansNum = (i: number) => <span className="td-arnum">{i + 1}</span>;

/** Dynamic list of short answers (choices / accepted / enumeration items). */
function ListInput({ items, hint, removable, onChange }: {
  items: string[]; hint: string; removable: boolean;
  onChange: (items: string[]) => void;
}) {
  return (
    <div className="td-stack">
      {items.map((v, i) => (
        <div key={i} className="td-arow">
          {ansNum(i)}
          <div className="td-acol">
            <AnsField value={v} placeholder={`${hint} ${i + 1}`}
              removeDisabled={!removable}
              onText={(t) => onChange(items.map((x, xi) => (xi === i ? t : x)))}
              onRemove={() => onChange(items.filter((_, xi) => xi !== i))} />
          </div>
        </div>
      ))}
    </div>
  );
}

function QuestionForm({ draft, parts, number, points, onChange, onSave, onCancel, saving, error }: {
  draft: Draft; parts: AssessmentPart[]; number: number; points: number;
  onChange: (d: Draft) => void;
  onSave: () => void; onCancel: () => void;
  saving: boolean; error: unknown;
}) {
  const set = <K extends keyof Draft>(k: K, v: Draft[K]) => onChange({ ...draft, [k]: v });
  const moveChoice = (i: number, d: -1 | 1) => {
    const j = i + d, choices = [...draft.choices];
    [choices[i], choices[j]] = [choices[j], choices[i]];
    onChange({ ...draft, choices,
      correct: draft.correct === i ? j : draft.correct === j ? i : draft.correct,
      sel: draft.sel.map((s) => s === i ? j : s === j ? i : s) });
  };
  const removeChoice = (i: number) => {
    onChange({ ...draft,
      choices: draft.choices.filter((_, x) => x !== i),
      correct: draft.correct === i ? 0
        : draft.correct > i ? draft.correct - 1 : draft.correct,
      sel: draft.sel.filter((s) => s !== i).map((s) => s > i ? s - 1 : s) });
  };

  const promptRef = useRef<HTMLTextAreaElement>(null);
  /** Insert the [blank] gap marker at the caret (end if unfocused). */
  const insertBlank = () => {
    const el = promptRef.current;
    const s = el?.selectionStart ?? draft.prompt.length;
    const e = el?.selectionEnd ?? draft.prompt.length;
    set("prompt", `${draft.prompt.slice(0, s)}[blank]${draft.prompt.slice(e)}`);
    requestAnimationFrame(() => {
      el?.focus();
      el?.setSelectionRange(s + 7, s + 7);
    });
  };

  const markerStyle = {
    width: 18, height: 18, accentColor: "var(--ds-blue)",
  };
  const choiceRow = (i: number, marker: ReactNode, correct: boolean) => (
    <div key={i} className="td-arow">
      {marker}
      <div className="td-acol">
        <AnsField value={draft.choices[i]} correct={correct}
          placeholder={`Choice ${String.fromCharCode(65 + i)}`}
          removeDisabled={draft.choices.length <= 2}
          onText={(t) => set("choices",
            draft.choices.map((x, xi) => (xi === i ? t : x)))}
          onRemove={() => removeChoice(i)} />
      </div>
      <span className="td-actions" style={{ alignSelf: "flex-start", paddingTop: 2 }}>
        <IconButton icon="up" label="Move up" disabled={i === 0}
          onClick={() => moveChoice(i, -1)} />
        <IconButton icon="down" label="Move down" disabled={i === draft.choices.length - 1}
          onClick={() => moveChoice(i, 1)} />
      </span>
    </div>
  );
  const radioMark = (i: number) => (
    <span className="td-amark">
      <input type="radio" name="correct" checked={draft.correct === i}
        onChange={() => set("correct", i)} style={markerStyle} />
    </span>
  );
  const checkMark = (i: number) => (
    <span className="td-amark">
      <input type="checkbox" checked={draft.sel.includes(i)}
        onChange={() => set("sel", draft.sel.includes(i)
          ? draft.sel.filter((x) => x !== i)
          : [...draft.sel, i])}
        style={markerStyle} />
    </span>
  );
  const addChoiceBtn = (cap: number) => draft.choices.length < cap && (
    <div>
      <Button variant="outline" size="sm" leadingIcon="add" type="button"
        onClick={() => set("choices", [...draft.choices, ""])}>
        Add choice
      </Button>
    </div>
  );

  const setItem = (i: number, v: string) =>
    set("items", draft.items.map((x, xi) => (xi === i ? v : x)));
  const setZone = (i: number, z: number) =>
    set("zones", draft.zones.map((x, xi) => (xi === i ? z : x)));
  const moveItem = (i: number, d: -1 | 1) => {
    const j = i + d, items = [...draft.items], zones = [...draft.zones];
    [items[i], items[j]] = [items[j], items[i]];
    [zones[i], zones[j]] = [zones[j], zones[i]];
    onChange({ ...draft, items, zones });
  };
  const removeItem = (i: number) => onChange({ ...draft,
    items: draft.items.filter((_, x) => x !== i),
    zones: draft.zones.filter((_, x) => x !== i) });
  const removeZone = (i: number) => onChange({ ...draft,
    buckets: draft.buckets.filter((_, x) => x !== i),
    zones: draft.zones.map((z) => (z === i ? 0 : z > i ? z - 1 : z)) });
  const addItemBtn = draft.items.length < 10 && (
    <div>
      <Button variant="outline" size="sm" leadingIcon="add" type="button"
        onClick={() => onChange({ ...draft,
          items: [...draft.items, ""], zones: [...draft.zones, 0] })}>
        Add item
      </Button>
    </div>
  );

  /** "Move to part" — changes part_id; position lands at the target's end. */
  const moveTarget = (partId: string | null) => {
    onChange({ ...draft, part_id: partId });
  };

  return (
    <Card variant="white" className="td-qedit">
      <div className="td-qedit-head">
        <span className="ds-label">Question {number}</span>
        <span className="ds-caption" style={{ color: "var(--ds-muted)" }}>
          {fmtPts(points)} pt{points === 1 ? "" : "s"}
        </span>
        <IconButton icon="close" label="Close editor" onClick={onCancel} />
      </div>
      <div className="td-stack">
        <Select label="Move to part" value={draft.part_id ?? ""}
          onChange={(e) => moveTarget(e.target.value === "" ? null : e.target.value)}
          options={[
            ...parts.map((p, i) => ({
              value: p.id, label: `Activity ${i + 1}${p.title ? ` — ${p.title}` : ""}`,
            })),
            { value: "", label: "Ungrouped" },
          ]} />
        <Select label="Question type" value={draft.qtype}
          onChange={(e) => set("qtype", e.target.value as QuestionType)}
          options={QTYPES.map((t) => ({ value: t.value, label: t.label }))} />
        <TextArea clean label="Prompt" rows={2} value={draft.prompt}
          ref={promptRef}
          onChange={(e) => set("prompt", e.target.value)} />

        {draft.qtype === "multiple_choice" && (
          <>
            <p className="ds-label" style={{ margin: 0 }}>Choices</p>
            <p className="td-ahelp">Tap the circle for the correct answer.</p>
            {draft.choices.map((_, i) => choiceRow(i, radioMark(i), draft.correct === i))}
            {addChoiceBtn(6)}
          </>
        )}
        {draft.qtype === "fill_blank" && (
          <>
            <div>
              <Button variant="outline" size="sm" leadingIcon="add" type="button"
                onClick={insertBlank}>
                Insert [blank]
              </Button>
            </div>
            <p className="ds-label" style={{ margin: 0 }}>Options</p>
            <p className="td-ahelp">Tap the circle for the correct answer.</p>
            {draft.choices.map((_, i) => choiceRow(i, radioMark(i), draft.correct === i))}
            {addChoiceBtn(6)}
          </>
        )}
        {draft.qtype === "multi_select" && (
          <>
            <p className="ds-label" style={{ margin: 0 }}>Choices</p>
            <p className="td-ahelp">Tap the squares for the correct answers.</p>
            {draft.choices.map((_, i) => choiceRow(i, checkMark(i), draft.sel.includes(i)))}
            {addChoiceBtn(8)}
            <p className="ds-label" style={{ margin: 0 }}>Required selections</p>
            <div className="td-row">
              <div style={{ flex: 1 }}>
                <TextField clean label="Min" type="number" min={0}
                  value={Number.isNaN(draft.minSel) ? "" : draft.minSel}
                  onChange={(e) => set("minSel", numOr(e.target.value, -1))} />
              </div>
              <div style={{ flex: 1 }}>
                <TextField clean label="Max" type="number" min={1}
                  value={Number.isNaN(draft.maxSel) ? "" : draft.maxSel}
                  onChange={(e) => set("maxSel", numOr(e.target.value, -1))} />
              </div>
            </div>
            <Checkbox label="Partial credit — correct picks minus wrong picks, otherwise all-or-nothing"
              checked={draft.partial} onChange={(e) => set("partial", e.target.checked)} />
          </>
        )}
        {draft.qtype === "true_false" && (
          <>
            <p className="ds-caption" style={{ margin: 0 }}>Answer key</p>
            <div className="td-tfrow" role="group" aria-label="Correct answer">
              {(["true", "false"] as const).map((v) => (
                <button key={v} type="button"
                  className={`td-tf${draft.boolAnswer === (v === "true") ? " on" : ""}`}
                  aria-pressed={draft.boolAnswer === (v === "true")}
                  onClick={() => set("boolAnswer", v === "true")}>
                  {v === "true" ? "True" : "False"}
                </button>
              ))}
            </div>
          </>
        )}
        {draft.qtype === "identification" && (
          <>
            <p className="ds-label" style={{ margin: 0 }}>Accepted answers</p>
            <p className="td-ahelp">Matching ignores case and surrounding spaces.</p>
            <ListInput items={draft.accepted} hint="Answer"
              removable={draft.accepted.length > 1}
              onChange={(v) => set("accepted", v)} />
            <div>
              <Button variant="outline" size="sm" leadingIcon="add" type="button"
                onClick={() => set("accepted", [...draft.accepted, ""])}>
                Add accepted answer
              </Button>
            </div>
          </>
        )}
        {draft.qtype === "enumeration" && (
          <>
            <p className="ds-label" style={{ margin: 0 }}>Expected items</p>
            <ListInput items={draft.items} hint="Item"
              removable={draft.items.length > 2}
              onChange={(v) => set("items", v)} />
            <div>
              <Button variant="outline" size="sm" leadingIcon="add" type="button"
                onClick={() => set("items", [...draft.items, ""])}>
                Add item
              </Button>
            </div>
            <Checkbox label="Order matters — items must appear in this order"
              checked={draft.ordered} onChange={(e) => set("ordered", e.target.checked)} />
            <Checkbox label="Partial credit — score each correct item, otherwise all-or-nothing"
              checked={draft.partial} onChange={(e) => set("partial", e.target.checked)} />
          </>
        )}
        {draft.qtype === "classification" && (
          <>
            <TextArea clean label="Context shown to students (optional)" rows={3}
              value={draft.context}
              onChange={(e) => set("context", e.target.value)} />
            <p className="ds-label" style={{ margin: 0 }}>Zones</p>
            {draft.buckets.map((b, bi) => (
              <div key={bi} className="td-arow">
                {ansNum(bi)}
                <div className="td-acol">
                  <AnsField value={b} placeholder={`Zone ${bi + 1}`}
                    removeDisabled={draft.buckets.length <= 2}
                    onText={(t) => set("buckets",
                      draft.buckets.map((x, xi) => (xi === bi ? t : x)))}
                    onRemove={() => removeZone(bi)} />
                </div>
              </div>
            ))}
            {draft.buckets.length < 6 && (
              <div>
                <Button variant="outline" size="sm" leadingIcon="add" type="button"
                  onClick={() => set("buckets", [...draft.buckets, ""])}>
                  Add zone
                </Button>
              </div>
            )}
            <p className="ds-label" style={{ margin: 0 }}>Items and their correct zone</p>
            {draft.items.map((item, i) => (
              <div key={i} className="td-arow">
                {ansNum(i)}
                <div className="td-acol">
                  <AnsField value={item} placeholder={`Item ${i + 1}`}
                    removeDisabled={draft.items.length <= 2}
                    onText={(t) => setItem(i, t)}
                    onRemove={() => removeItem(i)} />
                  <div className="ds-field">
                    <div className="ds-select-wrap">
                      <select aria-label={`Zone for item ${i + 1}`}
                        value={draft.zones[i] ?? 0}
                        onChange={(e) => setZone(i, Number(e.target.value))}>
                        {draft.buckets.map((b, bi) => (
                          <option key={bi} value={bi}>
                            {b.trim() || `Bucket ${bi + 1}`}
                          </option>
                        ))}
                      </select>
                      <Icon name="chevron" size={18} className="ds-select-chev" />
                    </div>
                  </div>
                </div>
                <span className="td-actions" style={{ alignSelf: "flex-start", paddingTop: 2 }}>
                  <IconButton icon="up" label="Move up" disabled={i === 0}
                    onClick={() => moveItem(i, -1)} />
                  <IconButton icon="down" label="Move down"
                    disabled={i === draft.items.length - 1}
                    onClick={() => moveItem(i, 1)} />
                </span>
              </div>
            ))}
            {addItemBtn}
          </>
        )}
        {draft.qtype === "ordering" && (
          <>
            <p className="ds-label" style={{ margin: 0 }}>
              Items — enter in the CORRECT order
            </p>
            {draft.items.map((item, i) => (
              <div key={i} className="td-arow">
                {ansNum(i)}
                <div className="td-acol">
                  <AnsField value={item} placeholder={`Item ${i + 1}`}
                    removeDisabled={draft.items.length <= 2}
                    onText={(t) => setItem(i, t)}
                    onRemove={() => removeItem(i)} />
                </div>
                <span className="td-actions" style={{ alignSelf: "flex-start", paddingTop: 2 }}>
                  <IconButton icon="up" label="Move up" disabled={i === 0}
                    onClick={() => moveItem(i, -1)} />
                  <IconButton icon="down" label="Move down"
                    disabled={i === draft.items.length - 1}
                    onClick={() => moveItem(i, 1)} />
                </span>
              </div>
            ))}
            {addItemBtn}
            <Checkbox label="Shuffle for students"
              checked={draft.shuffle}
              onChange={(e) => set("shuffle", e.target.checked)} />
          </>
        )}

        <div className="td-actions" style={{ justifyContent: "flex-start" }}>
          <Button onClick={onSave} disabled={saving} loading={saving}>Save question</Button>
          <Button variant="outline" onClick={onCancel}>Cancel</Button>
        </div>
        {error != null && <p className="td-err">{errText(error)}</p>}
      </div>
    </Card>
  );
}

/** Editable draft of one part inside an activity. */
interface PartDraft {
  id?: string;
  title: string;
  directions: string;
  mode: ActivityMode;
  scored: boolean;
  points: number;
  position: number;
}

const emptyPartDraft = (pos: number): PartDraft => ({
  title: "", directions: "", mode: "multiple_choice", scored: true,
  points: 1, position: pos,
});

const toPartDraft = (p: AssessmentPart): PartDraft => ({
  id: p.id, title: p.title, directions: p.directions,
  mode: p.mode, scored: p.scored, points: p.points ?? 1, position: p.position,
});

/** Part editor: title + mode + points + scored switch + directions. */
function PartForm({ draft, onChange, onSave, onDelete, saving, error }: {
  draft: PartDraft; onChange: (d: PartDraft) => void; onSave: () => void;
  onDelete?: () => void; saving: boolean; error: unknown;
}) {
  const set = <K extends keyof PartDraft>(k: K, v: PartDraft[K]) =>
    onChange({ ...draft, [k]: v });
  return (
    <Card variant="white">
      <div className="td-stack">
        <div className="td-spread">
          <span className="ds-label">{draft.id ? "Part settings" : "New part"}</span>
          {onDelete && (
            <IconButton icon="delete" label="Delete part" onClick={onDelete} />
          )}
        </div>
        <TextField clean label="Part title" value={draft.title}
          placeholder="e.g. Activity 1 — Reaction Detective"
          onChange={(e) => set("title", e.target.value)} />
        <Select label="Quiz mode" value={draft.mode}
          onChange={(e) => set("mode", e.target.value as ActivityMode)}
          options={MODES.map((m) => ({
            value: m.value, label: m.supported ? m.label : `${m.label} (soon)`,
          }))} />
        {MODE_TO_QTYPE[draft.mode] == null && (
          <p className="ds-caption" style={{ color: "var(--ds-muted)", margin: 0 }}>
            “{modeLabel(draft.mode)}” isn't supported by the runner yet — items in this
            part default to Multiple Choice for now.
          </p>
        )}
        <Switch label="Scored"
          checked={draft.scored} onChange={(e) => set("scored", e.target.checked)} />
        {draft.scored && (
          <TextField label="Points per item" type="number" min={0} step="0.5"
            inputMode="decimal" value={Number.isNaN(draft.points) ? "" : draft.points}
            helper="Each item in this part is worth this many points."
            onChange={(e) => set("points",
              e.target.value === "" ? NaN : Math.max(0, numOr(e.target.value, 0)))} />
        )}
        <TextArea clean label="Directions" rows={2} value={draft.directions}
          placeholder="e.g. Read each situation carefully and select the correct answer."
          onChange={(e) => set("directions", e.target.value)} />
        <div className="td-actions" style={{ justifyContent: "flex-start" }}>
          <Button onClick={onSave} disabled={saving} loading={saving}>Save part</Button>
        </div>
        {error != null && <p className="td-err">{errText(error)}</p>}
      </div>
    </Card>
  );
}

/** Pointer-drag reorder: `start(i)` on the grip; hover tracked by row rects;
 *  commit(f,h) persists. Rows mark `data-drag-row` inside `listRef`. */
function useDragList(onCommit: (from: number, to: number) => void) {
  const [drag, setDrag] = useState<{ from: number; hover: number } | null>(null);
  const listRef = useRef<HTMLDivElement>(null);
  const start = (i: number) => (e: React.PointerEvent) => {
    e.preventDefault();
    setDrag({ from: i, hover: i });
    const onMove = (ev: PointerEvent) => {
      const rows = listRef.current?.querySelectorAll("[data-drag-row]");
      if (!rows) return;
      rows.forEach((row, idx) => {
        const r = row.getBoundingClientRect();
        if (ev.clientY >= r.top && ev.clientY <= r.bottom) {
          setDrag((d) => (d ? { ...d, hover: idx } : d));
        }
      });
    };
    const onUp = () => {
      window.removeEventListener("pointermove", onMove);
      window.removeEventListener("pointerup", onUp);
      setDrag((d) => {
        if (d && d.hover !== d.from) onCommit(d.from, d.hover);
        return null;
      });
    };
    window.addEventListener("pointermove", onMove);
    window.addEventListener("pointerup", onUp, { once: true });
  };
  return { drag, start, listRef };
}

export default function ActivityBuilder() {
  const { classId = "", assessmentId = "" } = useParams();
  const nav = useNavigate();
  const qc = useQueryClient();

  const assessment = useQuery({
    queryKey: ["assessment", assessmentId],
    queryFn: () => fetchAssessment(assessmentId),
  });
  const lesson = useQuery({
    queryKey: ["lesson", assessment.data?.lesson_id],
    queryFn: () => fetchLesson(assessment.data!.lesson_id!),
    enabled: assessment.data?.lesson_id != null,
  });
  const parts = useQuery({ queryKey: ["parts", assessmentId], queryFn: () => fetchParts(assessmentId) });
  const questions = useQuery({ queryKey: ["questions-full", assessmentId], queryFn: () => fetchQuestionsFull(assessmentId) });

  const [selPart, setSelPart] = useState<string | null>(null);
  const [partDraft, setPartDraft] = useState<PartDraft | null>(null);
  const [draft, setDraft] = useState<Draft | null>(null);
  const [delQ, setDelQ] = useState<Question | null>(null);
  const [delP, setDelP] = useState<AssessmentPart | null>(null);
  const [renameOpen, setRenameOpen] = useState(false);
  const [toast, setToast] = useState<string | null>(null);
  const [rTitle, setRTitle] = useState("");
  const [rDesc, setRDesc] = useState("");
  const [releaseConfirm, setReleaseConfirm] = useState(false);
  /** Pending mode switch — the part has questions, confirm wipes them. */
  const [modeChange, setModeChange] =
    useState<{ draft: PartDraft; count: number } | null>(null);
  const [modeDelErr, setModeDelErr] = useState<unknown>(null);

  const invalidate = () => {
    qc.invalidateQueries({ queryKey: ["assessment", assessmentId] });
    qc.invalidateQueries({ queryKey: ["parts", assessmentId] });
    qc.invalidateQueries({ queryKey: ["questions-full", assessmentId] });
    qc.invalidateQueries({ queryKey: ["lesson-assessments"] });
  };

  const a = assessment.data;
  const ps = parts.data ?? [];
  const qs = questions.data ?? [];
  const qCount = qs.length;

  const rename = useMutation({
    mutationFn: () => renameAssessment(assessmentId, { title: rTitle, description: rDesc }),
    onSuccess: () => { setRenameOpen(false); invalidate(); },
  });
  const pub = useMutation({
    mutationFn: (published: boolean) => setAssessmentPublished(assessmentId, published),
    onSuccess: invalidate,
    onError: invalidate,
  });
  const release = useMutation({
    mutationFn: (mode: "immediate" | "manual") => setScoreRelease(assessmentId, mode),
    onSuccess: invalidate,
  });
  const releaseNow = useMutation({
    mutationFn: () => releaseScores(assessmentId),
    onSuccess: () => { setReleaseConfirm(false); invalidate(); },
  });
  const save = useMutation({
    mutationFn: (d: Draft) => {
      const filled = d.choices.map((c) => c.trim());
      const selStored = [...new Set(
        d.sel.filter((i) => filled[i] !== "" && filled[i] != null)
             .map((i) => filled.slice(0, i).filter(Boolean).length)
      )].sort((x, y) => x - y);
      const itemTexts = d.items.map((c) => c.trim());
      const zonesStored = itemTexts
        .map((t, i) => (t !== "" ? (d.zones[i] ?? 0) : null))
        .filter((z): z is number => z != null);
      const ordItems = itemTexts.filter((t) => t !== "");
      const perm = ordItems.map((_, k) => k);
      for (let k = perm.length - 1; k > 0; k--) {
        const j = Math.floor(Math.random() * (k + 1));
        [perm[k], perm[j]] = [perm[j], perm[k]];
      }
      const ordChoices = perm.map((k) => ordItems[k]);
      const ordCorrect = ordItems.map((_, p) => perm.indexOf(p));
      const targetList = d.part_id
        ? qs.filter((x) => x.part_id === d.part_id && x.id !== d.id)
        : qs.filter((x) => x.part_id == null && x.id !== d.id);
      const pos = d.part_id === draft?.part_id && d.id != null
        ? d.position
        : targetList.length;
      return upsertQuestion({
        id: d.id, assessment_id: assessmentId, part_id: d.part_id,
        qtype: d.qtype, prompt: d.prompt.trim(),
        position: pos,
        choices: d.qtype === "ordering" ? ordChoices
          : d.qtype === "classification" ? itemTexts.filter(Boolean)
          : d.qtype === "multiple_choice" || d.qtype === "multi_select"
                    || d.qtype === "fill_blank"
          ? filled.filter(Boolean) : null,
        correct_index: d.qtype === "multiple_choice" || d.qtype === "fill_blank"
          ? filled.slice(0, d.correct).filter(Boolean).length
          : null,
        answer: d.qtype === "true_false" ? { correct: d.boolAnswer }
          : d.qtype === "identification"
            ? { accepted: d.accepted.map((x) => x.trim()).filter(Boolean) }
            : d.qtype === "enumeration"
              ? { items: d.items.map((i) => i.trim()).filter(Boolean), ordered: d.ordered, partial: d.partial }
              : d.qtype === "multi_select"
                ? { indexes: selStored, min: d.minSel, max: d.maxSel, partial: d.partial }
                : d.qtype === "classification"
                  ? { buckets: d.buckets.map((b) => b.trim()),
                      zones: zonesStored,
                      ...(d.context.trim() !== ""
                        ? { context: d.context.trim() } : {}) }
                  : d.qtype === "ordering"
                    ? { correct: ordCorrect, shuffle: d.shuffle }
                    : null,
      });
    },
    onSuccess: () => {
      setDraft(null);
      invalidate();
    },
  });
  const del = useMutation({ mutationFn: deleteQuestion, onSuccess: invalidate });
  const savePart = useMutation({
    mutationFn: async (p: PartDraft) => {
      const newId = await upsertPart({
        id: p.id, assessment_id: assessmentId, title: p.title.trim(),
        directions: p.directions.trim(), mode: p.mode, scored: p.scored,
        points: Number.isFinite(p.points) ? p.points : 1,
        position: p.position,
      });
      // Keep positions dense — heals gaps from older writes so a
      // later insert can never tie and sort first.
      const now = await fetchParts(assessmentId);
      await reorderPartPositions(now.map((x) => x.id));
      return newId;
    },
    onSuccess: (newId) => {
      invalidate();
      setSelPart(newId);
    },
  });
  const delPart = useMutation({
    mutationFn: async (id: string) => {
      await deletePart(id);
      // Close the gap so positions stay dense.
      const now = await fetchParts(assessmentId);
      await reorderPartPositions(now.map((x) => x.id));
    },
    onSuccess: invalidate,
  });
  const reorderQ = useMutation({
    mutationFn: reorderQuestionPositions, onSuccess: invalidate,
  });
  const reorderP = useMutation({
    mutationFn: reorderPartPositions, onSuccess: invalidate,
  });

  // Select the first part once parts load — but not while a "new part"
  // draft is open (selPart is null then on purpose).
  useEffect(() => {
    if (selPart == null && partDraft == null && ps.length > 0) {
      setSelPart(ps[0].id);
    }
  }, [ps, selPart, partDraft]);
  useEffect(() => {
    const p = ps.find((x) => x.id === selPart);
    // selPart === null is the "+ Add part" state — keep the new-part draft.
    if (p) setPartDraft(toPartDraft(p));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selPart]);

  const selQuestions = selPart
    ? qs.filter((q) => q.part_id === selPart)
    : qs.filter((q) => q.part_id == null);
  const ungrouped = qs.filter((q) => q.part_id == null);
  const bad = draft ? draftValid(draft) : null;
  const partBad = partDraft && !partDraft.title.trim() ? "Enter a part title." : null;

  /** Commit a question drag inside the selected scope. */
  const commitQDrag = (from: number, to: number) => {
    const next = moveInList(selQuestions.map((q) => q.id), from, to);
    reorderQ.mutate(next);
  };
  const qDrag = useDragList(commitQDrag);
  /** Commit a part drag in the outline. */
  const commitPDrag = (from: number, to: number) => {
    const next = moveInList(ps.map((p) => p.id), from, to);
    reorderP.mutate(next);
  };
  const pDrag = useDragList(commitPDrag);

  const moveQ = (q: Question, dir: -1 | 1) => {
    const ids = selQuestions.map((x) => x.id);
    const i = ids.indexOf(q.id);
    reorderQ.mutate(moveInList(ids, i, i + dir));
  };
  const moveP = (p: AssessmentPart, dir: -1 | 1) => {
    const ids = ps.map((x) => x.id);
    const i = ids.indexOf(p.id);
    reorderP.mutate(moveInList(ids, i, i + dir));
  };

  /** Editor opens for a new question — type comes from the part's mode. */
  const selMode: ActivityMode =
    ps.find((p) => p.id === selPart)?.mode ?? "multiple_choice";
  const openNew = () => {
    // Questions live inside parts — with none yet, nudge the teacher to
    // "+ Add part" instead of filing an ungrouped item.
    if (ps.length === 0) {
      setToast("Add a part first — questions live inside parts.");
      return;
    }
    setDraft(emptyDraft(selQuestions.length,
      MODE_TO_QTYPE[selMode] ?? "multiple_choice", selPart));
  };

  const partPoints = (pid: string | null) =>
    ps.find((p) => p.id === pid)?.points ?? 1;

  const releaseOpts = [
    { value: "immediate", label: "Instant scores" },
    { value: "manual", label: "Manual release" },
    ...(a?.release_scores === "manual" && !a.scores_released
      ? [{ value: "__now", label: "Release scores now" }] : []),
  ];

  /** One question row (or the inline editor when open). */
  const qRow = (q: Question, i: number, scope: Question[]) =>
    draft?.id === q.id ? (
      <QuestionForm key={q.id} draft={draft} parts={ps}
        number={i + 1} points={partPoints(q.part_id)}
        onChange={setDraft}
        saving={save.isPending} error={save.error}
        onSave={() => !bad && save.mutate(draft)} onCancel={() => setDraft(null)} />
    ) : (
      <div key={q.id} data-drag-row
        className={`td-qrow${qDrag.drag?.hover === i && qDrag.drag.from !== i ? " td-qrow-drop" : ""}`}>
        <button type="button" className="td-grip" aria-label="Drag to reorder"
          onPointerDown={qDrag.start(i)}>
          <Icon name="grip" size={18} />
        </button>
        <span className="td-num">{i + 1}</span>
        <Chip variant="pastel" pastelColor="blue">
          {QTYPES.find((t) => t.value === q.qtype)?.label ?? q.qtype.replace(/_/g, " ")}
        </Chip>
        <span className="td-qrow-main">
          <span className="td-qrow-prompt">{q.prompt}</span>
          <span className="td-qrow-hint">{answerHint(q)}</span>
        </span>
        <PopoverMenu label="Question actions" bare items={[
          { key: "edit", label: "Edit", icon: <Icon name="edit" size={16} />,
            onSelect: () => setDraft(toDraft(q)) },
          { key: "up", label: "Move up", icon: <Icon name="up" size={16} />,
            disabled: i === 0, onSelect: () => moveQ(q, -1) },
          { key: "down", label: "Move down", icon: <Icon name="down" size={16} />,
            disabled: i === scope.length - 1, onSelect: () => moveQ(q, 1) },
          { key: "del", label: "Delete", icon: <Icon name="delete" size={16} />,
            danger: true, onSelect: () => setDelQ(q) },
        ]} />
      </div>
    );

  if (assessment.isLoading) return <p className="ds-body">Loading activity…</p>;
  if (assessment.error) return <p className="td-err">{errText(assessment.error)}</p>;
  if (!a) return <p className="td-err">Activity not found.</p>;

  return (
    <div className="td-stack">
      {/* navy header card */}
      <div className="td-build-head">
        <Link to={`/teacher/c/${classId}/quiz`} className="td-build-back">
          <Icon name="back" size={18} /> Back
        </Link>
        <div className="td-build-title">
          <h2 className="td-build-h">{a.title}</h2>
          <IconButton icon="edit" label="Rename activity" className="td-build-pencil"
            onClick={() => {
              setRTitle(a.title); setRDesc(a.description); setRenameOpen(true);
            }} />
        </div>
        {lesson.data?.title && (
          <p className="td-build-sub">Lesson · {lesson.data.title}</p>
        )}
        {a.description !== "" && (
          <p className="td-build-sub">{a.description}</p>
        )}
        <div className="td-build-tools">
          <Button variant="outline" size="sm" leadingIcon="show"
            onClick={() => nav(`/teacher/c/${classId}/quiz/a/${assessmentId}/preview`)}>
            Preview
          </Button>
          <div className="td-build-release">
            <Select label="" value={a.release_scores}
              onChange={(e) => {
                const v = e.target.value;
                if (v === "__now") setReleaseConfirm(true);
                else release.mutate(v as "immediate" | "manual");
              }}
              options={releaseOpts} />
            {a.scores_released && <StatusBadge status="released" label="Scores released" />}
          </div>
          <span className="td-build-pub">
            <Switch tone="teal"
              checked={a.is_published}
              disabled={qCount === 0 || pub.isPending}
              onChange={(e) => pub.mutate(e.target.checked)} />
            {qCount === 0 && (
              <Chip variant="pastel" pastelColor="yellow">Add questions to publish</Chip>
            )}
          </span>
        </div>
        <div className="td-build-counts">
          <span className="ds-caption">
            {ps.length} {ps.length === 1 ? "part" : "parts"} · {qCount}{" "}
            {qCount === 1 ? "question" : "questions"}
          </span>
        </div>
      </div>

      {/* body: parts outline + editor column */}
      <div className="td-build-grid">
        <Card variant="white" className="td-outline">
          <span className="ds-label">Parts</span>
          <div ref={pDrag.listRef} className="td-outline-list">
            {ps.map((p, pi) => (
              <div key={p.id} data-drag-row
                className={`td-prow${selPart === p.id ? " on" : ""}${
                  pDrag.drag?.hover === pi && pDrag.drag.from !== pi ? " td-prow-drop" : ""}`}
                onClick={() => setSelPart(p.id)}>
                <button type="button" className="td-grip" aria-label="Drag to reorder"
                  onPointerDown={(e) => { e.stopPropagation(); pDrag.start(pi)(e); }}>
                  <Icon name="grip" size={16} />
                </button>
                <span className="td-prow-main">
                  <span className="td-prow-title">
                    {pi + 1}. {p.title || `Activity ${pi + 1}`}
                  </span>
                  <span className="td-prow-sub">
                    {modeLabel(p.mode)} · {qs.filter((q) => q.part_id === p.id).length} items
                  </span>
                </span>
                <PopoverMenu label="Part actions" items={[
                  { key: "up", label: "Move up", icon: <Icon name="up" size={16} />,
                    disabled: pi === 0, onSelect: () => moveP(p, -1) },
                  { key: "down", label: "Move down", icon: <Icon name="down" size={16} />,
                    disabled: pi === ps.length - 1, onSelect: () => moveP(p, 1) },
                  { key: "del", label: "Delete", icon: <Icon name="delete" size={16} />,
                    danger: true, onSelect: () => setDelP(p) },
                ]} />
              </div>
            ))}
            <button type="button" className="td-prow-add"
              onClick={() => { setSelPart(null); setPartDraft(emptyPartDraft(
                // max(position)+1 — deleting a part leaves gaps, and a
                // length-based slot can tie an existing position and sort
                // the new part first.
                ps.reduce((m, p) => Math.max(m, p.position ?? 0), -1) + 1,
              )); }}>
              <Icon name="add" size={16} /> Add part
            </button>
          </div>
        </Card>

        <div className="td-stack">
          {partDraft && (
            <PartForm draft={partDraft} onChange={setPartDraft}
              saving={savePart.isPending} error={savePart.error ?? modeDelErr}
              onSave={() => {
                if (partBad) return;
                // Mode drives the question type — if it changed and the
                // part already has questions, confirm the wipe first.
                const prev = partDraft.id
                  ? ps.find((p) => p.id === partDraft.id) : undefined;
                const n = prev
                  ? qs.filter((q) => q.part_id === prev.id).length : 0;
                if (prev && partDraft.mode !== prev.mode && n > 0) {
                  setModeDelErr(null);
                  setModeChange({ draft: partDraft, count: n });
                  return;
                }
                savePart.mutate(partDraft);
              }}
              onDelete={partDraft.id
                ? () => setDelP(ps.find((p) => p.id === partDraft.id) ?? null)
                : undefined} />
          )}
          {partBad && <p className="td-err">{partBad}</p>}

          <Card variant="white">
            <div className="td-spread">
              <span className="ds-label">
                Questions {selPart ? "" : "(ungrouped)"}
              </span>
              <span className="ds-caption" style={{ color: "var(--ds-muted)" }}>
                {selQuestions.length} items
              </span>
            </div>
            <div ref={qDrag.listRef} className="td-qlist">
              {selQuestions.map((q, i) => qRow(q, i, selQuestions))}
              {draft && !draft.id && (
                <QuestionForm draft={draft} parts={ps}
                  number={selQuestions.length + 1} points={partPoints(draft.part_id)}
                  onChange={setDraft}
                  saving={save.isPending} error={save.error}
                  onSave={() => !bad && save.mutate(draft)} onCancel={() => setDraft(null)} />
              )}
            </div>
            {bad && draft && <p className="td-err">{bad}</p>}
            <div className="td-addq">
              <Button leadingIcon="add" onClick={openNew}>Add question</Button>
              <span className="ds-caption" style={{ color: "var(--ds-muted)" }}>
                Type comes from the part's mode ({modeLabel(selMode)}).
              </span>
            </div>
          </Card>

          {ungrouped.length > 0 && selPart != null && (
            <Card variant="white">
              <p className="ds-caption" style={{ color: "var(--ds-muted)", margin: 0 }}>
                Ungrouped questions — pick a part inside each item's editor to file it.
              </p>
              <div className="td-qlist">
                {ungrouped.map((q, i) => qRow(q, i, ungrouped))}
              </div>
            </Card>
          )}
        </div>
      </div>

      {/* rename modal */}
      <Modal open={renameOpen} onClose={() => setRenameOpen(false)} title="Rename activity"
        actions={
          <>
            <Button variant="outline" onClick={() => setRenameOpen(false)}>Cancel</Button>
            <Button disabled={rename.isPending || !rTitle.trim()} loading={rename.isPending}
              onClick={() => rename.mutate()}>
              Save
            </Button>
          </>
        }>
        <div className="td-stack">
          <TextField clean label="Title" value={rTitle}
            onChange={(e) => setRTitle(e.target.value)} />
          <TextField clean label="Description" value={rDesc}
            placeholder="optional"
            onChange={(e) => setRDesc(e.target.value)} />
        </div>
        {rename.error != null && <p className="td-err">{errText(rename.error)}</p>}
      </Modal>

      {/* release-now confirm */}
      <Modal open={releaseConfirm} onClose={() => setReleaseConfirm(false)}
        title="Release scores now?"
        actions={
          <>
            <Button variant="outline" onClick={() => setReleaseConfirm(false)}>Cancel</Button>
            <Button loading={releaseNow.isPending} onClick={() => releaseNow.mutate()}>
              Release
            </Button>
          </>
        }>
        <p className="ds-body">
          Students who already took “{a.title}” will see their scores right away.
        </p>
        {releaseNow.error != null && <p className="td-err">{errText(releaseNow.error)}</p>}
      </Modal>

      {/* delete confirms */}
      <Modal open={delQ != null} onClose={() => setDelQ(null)} title="Delete question?"
        actions={
          <>
            <Button variant="ghost" onClick={() => setDelQ(null)}>Keep it</Button>
            <Button variant="danger" disabled={del.isPending}
              onClick={() => { del.mutate(delQ!.id); setDelQ(null); }}>
              Delete
            </Button>
          </>
        }>
        <p className="ds-body">“{delQ?.prompt.slice(0, 80)}”</p>
      </Modal>
      {/* mode-change confirm — wipes the part's existing questions */}
      <Modal open={modeChange != null} onClose={() => setModeChange(null)}
        title="Change mode?"
        actions={
          <>
            <Button variant="ghost" onClick={() => setModeChange(null)}>Keep it</Button>
            <Button variant="danger"
              onClick={async () => {
                const mc = modeChange!;
                setModeChange(null);
                try {
                  await Promise.all(
                    qs.filter((q) => q.part_id === mc.draft.id)
                      .map((q) => deleteQuestion(q.id)));
                  savePart.mutate(mc.draft);
                } catch (e) {
                  setModeDelErr(e);
                }
              }}>
              Change mode
            </Button>
          </>
        }>
        <p className="ds-body">
          Changing to “{modeChange ? modeLabel(modeChange.draft.mode) : ""}”
          removes the {modeChange?.count} question(s) already in this part.
        </p>
      </Modal>
      <Modal open={delP != null} onClose={() => setDelP(null)} title="Delete part?"
        actions={
          <>
            <Button variant="ghost" onClick={() => setDelP(null)}>Keep it</Button>
            <Button variant="danger" disabled={delPart.isPending}
              onClick={() => { delPart.mutate(delP!.id); setDelP(null); }}>
              Delete
            </Button>
          </>
        }>
        <p className="ds-body">
          This removes “{delP?.title || "this part"}” and its{" "}
          {qs.filter((q) => q.part_id === delP?.id).length} question(s).
        </p>
      </Modal>
      <Toast open={toast != null} message={toast ?? ""} tone="info"
        onClose={() => setToast(null)} />
    </div>
  );
}
