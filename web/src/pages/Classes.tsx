import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { createClass, deleteClass, fetchMyClasses, type ClassRow } from "../services/classes";
import {
  Button, Card, Chip, EmptyState, IconButton, ListItemCard, Modal,
  SegmentedControl, TextField, Toast,
} from "../design-system";
import "./teacher.css";

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
  const [copied, setCopied] = useState(false);
  const [confirmId, setConfirmId] = useState<string | null>(null);

  const create = useMutation({
    mutationFn: () => createClass(name.trim(), policy),
    onSuccess: () => { setName(""); qc.invalidateQueries({ queryKey: ["my-classes"] }); },
  });
  const del = useMutation({
    mutationFn: deleteClass,
    onSuccess: () => qc.invalidateQueries({ queryKey: ["my-classes"] }),
  });

  function copy(code: string) {
    navigator.clipboard.writeText(code).then(() => setCopied(true));
  }

  return (
    <>
      <Card variant="white">
        <h3 className="ds-h3" style={{ marginTop: 0 }}>New class</h3>
        <div className="td-row">
          <div style={{ flex: 1, minWidth: 200 }}>
            <TextField label="Class name" placeholder="e.g. Grade 7 - Diamond" value={name}
              onChange={(e) => setName(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && name.trim() && create.mutate()} />
          </div>
          <Button disabled={create.isPending || !name.trim()} loading={create.isPending}
            onClick={() => create.mutate()} style={{ alignSelf: "flex-end" }}>
            Create class
          </Button>
        </div>
        <div className="td-heading" style={{ marginBottom: 0 }}>
          <SegmentedControl
            ariaLabel="How do students join?"
            options={[
              { value: "open", label: "Instant" },
              { value: "approval", label: "Approval" },
            ]}
            value={policy}
            onChange={(v) => setPolicy(v as "open" | "approval")}
          />
          <p className="ds-caption" style={{ margin: "var(--ds-s2) 0 0" }}>
            {policy === "open"
              ? "Anyone with the code joins immediately."
              : "You confirm each request before they see class content."}
          </p>
        </div>
        {create.error != null && <p className="td-err">{String(create.error)}</p>}
      </Card>

      <div className="td-stack" style={{ marginTop: "var(--ds-s4)" }}>
        {classes.isLoading && <p className="ds-body">Loading classes…</p>}
        {classes.error && <p className="td-err">{String(classes.error)}</p>}
        {classes.data?.length === 0 && (
          <Card variant="white">
            <EmptyState icon="school" title="No classes yet"
              body="Create one and share its join code with students." />
          </Card>
        )}
        {classes.data?.map((c) => (
          <ListItemCard
            key={c.id}
            to={`/teacher/classes/${c.id}`}
            title={c.name}
            subtitle={subtitle(c)}
            trailing={
              <span className="td-row" style={{ flexWrap: "nowrap" }}>
                <Chip><span className="td-code">{c.code}</span></Chip>
                <IconButton icon="copy" label="Copy join code"
                  onClick={(e) => { e.preventDefault(); e.stopPropagation(); copy(c.code); }} />
                <IconButton icon="delete" label="Delete class" disabled={del.isPending}
                  onClick={(e) => { e.preventDefault(); e.stopPropagation(); setConfirmId(c.id); }} />
              </span>
            }
          />
        ))}
      </div>

      <Modal open={confirmId != null} onClose={() => setConfirmId(null)} title="Delete class?"
        actions={
          <>
            <Button variant="ghost" onClick={() => setConfirmId(null)}>Keep it</Button>
            <Button variant="danger" disabled={del.isPending}
              onClick={() => { del.mutate(confirmId!); setConfirmId(null); }}>
              Delete
            </Button>
          </>
        }>
        <p className="ds-body">This removes the class and its lessons. Students lose access.</p>
      </Modal>
      <Toast open={copied} message="Code copied" tone="success" onClose={() => setCopied(false)} />
    </>
  );
}
