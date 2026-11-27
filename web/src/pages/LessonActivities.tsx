import { useRef, useState, type ReactNode } from "react";
import { Link, useParams } from "react-router-dom";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { fetchLesson } from "../services/learning";
import {
  createAssessment, deleteAssessment, deletePart, deleteQuestion, fetchLessonAssessments,
  fetchParts, fetchQuestionsFull, releaseScores, setAssessmentPublished, setScoreRelease,
  upsertPart, upsertQuestion,
} from "../services/activities";
import {
  Button, Card, Checkbox, Divider, EmptyState, Icon, IconButton,
  ListItemCard, Modal, Select, StatusBadge, TextArea, TextField,
} from "../design-system";
import type { ActivityMode, AssessmentPart, Question, QuestionType } from "../types";
import { fmtPts } from "../utils/stats";
import "./teacher.css";

/** Quiz modes offered when creating an activity. `supported` = the question
 *  editor and student runner can handle it today; others are marked "(soon)". */
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

/** Activity mode -> question type used as the editor default. */
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
  /** multi_select: indexes into `choices` the teacher ticked as correct. */
  sel: number[];
  minSel: number;
  maxSel: number;
  boolAnswer: boolean;
  accepted: string[];
  items: string[];
  ordered: boolean;
  partial: boolean;
  /** classification: the zone names + each item's correct zone index
   *  (parallel to `items`). `context` is the optional student-facing body. */
  buckets: string[];
  zones: number[];
  context: string;
  /** ordering: re-shuffle the shown order per open (default true). */
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
  // Legacy fill_blank (accepted-answer key) seeds its accepted items as
  // options with the first pre-ticked, so editing converts instead of losing it.
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
  // classification + ordering items live in `choices` (ordering's are
  // scrambled — `answer.correct` maps each position back); enumeration's
  // are in answer.items.
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

/** Dynamic list of short answers (choices / accepted / enumeration items). */
function ListInput({ items, label, removable, onChange }: {
  items: string[]; label: (i: number) => string; removable: boolean;
  onChange: (items: string[]) => void;
}) {
  return (
    <div className="td-stack">
      {items.map((v, i) => (
        <div key={i} className="td-row" style={{ flexWrap: "nowrap" }}>
          <div style={{ flex: 1 }}>
            <TextField clean label={label(i)} value={v}
              onChange={(e) => onChange(items.map((x, xi) => (xi === i ? e.target.value : x)))} />
          </div>
          {removable && (
            <IconButton icon="delete" label="Remove" style={{ alignSelf: "flex-end" }}
              onClick={() => onChange(items.filter((_, xi) => xi !== i))} />
          )}
        </div>
      ))}
    </div>
  );
}

function QuestionForm({ draft, onChange, onSave, onCancel, saving, error }: {
  draft: Draft; onChange: (d: Draft) => void;
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
    width: 18, height: 18, flex: "none" as const, marginTop: 26,
    accentColor: "var(--ds-blue)",
  };
  /** Option row shared by MC / multi_select / fill_blank: marker + field
   *  + move/delete buttons. */
  const choiceRow = (i: number, marker: ReactNode) => (
    <div key={i} className="td-row" style={{ flexWrap: "nowrap", alignItems: "center" }}>
      {marker}
      <div style={{ flex: 1 }}>
        <TextField clean label={`Choice ${i + 1}`} value={draft.choices[i]}
          onChange={(e) => set("choices",
            draft.choices.map((x, xi) => (xi === i ? e.target.value : x)))} />
      </div>
      <span className="td-actions" style={{ alignSelf: "flex-end" }}>
        <IconButton icon="up" label="Move up" disabled={i === 0}
          onClick={() => moveChoice(i, -1)} />
        <IconButton icon="down" label="Move down" disabled={i === draft.choices.length - 1}
          onClick={() => moveChoice(i, 1)} />
        <IconButton icon="delete" label="Remove" disabled={draft.choices.length <= 2}
          onClick={() => removeChoice(i)} />
      </span>
    </div>
  );
  const radioMark = (i: number) => (
    <input type="radio" name="correct" checked={draft.correct === i}
      onChange={() => set("correct", i)} style={markerStyle} />
  );
  const checkMark = (i: number) => (
    <input type="checkbox" checked={draft.sel.includes(i)}
      onChange={() => set("sel", draft.sel.includes(i)
        ? draft.sel.filter((x) => x !== i)
        : [...draft.sel, i])}
      style={markerStyle} />
  );
  const addChoiceBtn = (cap: number) => draft.choices.length < cap && (
    <div>
      <Button variant="outline" size="sm" leadingIcon="add" type="button"
        onClick={() => set("choices", [...draft.choices, ""])}>
        Add choice
      </Button>
    </div>
  );

  /** classification: `items`/`zones` stay parallel — move/remove/edit both. */
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
  /** Removing a zone drops its index and remaps every item's zone. */
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

  return (
    <Card variant="white">
      <div className="td-stack">
        <Select label="Question type" value={draft.qtype}
          onChange={(e) => set("qtype", e.target.value as QuestionType)}
          options={QTYPES.map((t) => ({ value: t.value, label: t.label }))} />
        <TextArea clean label="Prompt" rows={2} value={draft.prompt}
          ref={promptRef}
          onChange={(e) => set("prompt", e.target.value)} />

        {draft.qtype === "multiple_choice" && (
          <>
            <p className="ds-caption" style={{ margin: 0 }}>Choices — select the correct one:</p>
            {draft.choices.map((_, i) => choiceRow(i, radioMark(i)))}
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
            <p className="ds-caption" style={{ margin: 0 }}>Options — select the correct one:</p>
            {draft.choices.map((_, i) => choiceRow(i, radioMark(i)))}
            {addChoiceBtn(6)}
          </>
        )}
        {draft.qtype === "multi_select" && (
          <>
            <p className="ds-caption" style={{ margin: 0 }}>Choices — tick every correct one:</p>
            {draft.choices.map((_, i) => choiceRow(i, checkMark(i)))}
            {addChoiceBtn(8)}
            <p className="ds-caption" style={{ margin: 0 }}>Required selections</p>
            <div className="td-row">
              <div style={{ flex: 1 }}>
                <TextField clean label="Min" type="number" min={0} value={draft.minSel}
                  onChange={(e) => set("minSel", e.target.valueAsNumber)} />
              </div>
              <div style={{ flex: 1 }}>
                <TextField clean label="Max" type="number" min={1} value={draft.maxSel}
                  onChange={(e) => set("maxSel", e.target.valueAsNumber)} />
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
            <p className="ds-caption" style={{ margin: 0 }}>
              Accepted answers — matching ignores case and surrounding spaces:
            </p>
            <ListInput items={draft.accepted} label={(i) => `Answer ${i + 1}`}
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
            <p className="ds-caption" style={{ margin: 0 }}>Expected items:</p>
            <ListInput items={draft.items} label={(i) => `Item ${i + 1}`}
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
            <p className="ds-caption" style={{ margin: 0 }}>Zones</p>
            {draft.buckets.map((b, bi) => (
              <div key={bi} className="td-row" style={{ flexWrap: "nowrap" }}>
                <div style={{ flex: 1 }}>
                  <TextField clean label={`Zone ${bi + 1}`} value={b}
                    onChange={(e) => set("buckets",
                      draft.buckets.map((x, xi) => (xi === bi ? e.target.value : x)))} />
                </div>
                <IconButton icon="delete" label="Remove zone"
                  disabled={draft.buckets.length <= 2}
                  style={{ alignSelf: "flex-end" }}
                  onClick={() => removeZone(bi)} />
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
            <p className="ds-caption" style={{ margin: 0 }}>Items and their correct zone</p>
            {draft.items.map((item, i) => (
              <div key={i} className="td-row"
                style={{ flexWrap: "nowrap", alignItems: "flex-end" }}>
                <div style={{ flex: 1 }}>
                  <TextField clean label={`Item ${i + 1}`} value={item}
                    onChange={(e) => setItem(i, e.target.value)} />
                </div>
                <div className="ds-field" style={{ flex: 1 }}>
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
                <span className="td-actions">
                  <IconButton icon="up" label="Move up" disabled={i === 0}
                    onClick={() => moveItem(i, -1)} />
                  <IconButton icon="down" label="Move down"
                    disabled={i === draft.items.length - 1}
                    onClick={() => moveItem(i, 1)} />
                  <IconButton icon="delete" label="Remove"
                    disabled={draft.items.length <= 2}
                    onClick={() => removeItem(i)} />
                </span>
              </div>
            ))}
            {addItemBtn}
          </>
        )}
        {draft.qtype === "ordering" && (
          <>
            <p className="ds-caption" style={{ margin: 0 }}>
              Items — enter in the CORRECT order:
            </p>
            {draft.items.map((item, i) => (
              <div key={i} className="td-row"
                style={{ flexWrap: "nowrap", alignItems: "flex-end" }}>
                <span className="td-num">{i + 1}</span>
                <div style={{ flex: 1 }}>
                  <TextField clean label={`Item ${i + 1}`} value={item}
                    onChange={(e) => setItem(i, e.target.value)} />
                </div>
                <span className="td-actions">
                  <IconButton icon="up" label="Move up" disabled={i === 0}
                    onClick={() => moveItem(i, -1)} />
                  <IconButton icon="down" label="Move down"
                    disabled={i === draft.items.length - 1}
                    onClick={() => moveItem(i, 1)} />
                  <IconButton icon="delete" label="Remove"
                    disabled={draft.items.length <= 2}
                    onClick={() => removeItem(i)} />
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

/** Part editor: title + student-facing directions + quiz mode + scored toggle. */
function PartForm({ draft, onChange, onSave, onCancel, saving, error }: {
  draft: PartDraft; onChange: (d: PartDraft) => void; onSave: () => void;
  onCancel: () => void; saving: boolean; error: unknown;
}) {
  const set = <K extends keyof PartDraft>(k: K, v: PartDraft[K]) =>
    onChange({ ...draft, [k]: v });
  return (
    <Card variant="white">
      <div className="td-stack">
        <TextField clean label="Part title" value={draft.title}
          placeholder="e.g. Activity 1 — Reaction Detective"
          onChange={(e) => set("title", e.target.value)} />
        <TextArea clean label="Directions" rows={2} value={draft.directions}
          placeholder="e.g. Read each situation carefully and select the correct answer."
          onChange={(e) => set("directions", e.target.value)} />
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
        <Checkbox label="Scored — items in this part count toward the activity score"
          checked={draft.scored} onChange={(e) => set("scored", e.target.checked)} />
        {draft.scored && (
          <TextField label="Points per item" type="number" min={0} step="0.5"
            inputMode="decimal" value={Number.isNaN(draft.points) ? "" : draft.points}
            helper="Each item in this part is worth this many points."
            onChange={(e) => set("points", e.target.value === "" ? NaN : Math.max(0, parseFloat(e.target.value) || 0))} />
        )}
        <div className="td-actions" style={{ justifyContent: "flex-start" }}>
          <Button onClick={onSave} disabled={saving} loading={saving}>Save part</Button>
          <Button variant="outline" onClick={onCancel}>Cancel</Button>
        </div>
        {error != null && <p className="td-err">{errText(error)}</p>}
      </div>
    </Card>
  );
}

function AssessmentEditor({ assessmentId }: { assessmentId: string }) {
  const qc = useQueryClient();
  const parts = useQuery({ queryKey: ["parts", assessmentId], queryFn: () => fetchParts(assessmentId) });
  const questions = useQuery({ queryKey: ["questions-full", assessmentId], queryFn: () => fetchQuestionsFull(assessmentId) });
  const [draft, setDraft] = useState<Draft | null>(null);
  const [partDraft, setPartDraft] = useState<PartDraft | null>(null);
  const [delQ, setDelQ] = useState<Question | null>(null);
  const [delP, setDelP] = useState<AssessmentPart | null>(null);

  const invalidate = () => {
    qc.invalidateQueries({ queryKey: ["parts", assessmentId] });
    qc.invalidateQueries({ queryKey: ["questions-full", assessmentId] });
    qc.invalidateQueries({ queryKey: ["lesson-assessments"] });
  };

  const save = useMutation({
    mutationFn: (d: Draft) => {
      const filled = d.choices.map((c) => c.trim());
      // Draft sel indexes -> indexes over the saved (non-blank) choices.
      const selStored = [...new Set(
        d.sel.filter((i) => filled[i] !== "" && filled[i] != null)
             .map((i) => filled.slice(0, i).filter(Boolean).length)
      )].sort((a, b) => a - b);
      // classification: item texts -> choices; zones parallel to items ->
      // zones over the saved (non-blank) items.
      const itemTexts = d.items.map((c) => c.trim());
      const zonesStored = itemTexts
        .map((t, i) => (t !== "" ? (d.zones[i] ?? 0) : null))
        .filter((z): z is number => z != null);
      // ordering: scramble the stored choice order so the public list leaks
      // nothing; correct[p] = index of the choice at correct position p.
      const ordItems = itemTexts.filter((t) => t !== "");
      const perm = ordItems.map((_, k) => k);
      for (let k = perm.length - 1; k > 0; k--) {
        const j = Math.floor(Math.random() * (k + 1));
        [perm[k], perm[j]] = [perm[j], perm[k]];
      }
      const ordChoices = perm.map((k) => ordItems[k]);
      const ordCorrect = ordItems.map((_, p) => perm.indexOf(p));
      return upsertQuestion({
      id: d.id, assessment_id: assessmentId, part_id: d.part_id,
      qtype: d.qtype, prompt: d.prompt.trim(), position: d.position,
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
          ? { accepted: d.accepted.map((a) => a.trim()).filter(Boolean) }
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
  const del = useMutation({
    mutationFn: deleteQuestion,
    onSuccess: invalidate,
  });
  const savePart = useMutation({
    mutationFn: (p: PartDraft) => upsertPart({
      id: p.id, assessment_id: assessmentId, title: p.title.trim(),
      directions: p.directions.trim(), mode: p.mode, scored: p.scored,
      points: Number.isFinite(p.points) ? p.points : 1,
      position: p.position,
    }),
    onSuccess: () => {
      setPartDraft(null);
      invalidate();
    },
  });
  const delPart = useMutation({ mutationFn: deletePart, onSuccess: invalidate });

  const qs = questions.data ?? [];
  const ps = parts.data ?? [];
  const ungrouped = qs.filter((q) => q.part_id == null);
  const bad = draft ? draftValid(draft) : null;
  const partBad = partDraft && !partDraft.title.trim() ? "Enter a part title." : null;

  /** Question rows + "Add question" for one part (part=null → ungrouped). */
  const qList = (list: Question[], part: AssessmentPart | null) => (
    <>
      {list.map((q, i) =>
        draft?.id === q.id ? (
          <QuestionForm key={q.id} draft={draft} onChange={setDraft}
            saving={save.isPending} error={save.error}
            onSave={() => !bad && save.mutate(draft)} onCancel={() => setDraft(null)} />
        ) : (
          <ListItemCard key={q.id}
            leading={<span className="ds-label">{i + 1}</span>}
            title={q.prompt}
            subtitle={QTYPES.find((t) => t.value === q.qtype)?.label ?? q.qtype.replace(/_/g, " ")}
            trailing={
              <span className="td-row" style={{ flexWrap: "nowrap" }}>
                <IconButton icon="edit" label="Edit" onClick={() => setDraft(toDraft(q))} />
                <IconButton icon="delete" label="Delete" disabled={del.isPending}
                  onClick={() => setDelQ(q)} />
              </span>
            } />
        ),
      )}
      {draft && !draft.id && draft.part_id === (part?.id ?? null) ? (
        <QuestionForm draft={draft} onChange={setDraft}
          saving={save.isPending} error={save.error}
          onSave={() => !bad && save.mutate(draft)} onCancel={() => setDraft(null)} />
      ) : (
        <div>
          <Button variant="outline" size="sm" leadingIcon="add"
            onClick={() => setDraft(emptyDraft(
              list.length,
              MODE_TO_QTYPE[part?.mode ?? "multiple_choice"] ?? "multiple_choice",
              part?.id ?? null,
            ))}>
            Add item
          </Button>
        </div>
      )}
    </>
  );

  return (
    <div className="td-stack" style={{ marginTop: "var(--ds-s3)" }}>
      {questions.isLoading && <p className="ds-body">Loading questions…</p>}
      {questions.error && <p className="td-err">{errText(questions.error)}</p>}
      {ps.map((p, pi) => (
        <div key={p.id} className="td-stack">
          <div className="td-spread">
            <span>
              <strong>Activity {pi + 1}{p.title ? ` — ${p.title}` : ""}</strong>{" "}
              <span className="ds-caption" style={{ color: "var(--ds-muted)" }}>
                {modeLabel(p.mode)}{p.scored ? ` · ${fmtPts(p.points)} pt${p.points === 1 ? "" : "s"} each` : " · not scored"}
              </span>
            </span>
            <span className="td-actions">
              <IconButton icon="edit" label="Edit part"
                onClick={() => setPartDraft(toPartDraft(p))} />
              <IconButton icon="delete" label="Delete part" disabled={delPart.isPending}
                onClick={() => setDelP(p)} />
            </span>
          </div>
          {p.directions !== "" && (
            <p className="ds-caption" style={{ color: "var(--ds-muted)", margin: 0 }}>
              {p.directions}
            </p>
          )}
          {qList(qs.filter((q) => q.part_id === p.id), p)}
          <Divider />
        </div>
      ))}
      {ungrouped.length > 0 && (
        <>
          <p className="ds-caption" style={{ color: "var(--ds-muted)", margin: 0 }}>
            Ungrouped questions — pick a Part inside each item to file it.
          </p>
          {qList(ungrouped, null)}
        </>
      )}
      {partDraft ? (
        <PartForm draft={partDraft} onChange={setPartDraft}
          saving={savePart.isPending} error={savePart.error}
          onSave={() => !partBad && savePart.mutate(partDraft)}
          onCancel={() => setPartDraft(null)} />
      ) : (
        <div>
          <Button variant="outline" size="sm" leadingIcon="add"
            onClick={() => setPartDraft(emptyPartDraft(ps.length))}>
            Add part
          </Button>
        </div>
      )}
      {bad && draft && <p className="td-err">{bad}</p>}
      {partBad && partDraft && <p className="td-err">{partBad}</p>}
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
    </div>
  );
}

/** Assessment/quiz builder for one lesson — reused by the Activities page
 *  and by the class portal's Create Quiz tab (behind a lesson picker). */
export function ActivitiesBuilder({ lessonId }: { lessonId: string }) {
  const qc = useQueryClient();
  const assessments = useQuery({ queryKey: ["lesson-assessments", lessonId], queryFn: () => fetchLessonAssessments(lessonId) });
  const [open, setOpen] = useState<string | null>(null);
  const [title, setTitle] = useState("");
  const [desc, setDesc] = useState("");
  const [delA, setDelA] = useState<string | null>(null);

  const create = useMutation({
    mutationFn: () => createAssessment({
      lesson_id: lessonId, kind: "topic_quiz",
      title: title.trim(), description: desc.trim(),
    }),
    onSuccess: (a) => {
      setTitle(""); setDesc(""); setOpen(a.id);
      qc.invalidateQueries({ queryKey: ["lesson-assessments", lessonId] });
    },
  });
  const pub = useMutation({
    mutationFn: ({ id, published }: { id: string; published: boolean }) => setAssessmentPublished(id, published),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["lesson-assessments", lessonId] }),
  });
  const del = useMutation({
    mutationFn: deleteAssessment,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["lesson-assessments", lessonId] }),
  });
  const release = useMutation({
    mutationFn: ({ id, mode }: { id: string; mode?: "immediate" | "manual"; reveal?: boolean }) =>
      mode ? setScoreRelease(id, mode) : releaseScores(id),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["lesson-assessments", lessonId] }),
  });

  return (
    <div className="td-stack">
      <Card variant="white">
        <h3 className="ds-h3" style={{ marginTop: 0 }}>New activity</h3>
        <div className="td-row3 bento bento-sm">
          <TextField clean label="Title" value={title} onChange={(e) => setTitle(e.target.value)}
            placeholder="e.g. ELABORATE — Reaction Detective" />
          <TextField clean label="Description" value={desc} onChange={(e) => setDesc(e.target.value)}
            placeholder="optional" />
        </div>
        <Button disabled={create.isPending || !title.trim()} loading={create.isPending}
          onClick={() => create.mutate()}>
          Create activity
        </Button>
        {create.error != null && <p className="td-err">{errText(create.error)}</p>}
      </Card>

      {assessments.isLoading && <p className="ds-body">Loading activities…</p>}
      {assessments.error && <p className="td-err">{errText(assessments.error)}</p>}
      {assessments.data?.length === 0 && (
        <Card variant="white">
          <EmptyState icon="assessment" title="No activities yet"
            body="Create one above, then add questions." />
        </Card>
      )}
      {assessments.data?.map((a) => (
        <Card key={a.id} variant="white">
          <div className="td-spread">
            <span className="td-name">
              <strong>{a.title}</strong>
              <span className="ds-caption" style={{ color: "var(--ds-muted)" }}>
                {a.part_count ?? 0} {(a.part_count ?? 0) === 1 ? "part" : "parts"}
              </span>
              <StatusBadge status={a.is_published ? "published" : "draft"} />
            </span>
            <span className="td-actions">
              <Button variant="outline" size="sm" onClick={() => setOpen(open === a.id ? null : a.id)}>
                {open === a.id ? "Close" : "Questions"}
              </Button>
              <Button variant="outline" size="sm" disabled={pub.isPending}
                onClick={() => pub.mutate({ id: a.id, published: !a.is_published })}>
                {a.is_published ? "Unpublish" : "Publish"}
              </Button>
              <IconButton icon="delete" label="Delete" disabled={del.isPending}
                onClick={() => setDelA(a.id)} />
            </span>
          </div>
          <div className="td-release">
            {a.release_scores === "manual"
              ? (a.scores_released
                  ? <StatusBadge status="released" label="Scores released" />
                  : <StatusBadge status="hidden" label="Scores hidden" />)
              : <StatusBadge status="active" label="Instant scores" />}
            <Button variant="ghost" size="sm" disabled={release.isPending}
              onClick={() => release.mutate({
                id: a.id, mode: a.release_scores === "manual" ? "immediate" : "manual",
              })}>
              {a.release_scores === "manual" ? "Show after submit" : "Release manually"}
            </Button>
            {a.release_scores === "manual" && !a.scores_released && (
              <Button variant="primary" size="sm" disabled={release.isPending}
                onClick={() => release.mutate({ id: a.id })}>
                Release scores
              </Button>
            )}
          </div>
          {open === a.id && (
            <>
              <Divider />
              <AssessmentEditor assessmentId={a.id} />
            </>
          )}
        </Card>
      ))}

      <Modal open={delA != null} onClose={() => setDelA(null)} title="Delete activity?"
        actions={
          <>
            <Button variant="ghost" onClick={() => setDelA(null)}>Keep it</Button>
            <Button variant="danger" disabled={del.isPending}
              onClick={() => { del.mutate(delA!); setDelA(null); }}>
              Delete
            </Button>
          </>
        }>
        <p className="ds-body">This removes the activity and its questions.</p>
      </Modal>
    </div>
  );
}

/** Per-lesson activities page — a heading over the shared ActivitiesBuilder. */
export default function LessonActivities() {
  const { lessonId = "" } = useParams();
  const lesson = useQuery({ queryKey: ["lesson", lessonId], queryFn: () => fetchLesson(lessonId) });

  if (lesson.isLoading) return <p className="ds-body">Loading…</p>;
  if (lesson.error) return <p className="td-err">{errText(lesson.error)}</p>;

  return (
    <div className="td-stack">
      <div>
        <Link to={lesson.data?.class_id ? `/teacher/c/${lesson.data.class_id}/lessons` : "/teacher"} className="td-link">
          ← Back to lessons
        </Link>
        <h2 className="ds-h2" style={{ margin: "var(--ds-s3) 0 0" }}>Activities for “{lesson.data?.title}”</h2>
      </div>
      <ActivitiesBuilder lessonId={lessonId} />
    </div>
  );
}
