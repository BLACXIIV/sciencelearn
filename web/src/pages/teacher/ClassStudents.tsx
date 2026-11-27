import { useEffect, useRef, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useLocation, useNavigate, useParams } from "react-router-dom";
import {
  approveMember, clearPickedClass, deleteClass, fetchClass, fetchClassMembers,
  fetchClassStudentProgress, fetchLessonActivityCounts, removeMember,
  type ClassMember,
} from "../../services/classes";
import rosterEmptyArt from "../../assets/illustrations/roster-empty.png";
import {
  Avatar, Button, Card, Icon, IconButton, Modal, ProgressBar,
  SearchField, Toast,
} from "../../design-system";
import "../teacher.css";

type Filter = "all" | "attention";
const needsAttention = (q: number | null | undefined) => q == null || q < 70;

/** Roster + access control + per-student progress, all scoped to this class. */
export default function ClassStudents() {
  const { classId = "" } = useParams();
  const nav = useNavigate();
  const loc = useLocation();
  const qc = useQueryClient();
  const cls = useQuery({ queryKey: ["class", classId], queryFn: () => fetchClass(classId) });
  const members = useQuery({ queryKey: ["class-members", classId], queryFn: () => fetchClassMembers(classId) });
  const progress = useQuery({ queryKey: ["class-progress", classId], queryFn: () => fetchClassStudentProgress(classId) });
  const actCounts = useQuery({ queryKey: ["lesson-activity-counts", classId], queryFn: () => fetchLessonActivityCounts(classId) });
  const [copied, setCopied] = useState(false);
  const [toast, setToast] = useState<string | null>(null);
  const [confirmDel, setConfirmDel] = useState(false);
  const [filter, setFilter] = useState<Filter>("all");
  const [query, setQuery] = useState("");
  const [menuFor, setMenuFor] = useState<string | null>(null);
  const [removeTarget, setRemoveTarget] = useState<ClassMember | null>(null);
  const menuRef = useRef<HTMLDivElement>(null);

  // Guard redirects land here with {toast: "…"} in location state.
  useEffect(() => {
    const msg = (loc.state as { toast?: string } | null)?.toast;
    if (msg) {
      setToast(msg);
      nav(loc.pathname, { replace: true, state: {} });
    }
  }, [loc.state, loc.pathname, nav]);

  // Close the "···" menu on outside click / Escape.
  useEffect(() => {
    if (!menuFor) return;
    const close = (e: MouseEvent) => {
      if (!menuRef.current?.contains(e.target as Node)) setMenuFor(null);
    };
    const esc = (e: KeyboardEvent) => e.key === "Escape" && setMenuFor(null);
    document.addEventListener("mousedown", close);
    document.addEventListener("keydown", esc);
    return () => {
      document.removeEventListener("mousedown", close);
      document.removeEventListener("keydown", esc);
    };
  }, [menuFor]);

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

  // A class that still owns activities can't be deleted — the lessons→
  // assessments FK is RESTRICT (0015). Disable the button + say why.
  const hasActivities = Object.values(actCounts.data ?? {}).some((n) => n > 0);
  const delErrorText = (e: unknown): string => {
    const msg = e instanceof Error ? e.message
      : typeof e === "object" && e != null && "message" in e
        ? String((e as { message: unknown }).message) : String(e);
    return /foreign key|violates|restrict/i.test(msg)
      ? "Delete or move its activities first." : msg;
  };
  const progById = new Map((progress.data ?? []).map((p) => [p.student_id, p]));
  const pending = (members.data ?? []).filter((m) => m.status === "pending");
  const active = (members.data ?? []).filter((m) => m.status === "active");
  const shown = active.filter((m) => {
    if (filter === "attention" && !needsAttention(progById.get(m.student_id)?.quizzes_pct)) return false;
    if (query && !(m.profiles?.full_name ?? "").toLowerCase().includes(query.toLowerCase())) return false;
    return true;
  });

  function copy() {
    if (!cls.data) return;
    navigator.clipboard.writeText(cls.data.code).then(() => setCopied(true));
  }

  return (
    <>
      {cls.data && (
        <div className="ts-strip edge-8">
          <div className="ts-strip-info">
            <span className="ts-strip-cap">Join code</span>
            <span className="ts-strip-sub">
              Students {cls.data.join_policy === "approval"
                ? "request to join, you approve." : "join instantly."}
            </span>
          </div>
          <div className="ts-strip-actions">
            <span className="ts-code edge-4">{cls.data.code}</span>
            <Button variant="white" size="sm" leadingIcon="copy" onClick={copy}>
              Copy code
            </Button>
          </div>
        </div>
      )}

      {pending.length > 0 && (
        <>
          <h3 className="ds-h3 td-heading">
            Requests <span className="ts-count ts-count-sun">{pending.length}</span>
          </h3>
          <div className="td-stack">
            {pending.map((m) => (
              <Card key={m.student_id} variant="white" className="ts-req">
                <Avatar name={m.profiles?.full_name || "?"} pastelColor="yellow" size={44} />
                <div className="ts-req-info">
                  <span className="ts-req-name">{m.profiles?.full_name || "(no name)"}</span>
                  <span className="ts-req-sub">Wants to join {cls.data?.name ?? "the class"}</span>
                </div>
                <div className="ts-req-btns">
                  <Button variant="outline" size="sm" disabled={remove.isPending}
                    onClick={() => remove.mutate(m.student_id)}>Decline</Button>
                  <Button variant="mint" size="sm" disabled={approve.isPending}
                    onClick={() => approve.mutate(m.student_id)}>Approve</Button>
                </div>
              </Card>
            ))}
          </div>
        </>
      )}

      <div className="ts-roster-head">
        <h3 className="ds-h3" style={{ margin: 0 }}>
          Students <span className="ts-count">{active.length}</span>
        </h3>
        <div className="ts-filters">
          <div className="ts-chips" role="tablist" aria-label="Filter students">
            {([["all", "All"], ["attention", "Needs attention"]] as [Filter, string][]).map(([v, l]) => (
              <button key={v} type="button" role="tab" aria-selected={filter === v}
                className={`ts-chip${filter === v ? " on" : ""}`}
                onClick={() => setFilter(v)}>{l}</button>
            ))}
          </div>
          <SearchField
            label="Search students"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search students"
          />
        </div>
      </div>

      {members.isLoading && <p className="ds-body">Loading students…</p>}
      {members.error && <p className="td-err">{String(members.error)}</p>}
      {members.data && active.length === 0 && (
        <div className="ts-empty" data-slot="roster-empty">
          <img src={rosterEmptyArt} alt="" width={140} height={100} />
          <p className="ds-body" style={{ color: "var(--ds-muted)" }}>
            No students yet — share the join code with your class.
          </p>
        </div>
      )}
      {members.data && active.length > 0 && shown.length === 0 && (
        <p className="ds-body" style={{ color: "var(--ds-muted)" }}>
          No students match this filter.
        </p>
      )}
      <div className="td-stack">
        {shown.map((m) => {
          const p = progById.get(m.student_id);
          const name = m.profiles?.full_name || "(no name)";
          const go = () => nav(`/teacher/c/${classId}/reports/${m.student_id}`);
          return (
            <div
              key={m.student_id}
              className="ts-row edge-4"
              role="link"
              tabIndex={0}
              aria-label={`Open report for ${name}`}
              onClick={go}
              onKeyDown={(e) => {
                if (e.key === "Enter" || e.key === " ") { e.preventDefault(); go(); }
              }}
            >
              <Avatar name={name} size={44} />
              <div className="ts-row-id">
                <span className="ts-row-name">{name}</span>
                <span className="ts-row-sub">Tap to open the report</span>
              </div>
              <div className="ts-stat">
                <span className="ts-stat-cap">Lessons</span>
                <span className="ts-stat-val">{p ? `${Math.round(p.lessons_pct)}%` : "—"}</span>
                <ProgressBar size="sm" tone="success" value={p?.lessons_pct ?? 0} label="Lessons" />
              </div>
              <div className="ts-stat">
                <span className="ts-stat-cap">Quiz</span>
                <span className="ts-stat-val">{p?.quizzes_pct != null ? `${p.quizzes_pct}%` : "—"}</span>
                <ProgressBar size="sm" tone="blue" value={p?.quizzes_pct ?? 0} label="Quiz average" />
              </div>
              <span className="ts-report">
                View report <Icon name="chevron" size={16} />
              </span>
              <div className="ts-menu" ref={menuFor === m.student_id ? menuRef : undefined}>
                <IconButton icon="more" label={`More actions for ${name}`}
                  onClick={(e) => {
                    e.stopPropagation();
                    setMenuFor(menuFor === m.student_id ? null : m.student_id);
                  }} />
                {menuFor === m.student_id && (
                  <div className="ts-menu-pop edge-pop" role="menu">
                    <button type="button" role="menuitem" className="ts-menu-item"
                      onClick={(e) => {
                        e.stopPropagation();
                        setMenuFor(null);
                        setRemoveTarget(m);
                      }}>
                      <Icon name="delete" size={16} /> Remove from class
                    </button>
                  </div>
                )}
              </div>
            </div>
          );
        })}
      </div>

      <h3 className="ds-h3 td-heading">Danger zone</h3>
      <Card variant="white">
        <div className="td-spread">
          <span className="ts-danger">
            <span className="ts-danger-t">Danger zone</span>
            <span className="ts-danger-s">
              Deleting removes the class and its lessons. A class that still has
              activities cannot be deleted yet.
            </span>
          </span>
          <span title={hasActivities
            ? "Delete or move this class's activities first."
            : undefined}>
            <Button variant="danger" size="sm" disabled={hasActivities}
              onClick={() => setConfirmDel(true)}>
              Delete class
            </Button>
          </span>
        </div>
        {hasActivities && (
          <p className="ts-danger-s" style={{ marginTop: 8 }}>
            Delete or move this class's activities first.
          </p>
        )}
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
        {del.error != null && <p className="td-err">{delErrorText(del.error)}</p>}
      </Modal>

      <Modal open={removeTarget != null} onClose={() => setRemoveTarget(null)}
        title="Remove from class?"
        actions={
          <>
            <Button variant="ghost" onClick={() => setRemoveTarget(null)}>Cancel</Button>
            <Button variant="danger" disabled={remove.isPending} loading={remove.isPending}
              onClick={() => {
                if (!removeTarget) return;
                remove.mutate(removeTarget.student_id);
                setRemoveTarget(null);
              }}>
              Remove
            </Button>
          </>
        }>
        <p className="ds-body">
          “{removeTarget?.profiles?.full_name}” loses access to this class.
        </p>
      </Modal>

      <Toast open={copied || toast != null} message={toast ?? "Code copied"}
        tone="success" onClose={() => { setCopied(false); setToast(null); }} />
    </>
  );
}
