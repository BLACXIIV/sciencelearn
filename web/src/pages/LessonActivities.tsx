import { useState } from "react";
import { Link, useParams } from "react-router-dom";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { fetchLesson } from "../services/learning";
import {
  createAssessment, deleteAssessment, deleteQuestion, fetchLessonAssessments,
  fetchQuestionsFull, releaseScores, setAssessmentPublished, setScoreRelease, upsertQuestion,
} from "../services/activities";
import {
  Button, Card, Checkbox, Divider, EmptyState, Icon, IconButton,
  ListItemCard, Modal, SegmentedControl, Select, TextArea, TextField,
} from "../design-system";
import type { AssessmentKind, Question, QuestionType } from "../types";
import "./teacher.css";

const KINDS: { value: AssessmentKind; label: string }[] = [
  { value: "pre_test", label: "Pre-Test" },
  { value: "post_test", label: "Post-Test" },
  { value: "topic_quiz", label: "Topic Quiz" },
  { value: "problem_solving", label: "Problem Solving" },
  { value: "final_challenge", label: "Final Challenge" },
  { value: "practice", label: "Practice" },
];

const QTYPES: { value: QuestionType; label: string }[] = [
  { value: "multiple_choice", label: "Multiple Choice" },
  { value: "true_false", label: "True or False" },
  { value: "fill_blank", label: "Fill in the Blank" },
  { value: "identification", label: "Identification" },
  { value: "enumeration", label: "Enumeration" },
];

/** Editable draft of one question, in form-friendly shape. */
interface Draft {
  id?: string;
  qtype: QuestionType;
  prompt: string;
  position: number;
  choices: string[];
  correct: number;
  boolAnswer: boolean;
  accepted: string[];
  items: string[];
  ordered: boolean;
  partial: boolean;
}

const emptyDraft = (pos: number): Draft => ({
  qtype: "multiple_choice", prompt: "", position: pos,
  choices: ["", "", "", ""], correct: 0, boolAnswer: true,
  accepted: [""], items: ["", "", ""], ordered: false, partial: true,
});

const toDraft = (q: Question): Draft => ({
  id: q.id, qtype: q.qtype, prompt: q.prompt, position: q.position,
  choices: q.choices ?? ["", "", "", ""],
  correct: q.correct_index ?? 0,
  boolAnswer: q.answer?.correct ?? true,
  accepted: q.answer?.accepted ?? [""],
  items: q.answer?.items ?? ["", "", ""],
  ordered: q.answer?.ordered ?? false,
  partial: q.answer?.partial ?? true,
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
    case "fill_blank":
    case "identification":
      return d.accepted.some((a) => a.trim()) ? null : "Add at least one accepted answer.";
    case "enumeration":
      return d.items.filter((i) => i.trim()).length >= 2 ? null : "Add at least two expected items.";
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
            <TextField label={label(i)} value={v}
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
  draft: Draft; onChange: (d: Draft) => void; onSave: () => void; onCancel: () => void;
  saving: boolean; error: unknown;
}) {
  const set = <K extends keyof Draft>(k: K, v: Draft[K]) => onChange({ ...draft, [k]: v });

  return (
    <Card variant="white">
      <div className="td-stack">
        <Select label="Question type" value={draft.qtype}
          onChange={(e) => set("qtype", e.target.value as QuestionType)}
          options={QTYPES.map((t) => ({ value: t.value, label: t.label }))} />
        <TextArea label="Prompt" rows={2} value={draft.prompt}
          onChange={(e) => set("prompt", e.target.value)} />

        {draft.qtype === "multiple_choice" && (
          <>
            <p className="ds-caption" style={{ margin: 0 }}>Choices — pick the correct one:</p>
            <ListInput items={draft.choices} label={(i) => `Choice ${i + 1}`}
              removable={draft.choices.length > 2}
              onChange={(v) => set("choices", v)} />
            <Select label="Correct choice" value={String(draft.correct)}
              onChange={(e) => set("correct", Number(e.target.value))}
              options={draft.choices.map((c, i) => ({
                value: String(i), label: `Choice ${i + 1}${c.trim() ? ` — ${c.trim().slice(0, 24)}` : ""}`,
              }))} />
            {draft.choices.length < 6 && (
              <div>
                <Button variant="outline" size="sm" leadingIcon="add" type="button"
                  onClick={() => set("choices", [...draft.choices, ""])}>
                  Add choice
                </Button>
              </div>
            )}
          </>
        )}
        {draft.qtype === "true_false" && (
          <SegmentedControl ariaLabel="Correct answer"
            options={[{ value: "true", label: "True" }, { value: "false", label: "False" }]}
            value={draft.boolAnswer ? "true" : "false"}
            onChange={(v) => set("boolAnswer", v === "true")} />
        )}
        {(draft.qtype === "fill_blank" || draft.qtype === "identification") && (
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

        <div className="td-actions" style={{ justifyContent: "flex-start" }}>
          <Button onClick={onSave} disabled={saving} loading={saving}>Save question</Button>
          <Button variant="outline" onClick={onCancel}>Cancel</Button>
        </div>
        {error != null && <p className="td-err">{String(error)}</p>}
      </div>
    </Card>
  );
}

function AssessmentEditor({ assessmentId }: { assessmentId: string }) {
  const qc = useQueryClient();
  const questions = useQuery({ queryKey: ["questions-full", assessmentId], queryFn: () => fetchQuestionsFull(assessmentId) });
  const [draft, setDraft] = useState<Draft | null>(null);
  const [delQ, setDelQ] = useState<Question | null>(null);

  const save = useMutation({
    mutationFn: (d: Draft) => {
      const filled = d.choices.map((c) => c.trim());
      return upsertQuestion({
      id: d.id, assessment_id: assessmentId, qtype: d.qtype, prompt: d.prompt.trim(), position: d.position,
      choices: d.qtype === "multiple_choice" ? filled.filter(Boolean) : null,
      correct_index: d.qtype === "multiple_choice"
        ? filled.slice(0, d.correct).filter(Boolean).length
        : null,
      answer: d.qtype === "true_false" ? { correct: d.boolAnswer }
        : d.qtype === "fill_blank" || d.qtype === "identification"
          ? { accepted: d.accepted.map((a) => a.trim()).filter(Boolean) }
          : d.qtype === "enumeration"
            ? { items: d.items.map((i) => i.trim()).filter(Boolean), ordered: d.ordered, partial: d.partial }
            : null,
      });
    },
    onSuccess: () => {
      setDraft(null);
      qc.invalidateQueries({ queryKey: ["questions-full", assessmentId] });
    },
  });
  const del = useMutation({
    mutationFn: deleteQuestion,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["questions-full", assessmentId] }),
  });

  const qs = questions.data ?? [];
  const bad = draft ? draftValid(draft) : null;

  return (
    <div className="td-stack" style={{ marginTop: "var(--ds-s3)" }}>
      {questions.isLoading && <p className="ds-body">Loading questions…</p>}
      {questions.error && <p className="td-err">{String(questions.error)}</p>}
      {qs.map((q, i) =>
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
      {draft && !draft.id ? (
        <QuestionForm draft={draft} onChange={setDraft} saving={save.isPending} error={save.error}
          onSave={() => !bad && save.mutate(draft)} onCancel={() => setDraft(null)} />
      ) : (
        <div>
          <Button variant="outline" size="sm" leadingIcon="add"
            onClick={() => setDraft(emptyDraft(qs.length))}>
            Add question
          </Button>
        </div>
      )}
      {bad && draft && <p className="td-err">{bad}</p>}
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
    </div>
  );
}

/** Assessment/quiz builder for one lesson — reused by the Activities page
 *  and by the class portal's Create Quiz tab (behind a lesson picker). */
export function ActivitiesBuilder({ lessonId }: { lessonId: string }) {
  const qc = useQueryClient();
  const assessments = useQuery({ queryKey: ["lesson-assessments", lessonId], queryFn: () => fetchLessonAssessments(lessonId) });
  const [open, setOpen] = useState<string | null>(null);
  const [kind, setKind] = useState<AssessmentKind>("topic_quiz");
  const [title, setTitle] = useState("");
  const [desc, setDesc] = useState("");
  const [delA, setDelA] = useState<string | null>(null);

  const create = useMutation({
    mutationFn: () => createAssessment({ lesson_id: lessonId, kind, title: title.trim(), description: desc.trim() }),
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
        <div className="td-row3">
          <Select label="Type" value={kind}
            onChange={(e) => setKind(e.target.value as AssessmentKind)}
            options={KINDS.map((k) => ({ value: k.value, label: k.label }))} />
          <TextField label="Title" value={title} onChange={(e) => setTitle(e.target.value)}
            placeholder="e.g. Volcanoes Quiz 1" />
          <TextField label="Description" value={desc} onChange={(e) => setDesc(e.target.value)}
            placeholder="optional" />
        </div>
        <Button disabled={create.isPending || !title.trim()} loading={create.isPending}
          onClick={() => create.mutate()}>
          Create activity
        </Button>
        {create.error != null && <p className="td-err">{String(create.error)}</p>}
      </Card>

      {assessments.isLoading && <p className="ds-body">Loading activities…</p>}
      {assessments.error && <p className="td-err">{String(assessments.error)}</p>}
      {assessments.data?.length === 0 && (
        <Card variant="white">
          <EmptyState icon="assessment" title="No activities yet"
            body="Create one above, then add questions." />
        </Card>
      )}
      {assessments.data?.map((a) => (
        <Card key={a.id} variant="white">
          <div className="td-spread">
            <span>
              <strong>{a.title}</strong>{" "}
              <span className="ds-caption" style={{ color: "var(--ds-muted)" }}>
                {KINDS.find((k) => k.value === a.kind)?.label}
                {a.is_published ? " · published" : " · draft"}
              </span>
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
            <Icon name="award" size={14} />
            <span className="ds-caption">
              {a.release_scores === "manual"
                ? (a.scores_released ? "Scores released" : "Scores hidden until you release them")
                : "Students see scores right after submitting"}
            </span>
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
  if (lesson.error) return <p className="td-err">{String(lesson.error)}</p>;

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
