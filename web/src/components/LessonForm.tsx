import { FormEvent, useState } from "react";
import { Button, Card, Select, TextArea, TextField } from "../design-system";
import { SUBJECTS, type NewLessonInput, type Subject } from "../types";

interface Props {
  /** Creates the lesson; must reject on failure so the form keeps its state. */
  onCreate: (input: NewLessonInput) => Promise<unknown>;
  pending: boolean;
  error: unknown;
}

/** New-lesson form. Owns its field state; clears only after a successful create. */
export default function LessonForm({ onCreate, pending, error }: Props) {
  const [title, setTitle] = useState("");
  const [subject, setSubject] = useState<Subject>("Physics");
  const [objectives, setObjectives] = useState("");
  const [thumb, setThumb] = useState<File | null>(null);
  const [material, setMaterial] = useState<File | null>(null);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    try {
      await onCreate({ title, subject, objectives, thumbnail: thumb, material });
      setTitle(""); setObjectives(""); setThumb(null); setMaterial(null);
    } catch {
      // failure is surfaced through the error prop; keep entered values
    }
  }

  return (
    <Card variant="white">
      <h3 className="ds-h3" style={{ marginTop: 0 }}>New lesson</h3>
      <form className="td-stack" onSubmit={onSubmit}>
        <TextField label="Title" value={title} onChange={(e) => setTitle(e.target.value)} required />
        <Select label="Subject" value={subject}
          onChange={(e) => setSubject(e.target.value as Subject)}
          options={SUBJECTS.map((s) => ({ value: s, label: s }))} />
        <TextArea label="Objectives" value={objectives} onChange={(e) => setObjectives(e.target.value)} />
        <div className="td-row3">
          <label className="td-field">
            <span className="ds-caption">Thumbnail</span>
            <input type="file" accept="image/*" onChange={(e) => setThumb(e.target.files?.[0] ?? null)} />
          </label>
          <label className="td-field">
            <span className="ds-caption">Material (PDF/video)</span>
            <input type="file" onChange={(e) => setMaterial(e.target.files?.[0] ?? null)} />
          </label>
        </div>
        <div>
          <Button type="submit" disabled={pending} loading={pending}>
            Create lesson
          </Button>
        </div>
        {Boolean(error) && <p className="td-err">{String(error)}</p>}
      </form>
    </Card>
  );
}
