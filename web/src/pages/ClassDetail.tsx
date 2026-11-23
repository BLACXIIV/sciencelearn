import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Link, useParams } from "react-router-dom";
import { approveMember, fetchClass, fetchClassMembers, removeMember } from "../services/classes";
import { useLessons } from "../hooks/useLessons";
import LessonForm from "../components/LessonForm";
import LessonList from "../components/LessonList";
import { I } from "../components/icons";

/** Teacher class detail: header (code + policy), pending requests, roster, lessons. */
export default function ClassDetail() {
  const { id = "" } = useParams();
  const qc = useQueryClient();
  const cls = useQuery({ queryKey: ["class", id], queryFn: () => fetchClass(id) });
  const members = useQuery({ queryKey: ["class-members", id], queryFn: () => fetchClassMembers(id) });
  const { lessons, create, togglePublish } = useLessons(id);
  const [copied, setCopied] = useState(false);

  const invalidate = () => {
    qc.invalidateQueries({ queryKey: ["class-members", id] });
    qc.invalidateQueries({ queryKey: ["class", id] });
    qc.invalidateQueries({ queryKey: ["my-classes"] });
  };
  const approve = useMutation({ mutationFn: (sid: string) => approveMember(id, sid), onSuccess: invalidate });
  const remove = useMutation({ mutationFn: (sid: string) => removeMember(id, sid), onSuccess: invalidate });

  function copy() {
    if (!cls.data) return;
    navigator.clipboard.writeText(cls.data.code).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 1500);
    });
  }

  if (cls.isLoading) return <p className="empty">Loading class…</p>;
  if (cls.error || !cls.data) return <p className="err">{String(cls.error ?? "Class not found")}</p>;

  const pending = (members.data ?? []).filter((m) => m.status === "pending");
  const active = (members.data ?? []).filter((m) => m.status === "active");
  const approval = cls.data.join_policy === "approval";

  return (
    <>
      <div className="card">
        <div className="perf">
          <span>
            <strong>{cls.data.name}</strong>
            <small className="kind">
              {active.length} student{active.length === 1 ? "" : "s"}
              {pending.length > 0 ? ` · ${pending.length} pending` : ""}
              {approval ? " · Approval required" : ""}
            </small>
          </span>
          <span className="kind">Join code</span>
          <button className="code-chip" onClick={copy} title="Copy join code">
            <I name={copied ? "done" : "copy"} size={14} /> {cls.data.code}
          </button>
        </div>
      </div>

      {pending.length > 0 && (
        <div className="card">
          <h3>Requests ({pending.length})</h3>
          <div className="q-list">
            {pending.map((m) => (
              <div key={m.student_id} className="perf">
                <span className="avatar"><I name="pending" size={16} /></span>
                <span>{m.profiles?.full_name || "(no name)"}</span>
                <button className="secondary" disabled={approve.isPending}
                  onClick={() => approve.mutate(m.student_id)}>Approve</button>
                <button className="icon-btn" title="Decline" disabled={remove.isPending}
                  onClick={() => remove.mutate(m.student_id)}><I name="delete" size={15} /></button>
              </div>
            ))}
          </div>
        </div>
      )}

      <div className="card">
        <h3>Students ({active.length})</h3>
        {members.isLoading && <p className="empty">Loading students…</p>}
        {members.error && <p className="err">{String(members.error)}</p>}
        {members.data && active.length === 0 && (
          <p className="empty">No students yet, share the class code.</p>
        )}
        <div className="q-list">
          {active.map((m) => (
            <div key={m.student_id} className="perf">
              <span className="avatar">{(m.profiles?.full_name || "?")[0].toUpperCase()}</span>
              <span>{m.profiles?.full_name || "(no name)"}</span>
              <button className="icon-btn" title="Remove from class" disabled={remove.isPending}
                onClick={() => remove.mutate(m.student_id)}><I name="delete" size={15} /></button>
            </div>
          ))}
        </div>
      </div>

      <h3 style={{ margin: "20px 0 8px" }}>Lessons</h3>
      <LessonForm onCreate={create.mutateAsync} pending={create.isPending} error={create.error} />
      {lessons.error && <p className="err">{String(lessons.error)}</p>}
      <LessonList lessons={lessons.data ?? []} onTogglePublish={togglePublish.mutate} />
      <p className="empty"><Link to="/teacher/classes">← Back to classes</Link></p>
    </>
  );
}
