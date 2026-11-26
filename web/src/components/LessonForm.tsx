import { FormEvent, useState } from "react";
import {
  Button, FileDropZone, Icon, IconButton, Modal, SearchField, TextArea,
  TextField, type IconName,
} from "../design-system";
import { SUBJECTS, type Lesson, type NewLessonInput, type Subject } from "../types";

interface Props {
  /** When set, the panel edits this lesson (prefilled fields, "Save changes"). */
  lesson?: Lesson | null;
  /** Must reject on failure so the form keeps its state. */
  onSubmit: (input: NewLessonInput) => Promise<unknown>;
  pending: boolean;
  error: unknown;
  /** Current subject list (built-ins + teacher customs); owned by the page. */
  subjects: string[];
  onAddSubject: (name: string) => void;
  onRemoveSubject: (name: string) => void;
}

const SUBJECT_ICON: Record<string, IconName> = {
  Physics: "atom",
  Chemistry: "science",
  "Earth Science": "globe",
};
const subjectIcon = (s: string): IconName => SUBJECT_ICON[s] ?? "lessons";

/** New/edit lesson panel (372px right rail). Owns its field state; clears
 *  only after a successful submit. Parent remounts via key to switch
 *  between create and edit targets. */
export default function LessonForm({
  lesson, onSubmit, pending, error,
  subjects, onAddSubject, onRemoveSubject,
}: Props) {
  const [title, setTitle] = useState(lesson?.title ?? "");
  const [subject, setSubject] = useState<Subject>(lesson?.subject ?? subjects[0] ?? "Physics");
  const [objectives, setObjectives] = useState(lesson?.objectives ?? "");
  const [thumb, setThumb] = useState<File | null>(null);
  const [material, setMaterial] = useState<File | null>(null);
  const [subjQ, setSubjQ] = useState("");
  const [addOpen, setAddOpen] = useState(false);
  const [newSubj, setNewSubj] = useState("");
  const [rmSubj, setRmSubj] = useState<string | null>(null);
  const editing = lesson != null;

  function remove(s: string) {
    onRemoveSubject(s);
    if (subject === s) setSubject(subjects.filter((x) => x !== s)[0] ?? "");
  }

  async function onFormSubmit(e: FormEvent) {
    e.preventDefault();
    try {
      await onSubmit({ title, subject, objectives, thumbnail: thumb, material });
      if (!editing) {
        setTitle(""); setObjectives(""); setThumb(null); setMaterial(null);
      }
    } catch {
      // failure is surfaced through the error prop; keep entered values
    }
  }

  return (
    <div className="tl-panel-card">
      <div className="tl-form-head">
        <h3 className="ds-h3" style={{ margin: 0 }}>
          {editing ? "Edit lesson" : "New lesson"}
        </h3>
      </div>
      <p className="tl-form-sub">
        {editing
          ? "Update the details — files only replace if you pick new ones."
          : "Lessons start as drafts — publish when students should see them."}
      </p>
      <form className="td-stack" onSubmit={onFormSubmit}>
        <TextField label="Title" value={title} onChange={(e) => setTitle(e.target.value)} required />
        <fieldset className="tl-subjects">
          <legend className="tl-subjects-leg">Subject</legend>
          <SearchField label="Search subject" placeholder="Type to filter"
            value={subjQ} onChange={(e) => setSubjQ(e.target.value)}
            className="tl-subj-search" />
          <div className="tl-subject-row" role="radiogroup" aria-label="Subject">
            {subjects
              .filter((s) =>
                s.toLowerCase().includes(subjQ.trim().toLowerCase()))
              .map((s) => (
                <button
                  key={s}
                  type="button"
                  role="radio"
                  aria-checked={subject === s}
                  className={`tl-subject${subject === s ? " on" : ""}`}
                  onClick={() => setSubject(s)}
                >
                  <span className="tl-subject-ic"><Icon name={subjectIcon(s)} size={22} /></span>
                  <span className="tl-subject-name">{s}</span>
                </button>
              ))}
            <button type="button" className="tl-subject tl-subject-add"
              aria-label="Add subject" onClick={() => setAddOpen(true)}>
              <span className="tl-subject-ic"><Icon name="add" size={22} /></span>
              <span className="tl-subject-name">Subject</span>
            </button>
          </div>
        </fieldset>
        <TextArea label="Objectives" value={objectives} onChange={(e) => setObjectives(e.target.value)} />
        <div className="tl-drops">
          <FileDropZone key={thumb ? `${thumb.name}${thumb.size}` : "t"} icon="camera"
            label="Thumbnail" hint="Drop an image or browse" accept="image/*"
            file={thumb} onChange={setThumb} />
          <FileDropZone key={material ? `${material.name}${material.size}` : "m"} icon="inbox"
            label="Material" hint="Drop a PDF or video or browse"
            file={material} onChange={setMaterial} />
        </div>
        <div className="tl-form-btns">
          <Button type="submit" leadingIcon={editing ? "check" : "add"}
            disabled={pending} loading={pending}>
            {editing ? "Save changes" : "Create lesson"}
          </Button>
        </div>
        {Boolean(error) && <p className="td-err">{String(error)}</p>}
      </form>
      <Modal
        open={addOpen}
        onClose={() => setAddOpen(false)}
        title="Add subject"
      >
        <div className="tl-add-subj">
          <TextField label="Subject name" value={newSubj}
            onChange={(e) => setNewSubj(e.target.value)} />
          <div className="tl-subject-grid" aria-label="Subjects">
            {subjects.map((s) => (
                <button key={s} type="button"
                  className="tl-subject tl-subject-del"
                  aria-label={`Remove ${s}`} onClick={() => setRmSubj(s)}>
                  <span className="tl-subject-ic"><Icon name={subjectIcon(s)} size={22} /></span>
                  <span className="tl-subject-name">{s}</span>
                  <span className="tl-subject-x"><Icon name="close" size={14} /></span>
                </button>
              ))}
          </div>
          <Button type="button"
            disabled={!newSubj.trim()}
            onClick={() => { onAddSubject(newSubj); setNewSubj(""); }}>
            Save
          </Button>
        </div>
      </Modal>
      <Modal
        open={rmSubj != null}
        onClose={() => setRmSubj(null)}
        title="Remove this subject?"
        actions={
          <>
            <Button variant="outline" onClick={() => setRmSubj(null)}>Cancel</Button>
            <Button variant="danger"
              onClick={() => { if (rmSubj) remove(rmSubj); setRmSubj(null); }}>
              Remove
            </Button>
          </>
        }
      >
        <p className="tl-dim">“{rmSubj}” will be removed from the subject
          picker. Lessons already tagged with it keep their subject.</p>
      </Modal>
    </div>
  );
}
