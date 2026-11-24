import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Link, useParams } from "react-router-dom";
import { approveMember, fetchClass, fetchClassMembers, removeMember } from "../services/classes";
import { useLessons } from "../hooks/useLessons";
import LessonForm from "../components/LessonForm";
import LessonList from "../components/LessonList";
import {
  Avatar, Button, Card, Chip, EmptyState, Icon, IconButton, ListItemCard, Toast,
} from "../design-system";
import "./teacher.css";

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
    navigator.clipboard.writeText(cls.data.code).then(() => setCopied(true));
  }

  if (cls.isLoading) return <p className="ds-body">Loading class…</p>;
  if (cls.error || !cls.data) return <p className="td-err">{String(cls.error ?? "Class not found")}</p>;

  const pending = (members.data ?? []).filter((m) => m.status === "pending");
  const active = (members.data ?? []).filter((m) => m.status === "active");
  const approval = cls.data.join_policy === "approval";

  return (
    <>
      <Card variant="white">
        <div className="td-spread">
          <span>
            <h3 className="ds-h3" style={{ margin: 0 }}>{cls.data.name}</h3>
            <span className="ds-caption" style={{ color: "var(--ds-muted)" }}>
              {active.length} student{active.length === 1 ? "" : "s"}
              {pending.length > 0 ? ` · ${pending.length} pending` : ""}
              {approval ? " · Approval required" : ""}
            </span>
          </span>
          <span className="td-row" style={{ flexWrap: "nowrap" }}>
            <span className="ds-caption" style={{ color: "var(--ds-muted)" }}>Join code</span>
            <Chip><span className="td-code">{cls.data.code}</span></Chip>
            <IconButton icon="copy" label="Copy join code" onClick={copy} />
          </span>
        </div>
      </Card>

      {pending.length > 0 && (
        <>
          <h3 className="ds-h3 td-heading">Requests ({pending.length})</h3>
          <div className="td-stack">
            {pending.map((m) => (
              <ListItemCard
                key={m.student_id}
                leading={<Icon name="pending" />}
                title={m.profiles?.full_name || "(no name)"}
                trailing={
                  <span className="td-actions">
                    <Button variant="mint" size="sm" disabled={approve.isPending}
                      onClick={() => approve.mutate(m.student_id)}>Approve</Button>
                    <IconButton icon="delete" label="Decline" disabled={remove.isPending}
                      onClick={() => remove.mutate(m.student_id)} />
                  </span>
                }
              />
            ))}
          </div>
        </>
      )}

      <h3 className="ds-h3 td-heading">Students ({active.length})</h3>
      {members.isLoading && <p className="ds-body">Loading students…</p>}
      {members.error && <p className="td-err">{String(members.error)}</p>}
      {members.data && active.length === 0 && (
        <Card variant="white">
          <EmptyState icon="students" title="No students yet" body="Share the class code." />
        </Card>
      )}
      <div className="td-stack">
        {active.map((m) => (
          <ListItemCard
            key={m.student_id}
            leading={<Avatar name={m.profiles?.full_name || "?"} />}
            title={m.profiles?.full_name || "(no name)"}
            trailing={
              <IconButton icon="delete" label="Remove from class" disabled={remove.isPending}
                onClick={() => remove.mutate(m.student_id)} />
            }
          />
        ))}
      </div>

      <h3 className="ds-h3 td-heading">Lessons</h3>
      <div className="td-stack">
        <LessonForm onCreate={create.mutateAsync} pending={create.isPending} error={create.error} />
        {lessons.error && <p className="td-err">{String(lessons.error)}</p>}
        <LessonList lessons={lessons.data ?? []} onTogglePublish={togglePublish.mutate} />
      </div>
      <p><Link to="/teacher/classes" className="td-link">← Back to classes</Link></p>
      <Toast open={copied} message="Code copied" tone="success" onClose={() => setCopied(false)} />
    </>
  );
}
