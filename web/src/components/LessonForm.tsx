import { FormEvent, useState } from "react";
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
    <form className="card form" onSubmit={onSubmit}>
      <h3>New lesson</h3>
      <input placeholder="Title" value={title} onChange={(e) => setTitle(e.target.value)} required />
      <select value={subject} onChange={(e) => setSubject(e.target.value as Subject)}>
        {SUBJECTS.map((s) => <option key={s}>{s}</option>)}
      </select>
      <textarea placeholder="Objectives" value={objectives} onChange={(e) => setObjectives(e.target.value)} />
      <label>Thumbnail <input type="file" accept="image/*" onChange={(e) => setThumb(e.target.files?.[0] ?? null)} /></label>
      <label>Material (PDF/video) <input type="file" onChange={(e) => setMaterial(e.target.files?.[0] ?? null)} /></label>
      <button disabled={pending}>{pending ? "Uploading…" : "Create lesson"}</button>
      {Boolean(error) && <p className="err">{String(error)}</p>}
    </form>
  );
}
