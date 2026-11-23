import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Link } from "react-router-dom";
import { createClass, deleteClass, fetchMyClasses, type ClassRow } from "../services/classes";
import { I } from "../components/icons";

function subtitle(c: ClassRow): string {
  const enr = c.enrollments ?? [];
  const active = enr.filter((e) => e.status === "active").length;
  const pending = enr.filter((e) => e.status === "pending").length;
  return [
    `${active} student${active === 1 ? "" : "s"}`,
    pending > 0 ? `${pending} pending` : null,
    c.join_policy === "approval" ? "Approval required" : null,
  ].filter(Boolean).join(" · ");
}

export default function Classes() {
  const qc = useQueryClient();
  const classes = useQuery({ queryKey: ["my-classes"], queryFn: fetchMyClasses });
  const [name, setName] = useState("");
  const [policy, setPolicy] = useState<"open" | "approval">("open");
  const [copied, setCopied] = useState<string | null>(null);

  const create = useMutation({
    mutationFn: () => createClass(name.trim(), policy),
    onSuccess: () => { setName(""); qc.invalidateQueries({ queryKey: ["my-classes"] }); },
  });
  const del = useMutation({
    mutationFn: deleteClass,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["my-classes"] }),
  });

  function copy(code: string) {
    navigator.clipboard.writeText(code).then(() => {
      setCopied(code);
      setTimeout(() => setCopied(null), 1500);
    });
  }

  return (
    <>
      <div className="card">
        <h3>New class</h3>
        <div className="row-actions" style={{ marginTop: 0 }}>
          <input className="text-answer" style={{ margin: 0, flex: 1 }} placeholder="Class name, e.g. Grade 7 - Diamond"
            value={name} onChange={(e) => setName(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && name.trim() && create.mutate()} />
          <button disabled={create.isPending || !name.trim()} onClick={() => create.mutate()}>
            {create.isPending ? "Creating…" : "Create class"}
          </button>
        </div>
        <div className="row-actions">
          <span className="kind">How do students join?</span>
          <label className="chip">
            <input type="radio" name="joinpol" checked={policy === "open"} onChange={() => setPolicy("open")} /> Instant
          </label>
          <label className="chip">
            <input type="radio" name="joinpol" checked={policy === "approval"} onChange={() => setPolicy("approval")} /> Approval
          </label>
        </div>
        <p className="empty" style={{ textAlign: "left", padding: 0 }}>
          {policy === "open"
            ? "Anyone with the code joins immediately."
            : "You confirm each request before they see class content."}
        </p>
        {create.error != null && <p className="err">{String(create.error)}</p>}
      </div>

      {classes.isLoading && <p className="empty">Loading classes…</p>}
      {classes.error && <p className="err">{String(classes.error)}</p>}
      {classes.data?.length === 0 && (
        <div className="card"><p className="empty">No classes yet. Create one and share its join code with students.</p></div>
      )}
      {classes.data?.map((c) => (
        <Link key={c.id} to={`/teacher/classes/${c.id}`} className="card lesson-row">
          <span className="lesson-body">
            <strong>{c.name}</strong>
            <small>{subtitle(c)}</small>
          </span>
          <button className="code-chip" title="Copy join code"
            onClick={(e) => { e.preventDefault(); copy(c.code); }}>
            <I name={copied === c.code ? "done" : "copy"} size={14} /> {c.code}
          </button>
          <button className="icon-btn" title="Delete class" disabled={del.isPending}
            onClick={(e) => { e.preventDefault(); del.mutate(c.id); }}>
            <I name="delete" size={15} />
          </button>
          <span className="chev"><I name="chevron" size={20} /></span>
        </Link>
      ))}
    </>
  );
}
