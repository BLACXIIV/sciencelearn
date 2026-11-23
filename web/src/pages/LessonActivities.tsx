import { useState } from "react";
import { Link, useParams } from "react-router-dom";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { fetchLesson } from "../services/learning";
import {
  createAssessment, deleteAssessment, deleteQuestion, fetchLessonAssessments,
  fetchQuestionsFull, setAssessmentPublished, upsertQuestion,
} from "../services/activities";
import { I } from "../components/icons";
import type { AssessmentKind, Question, QuestionType } from "../types";

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

function QuestionForm({ draft, onChange, onSave, onCancel, saving, error }: {
  draft: Draft; onChange: (d: Draft) => void; onSave: () => void; onCancel: () => void;
  saving: boolean; error: unknown;
}) {
  const set = <K extends keyof Draft>(k: K, v: Draft[K]) => onChange({ ...draft, [k]: v });
  const listRow = (key: "choices" | "accepted" | "items", i: number, label: string, removable: boolean) => (
    <div key={i} className="list-input-row">
      <input className="text-answer" placeholder={label} value={draft[key][i]}
        onChange={(e) => set(key, draft[key].map((x, xi) => (xi === i ? e.target.value : x)))} />
      {key === "choices" && (
        <label className="correct-mark" title="Correct choice">
          <input type="radio" name="correct" checked={draft.correct === i}
            onChange={() => set("correct", i)} /> correct
        </label>
      )}
      {removable && (
        <button type="button" className="icon-btn" title="Remove"
          onClick={() => set(key, draft[key].filter((_, xi) => xi !== i))}>
          <I name="delete" size={15} />
        </button>
      )}
    </div>
  );

  return (
    <div className="card q-editor">
      <label className="field"><span>Question type</span>
        <select value={draft.qtype} onChange={(e) => set("qtype", e.target.value as QuestionType)}>
          {QTYPES.map((t) => <option key={t.value} value={t.value}>{t.label}</option>)}
        </select>
      </label>
      <label className="field"><span>Prompt</span>
        <textarea rows={2} value={draft.prompt} onChange={(e) => set("prompt", e.target.value)} />
      </label>

      {draft.qtype === "multiple_choice" && (
        <>
          <p className="empty-sm" style={{ textAlign: "left" }}>Choices — mark the correct one:</p>
          {draft.choices.map((_, i) => listRow("choices", i, `Choice ${i + 1}`, draft.choices.length > 2))}
          {draft.choices.length < 6 && (
            <button type="button" className="secondary" onClick={() => set("choices", [...draft.choices, ""])}>
              <I name="add" size={14} /> Add choice
            </button>
          )}
        </>
      )}
      {draft.qtype === "true_false" && (
        <div className="tf-row">
          {[true, false].map((v) => (
            <label key={String(v)} className="choice">
              <input type="radio" checked={draft.boolAnswer === v} onChange={() => set("boolAnswer", v)} />
              {v ? "True" : "False"} is correct
            </label>
          ))}
        </div>
      )}
      {(draft.qtype === "fill_blank" || draft.qtype === "identification") && (
        <>
          <p className="empty-sm" style={{ textAlign: "left" }}>
            Accepted answers — matching ignores case and surrounding spaces:
          </p>
          {draft.accepted.map((_, i) => listRow("accepted", i, `Answer ${i + 1}`, draft.accepted.length > 1))}
          <button type="button" className="secondary" onClick={() => set("accepted", [...draft.accepted, ""])}>
            <I name="add" size={14} /> Add accepted answer
          </button>
        </>
      )}
      {draft.qtype === "enumeration" && (
        <>
          <p className="empty-sm" style={{ textAlign: "left" }}>Expected items:</p>
          {draft.items.map((_, i) => listRow("items", i, `Item ${i + 1}`, draft.items.length > 2))}
          <button type="button" className="secondary" onClick={() => set("items", [...draft.items, ""])}>
            <I name="add" size={14} /> Add item
          </button>
          <label className="choice" style={{ marginTop: 10 }}>
            <input type="checkbox" checked={draft.ordered} onChange={(e) => set("ordered", e.target.checked)} />
            Order matters — items must appear in this order
          </label>
          <label className="choice">
            <input type="checkbox" checked={draft.partial} onChange={(e) => set("partial", e.target.checked)} />
            Partial credit — score each correct item, otherwise all-or-nothing
          </label>
        </>
      )}

      <div className="row-actions">
        <button onClick={onSave} disabled={saving}>{saving ? "Saving…" : "Save question"}</button>
        <button className="secondary" onClick={onCancel}>Cancel</button>
      </div>
      {error != null && <p className="err">{String(error)}</p>}
    </div>
  );
}

function AssessmentEditor({ assessmentId }: { assessmentId: string }) {
  const qc = useQueryClient();
  const questions = useQuery({ queryKey: ["questions-full", assessmentId], queryFn: () => fetchQuestionsFull(assessmentId) });
  const [draft, setDraft] = useState<Draft | null>(null);

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
    <div className="q-list">
      {questions.isLoading && <p className="empty">Loading questions…</p>}
      {questions.error && <p className="err">{String(questions.error)}</p>}
      {qs.map((q, i) =>
        draft?.id === q.id ? (
          <QuestionForm key={q.id} draft={draft} onChange={setDraft}
            saving={save.isPending} error={save.error}
            onSave={() => !bad && save.mutate(draft)} onCancel={() => setDraft(null)} />
        ) : (
          <div key={q.id} className="q-row">
            <span className="q-num">{i + 1}</span>
            <span className="q-body">
              <strong>{q.prompt}</strong>
              <small className="q-kind">{q.qtype.replace(/_/g, " ")}</small>
            </span>
            <button className="icon-btn" title="Edit" onClick={() => setDraft(toDraft(q))}><I name="edit" size={15} /></button>
            <button className="icon-btn" title="Delete" disabled={del.isPending} onClick={() => del.mutate(q.id)}>
              <I name="delete" size={15} />
            </button>
          </div>
        ),
      )}
      {draft && !draft.id ? (
        <QuestionForm draft={draft} onChange={setDraft} saving={save.isPending} error={save.error}
          onSave={() => !bad && save.mutate(draft)} onCancel={() => setDraft(null)} />
      ) : (
        <button className="secondary" onClick={() => setDraft(emptyDraft(qs.length))}>
          <I name="add" size={15} /> Add question
        </button>
      )}
      {bad && draft && <p className="err">{bad}</p>}
    </div>
  );
}

export default function LessonActivities() {
  const { lessonId = "" } = useParams();
  const qc = useQueryClient();
  const lesson = useQuery({ queryKey: ["lesson", lessonId], queryFn: () => fetchLesson(lessonId) });
  const assessments = useQuery({ queryKey: ["lesson-assessments", lessonId], queryFn: () => fetchLessonAssessments(lessonId) });
  const [open, setOpen] = useState<string | null>(null);
  const [kind, setKind] = useState<AssessmentKind>("topic_quiz");
  const [title, setTitle] = useState("");
  const [desc, setDesc] = useState("");

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

  if (lesson.isLoading) return <p>Loading…</p>;
  if (lesson.error) return <p className="err">{String(lesson.error)}</p>;

  return (
    <>
      <Link to="/teacher/lessons" className="link-btn">← Back to lessons</Link>
      <h2>Activities for “{lesson.data?.title}”</h2>

      <div className="card">
        <h3>New activity</h3>
        <div className="row-3">
          <label className="field"><span>Type</span>
            <select value={kind} onChange={(e) => setKind(e.target.value as AssessmentKind)}>
              {KINDS.map((k) => <option key={k.value} value={k.value}>{k.label}</option>)}
            </select>
          </label>
          <label className="field"><span>Title</span>
            <input value={title} onChange={(e) => setTitle(e.target.value)} placeholder="e.g. Volcanoes Quiz 1" />
          </label>
          <label className="field"><span>Description</span>
            <input value={desc} onChange={(e) => setDesc(e.target.value)} placeholder="optional" />
          </label>
        </div>
        <button disabled={create.isPending || !title.trim()} onClick={() => create.mutate()}>
          {create.isPending ? "Creating…" : "Create activity"}
        </button>
        {create.error != null && <p className="err">{String(create.error)}</p>}
      </div>

      {assessments.isLoading && <p className="empty">Loading activities…</p>}
      {assessments.error && <p className="err">{String(assessments.error)}</p>}
      {assessments.data?.length === 0 && (
        <div className="card"><p className="empty">No activities yet. Create one above, then add questions.</p></div>
      )}
      {assessments.data?.map((a) => (
        <div key={a.id} className="card">
          <div className="perf">
            <span><strong>{a.title}</strong> <small className="kind">{KINDS.find((k) => k.value === a.kind)?.label}</small></span>
            <button className="secondary" onClick={() => setOpen(open === a.id ? null : a.id)}>
              {open === a.id ? "Close" : "Questions"}
            </button>
            <button className="secondary" disabled={pub.isPending}
              onClick={() => pub.mutate({ id: a.id, published: !a.is_published })}>
              {a.is_published ? "Unpublish" : "Publish"}
            </button>
            <button className="icon-btn" title="Delete" disabled={del.isPending} onClick={() => del.mutate(a.id)}>
              <I name="delete" size={15} />
            </button>
          </div>
          {open === a.id && <AssessmentEditor assessmentId={a.id} />}
        </div>
      ))}
    </>
  );
}
