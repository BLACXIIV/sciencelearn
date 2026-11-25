import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useNavigate, useParams } from "react-router-dom";
import {
  approveMember, clearPickedClass, deleteClass, fetchClass, fetchClassMembers,
  fetchClassStudentProgress, removeMember,
} from "../../services/classes";
import {
  Avatar, Button, Card, Chip, EmptyState, Icon, IconButton, ListItemCard, Modal, Toast,
} from "../../design-system";
import "../teacher.css";

/** Roster + access control + per-student progress, all scoped to this class. */
export default function ClassStudents() {
  const { classId = "" } = useParams();
  const nav = useNavigate();
  const qc = useQueryClient();
  const cls = useQuery({ queryKey: ["class", classId], queryFn: () => fetchClass(classId) });
  const members = useQuery({ queryKey: ["class-members", classId], queryFn: () => fetchClassMembers(classId) });
  const progress = useQuery({ queryKey: ["class-progress", classId], queryFn: () => fetchClassStudentProgress(classId) });
  const [copied, setCopied] = useState(false);
  const [confirmDel, setConfirmDel] = useState(false);

  const invalidate = () => {
    qc.invalidateQueries({ queryKey: ["class-members", classId] });
    qc.invalidateQueries({ queryKey: ["class", classId] });
    qc.invalidateQueries({ queryKey: ["class-progress", classId] });
  };
  const approve = useMutation({ mutationFn: (sid: string) => approveMember(classId, sid), onSuccess: invalidate });
  const remove = useMutation({ mutationFn: (sid: string) => removeMember(classId, sid), onSuccess: invalidate });
  const del = useMutation({
    mutationFn: () => deleteClass(classId),
    onSuccess: () => { clearPickedClass(); nav("/select-classroom", { replace: true }); },
  });

  const progById = new Map((progress.data ?? []).map((p) => [p.student_id, p]));
  const pending = (members.data ?? []).filter((m) => m.status === "pending");
  const active = (members.data ?? []).filter((m) => m.status === "active");

  function copy() {
    if (!cls.data) return;
    navigator.clipboard.writeText(cls.data.code).then(() => setCopied(true));
  }

  return (
    <>
      {cls.data && (
        <Card variant="white">
          <div className="td-spread">
            <span className="ds-caption" style={{ color: "var(--ds-muted)" }}>
              Share this code — students {cls.data.join_policy === "approval" ? "request to join, you approve" : "join instantly"}.
            </span>
            <span className="td-row" style={{ flexWrap: "nowrap" }}>
              <span className="ds-caption" style={{ color: "var(--ds-muted)" }}>Join code</span>
              <Chip><span className="td-code">{cls.data.code}</span></Chip>
              <IconButton icon="copy" label="Copy join code" onClick={copy} />
            </span>
          </div>
        </Card>
      )}

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
        {active.map((m) => {
          const p = progById.get(m.student_id);
          return (
            <ListItemCard
              key={m.student_id}
              leading={<Avatar name={m.profiles?.full_name || "?"} />}
              title={m.profiles?.full_name || "(no name)"}
              subtitle={
                p
                  ? `Lessons ${p.lessons_pct}% · Quiz ${p.quizzes_pct ?? "–"}% · Pre ${p.pre_score ?? "–"} → Post ${p.post_score ?? "–"}`
                  : "No progress yet"
              }
              trailing={
                <IconButton icon="delete" label="Remove from class" disabled={remove.isPending}
                  onClick={() => remove.mutate(m.student_id)} />
              }
            />
          );
        })}
      </div>

      <h3 className="ds-h3 td-heading">Danger zone</h3>
      <Card variant="white">
        <div className="td-spread">
          <span className="ds-caption" style={{ color: "var(--ds-muted)" }}>
            Deleting removes the class, its lessons and activities for everyone.
          </span>
          <Button variant="danger" size="sm" leadingIcon="delete" onClick={() => setConfirmDel(true)}>
            Delete class
          </Button>
        </div>
      </Card>

      <Modal open={confirmDel} onClose={() => setConfirmDel(false)} title="Delete this class?"
        actions={
          <>
            <Button variant="ghost" onClick={() => setConfirmDel(false)}>Keep it</Button>
            <Button variant="danger" disabled={del.isPending} loading={del.isPending}
              onClick={() => del.mutate()}>
              Delete
            </Button>
          </>
        }>
        <p className="ds-body">
          This removes “{cls.data?.name}” and its lessons. Students lose access.
        </p>
        {del.error != null && <p className="td-err">{String(del.error)}</p>}
      </Modal>
      <Toast open={copied} message="Code copied" tone="success" onClose={() => setCopied(false)} />
    </>
  );
}
