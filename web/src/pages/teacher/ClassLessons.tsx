import { useEffect, useRef, useState } from "react";
import { useParams } from "react-router-dom";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { Button, Icon, Modal, Toast } from "../../design-system";
import { useLessons } from "../../hooks/useLessons";
import LessonForm from "../../components/LessonForm";
import LessonList from "../../components/LessonList";
import {
  SUBJECTS, type Lesson, type Subject,
} from "../../types";
import { fetchSubjects, saveSubjects } from "../../services/users";
import lessonsEmptyArt from "../../assets/illustrations/lessons-empty.png";
import "../teacher.css";

type SubjectFilter = "all" | Subject;
type StatusFilter = "all" | "published" | "draft";

const STATUS_OPTIONS: { value: StatusFilter; label: string }[] = [
  { value: "all", label: "All status" },
  { value: "published", label: "Published" },
  { value: "draft", label: "Drafts" },
];

/** The class curriculum: subject-filtered lesson grid + a right-rail
 *  create/edit panel. Publish, edit and delete live on each card. */
export default function ClassLessons() {
  const { classId = "" } = useParams();
  const {
    lessons, counts, attemptCounts,
    create, update, remove, togglePublish,
  } = useLessons(classId);

  const [subject, setSubject] = useState<SubjectFilter>("all");
  const [status, setStatus] = useState<StatusFilter>("all");
  const [statusOpen, setStatusOpen] = useState(false);
  const statusRef = useRef<HTMLDivElement>(null);
  // The right-rail panel is always visible: "new" = create form, a Lesson =
  // edit form (from the card's "···" menu). X/Cancel return to create mode.
  const [panel, setPanel] = useState<"new" | Lesson>("new");
  const qc = useQueryClient();
  // Synced via profiles.settings — refetch on focus picks up edits made on
  // another device (e.g. a subject deleted on the phone).
  const subjectsQ = useQuery({
    queryKey: ["subjects"],
    queryFn: fetchSubjects,
    refetchOnWindowFocus: true,
  });
  const subjects = subjectsQ.data ?? [...SUBJECTS];
  const [unpubTarget, setUnpubTarget] = useState<Lesson | null>(null);
  const [delTarget, setDelTarget] = useState<Lesson | null>(null);
  const [toast, setToast] = useState<string | null>(null);

  const updateSubjects = (next: string[], done: string) => {
    const prev = subjects;
    qc.setQueryData(["subjects"], next);
    void saveSubjects(next).then((ok) => {
      if (ok) setToast(done);
      else {
        qc.setQueryData(["subjects"], prev);
        setToast("Couldn't sync the subject list — try again.");
      }
    });
  };

  // Close the status dropdown on outside click / Escape.
  useEffect(() => {
    if (!statusOpen) return;
    const close = (e: MouseEvent) => {
      if (!statusRef.current?.contains(e.target as Node)) setStatusOpen(false);
    };
    const esc = (e: KeyboardEvent) => e.key === "Escape" && setStatusOpen(false);
    document.addEventListener("mousedown", close);
    document.addEventListener("keydown", esc);
    return () => {
      document.removeEventListener("mousedown", close);
      document.removeEventListener("keydown", esc);
    };
  }, [statusOpen]);

  const rows = lessons.data ?? [];
  const filtered = rows.filter((l) => {
    if (subject !== "all" && l.subject !== subject) return false;
    if (status !== "all" && l.is_published !== (status === "published")) return false;
    return true;
  });

  function onSwitch(l: Lesson) {
    // Warn only when taking a lesson students have already attempted offline.
    if (l.is_published && (attemptCounts.data?.[l.id] ?? 0) > 0) {
      setUnpubTarget(l);
      return;
    }
    togglePublish.mutate(l);
  }

  const editing = panel !== "new" ? panel : null;
  const submitPending = create.isPending || update.isPending;

  return (
    <div className="tl-page">
      <div className="tl-main">
        <div className="tl-topbar">
          <h3 className="td-heading tl-heading">
            Lessons <span className="ts-count">{filtered.length}</span>
          </h3>
        </div>

        <div className="tl-filters">
          <div className="ts-chips" role="tablist" aria-label="Filter by subject">
            {(["all", ...subjects] as SubjectFilter[]).map((s) => (
              <button key={s} type="button" role="tab"
                aria-selected={subject === s}
                className={`ts-chip${subject === s ? " on" : ""}`}
                onClick={() => setSubject(s)}>
                {s === "all" ? "All" : s}
              </button>
            ))}
          </div>
          <div className="ts-menu" ref={statusRef}>
            <button type="button" className="tl-status edge-3"
              aria-haspopup="menu" aria-expanded={statusOpen}
              onClick={() => setStatusOpen((o) => !o)}>
              {STATUS_OPTIONS.find((o) => o.value === status)?.label}
              <Icon name="chevron" size={16} />
            </button>
            {statusOpen && (
              <div className="ts-menu-pop edge-pop" role="menu">
                {STATUS_OPTIONS.map((o) => (
                  <button key={o.value} type="button" role="menuitemradio"
                    aria-checked={status === o.value}
                    className={`tl-menu-item${status === o.value ? " on" : ""}`}
                    onClick={() => { setStatus(o.value); setStatusOpen(false); }}>
                    {o.label}
                  </button>
                ))}
              </div>
            )}
          </div>
        </div>

        {lessons.isLoading && <p className="tl-dim">Loading lessons…</p>}
        {lessons.error && <p className="td-err">{String(lessons.error)}</p>}
        {!lessons.isLoading && filtered.length === 0 && (
          <div className="ts-empty">
            <div data-slot="lessons-empty" className="tl-empty-art">
              <img src={lessonsEmptyArt} alt="" width={150} height={150} />
            </div>
            <h4 className="tl-empty-t">
              {rows.length === 0 ? "No lessons yet" : "No lessons match these filters"}
            </h4>
            <p className="tl-empty-s">
              {rows.length === 0
                ? "Create the first one — it starts as a draft."
                : "Try a different subject or status."}
            </p>
          </div>
        )}

        <LessonList
          lessons={filtered}
          counts={counts.data ?? {}}
          onTogglePublish={onSwitch}
          onEdit={(l) => setPanel(l)}
          onDelete={(l) => setDelTarget(l)}
          onBlockedDelete={() => setToast("Delete or move its activities first.")}
        />
      </div>

      <aside className="tl-panel">
        <LessonForm
          key={editing?.id ?? "new"}
          lesson={editing}
          onSubmit={(input) =>
            (editing
              ? update.mutateAsync({ id: editing.id, input })
              : create.mutateAsync(input)
            ).then(() => setPanel("new"))}
          pending={submitPending}
          error={editing ? update.error : create.error}
          subjects={subjects}
          onAddSubject={(n) => {
            const v = n.trim();
            if (v && !subjects.includes(v)) {
              updateSubjects([...subjects, v], "Subject added");
            }
          }}
          onRemoveSubject={(n) => {
            updateSubjects(subjects.filter((s) => s !== n), "Subject removed");
            if (subject === n) setSubject("all");
          }}
        />
      </aside>

      <Modal open={unpubTarget != null} onClose={() => setUnpubTarget(null)}
        title="Unpublish this lesson?"
        actions={
          <>
            <Button variant="ghost" onClick={() => setUnpubTarget(null)}>Cancel</Button>
            <Button variant="danger" disabled={togglePublish.isPending}
              loading={togglePublish.isPending}
              onClick={() => {
                if (!unpubTarget) return;
                togglePublish.mutate(unpubTarget);
                setUnpubTarget(null);
              }}>
              Unpublish
            </Button>
          </>
        }>
        <p className="ds-body">
          Students have already submitted attempts in “{unpubTarget?.title}”.
          Unpublishing hides the lesson but keeps their scores.
        </p>
      </Modal>

      <Modal open={delTarget != null} onClose={() => setDelTarget(null)}
        title="Delete this lesson?"
        actions={
          <>
            <Button variant="ghost" onClick={() => setDelTarget(null)}>Cancel</Button>
            <Button variant="danger" disabled={remove.isPending}
              loading={remove.isPending}
              onClick={() => {
                if (!delTarget) return;
                remove.mutate(delTarget.id);
                setDelTarget(null);
              }}>
              Delete
            </Button>
          </>
        }>
        <p className="ds-body">
          This also removes students' progress for “{delTarget?.title}”.
        </p>
        {remove.error != null && <p className="td-err">{String(remove.error)}</p>}
      </Modal>

      <Toast open={toast != null} message={toast ?? ""} tone="info"
        onClose={() => setToast(null)} />
    </div>
  );
}
