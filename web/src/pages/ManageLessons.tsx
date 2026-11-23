import { FormEvent, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { supabase } from "../lib/supabase";
import { uploadToR2 } from "../lib/r2";

const SUBJECTS = ["Physics", "Chemistry", "Earth Science"] as const;

export default function ManageLessons() {
  const qc = useQueryClient();
  const lessons = useQuery({
    queryKey: ["lessons"],
    queryFn: async () => (await supabase.from("lessons").select("*").order("position")).data ?? [],
  });

  const [title, setTitle] = useState("");
  const [subject, setSubject] = useState<(typeof SUBJECTS)[number]>("Physics");
  const [objectives, setObjectives] = useState("");
  const [thumb, setThumb] = useState<File | null>(null);
  const [material, setMaterial] = useState<File | null>(null);

  const create = useMutation({
    mutationFn: async () => {
      const thumbnail_key = thumb ? await uploadToR2(thumb, "thumbnails") : null;
      const content_key = material ? await uploadToR2(material, "lessons") : null;
      const { error } = await supabase.from("lessons").insert({
        title, subject, objectives, thumbnail_key, content_key,
        position: (lessons.data?.length ?? 0) + 1, is_published: false,
      });
      if (error) throw error;
    },
    onSuccess: () => { setTitle(""); setObjectives(""); setThumb(null); setMaterial(null); qc.invalidateQueries({ queryKey: ["lessons"] }); },
  });

  const togglePublish = useMutation({
    mutationFn: async (l: { id: string; is_published: boolean }) =>
      supabase.from("lessons").update({ is_published: !l.is_published }).eq("id", l.id),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["lessons"] }),
  });

  function onSubmit(e: FormEvent) { e.preventDefault(); create.mutate(); }

  return (
    <>
      <form className="card form" onSubmit={onSubmit}>
        <h3>New lesson</h3>
        <input placeholder="Title" value={title} onChange={(e) => setTitle(e.target.value)} required />
        <select value={subject} onChange={(e) => setSubject(e.target.value as typeof subject)}>
          {SUBJECTS.map((s) => <option key={s}>{s}</option>)}
        </select>
        <textarea placeholder="Objectives" value={objectives} onChange={(e) => setObjectives(e.target.value)} />
        <label>Thumbnail <input type="file" accept="image/*" onChange={(e) => setThumb(e.target.files?.[0] ?? null)} /></label>
        <label>Material (PDF/video) <input type="file" onChange={(e) => setMaterial(e.target.files?.[0] ?? null)} /></label>
        <button disabled={create.isPending}>{create.isPending ? "Uploading…" : "Create lesson"}</button>
        {create.error && <p className="err">{String(create.error)}</p>}
      </form>

      <div className="card">
        <h3>Lessons</h3>
        {lessons.data?.map((l: any) => (
          <div key={l.id} className="perf">
            <span>{l.title} <small>({l.subject})</small></span>
            <button onClick={() => togglePublish.mutate(l)}>{l.is_published ? "Unpublish" : "Publish"}</button>
          </div>
        ))}
      </div>
    </>
  );
}
