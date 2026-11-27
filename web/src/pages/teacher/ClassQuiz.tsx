import { useState } from "react";
import { Link, useNavigate, useParams, useSearchParams } from "react-router-dom";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useLessons } from "../../hooks/useLessons";
import {
  assessmentAttemptCount, createAssessment, deleteAssessment, fetchLessonAssessments,
  releaseScores, renameAssessment, setAssessmentPublished, setScoreRelease,
} from "../../services/activities";
import {
  Button, Card, Chip, EmptyState, Icon, IconButton, Modal, Select, StatusBadge,
  Switch, TextField, Toast,
} from "../../design-system";
import PopoverMenu from "../../components/PopoverMenu";
import type { Assessment } from "../../types";
import lessonsEmptyArt from "../../assets/illustrations/lessons-empty.png";
import "../teacher.css";

/** Supabase errors are plain objects ({message, details, hint}), not Error
 *  instances — String(e) prints "[object Object]". Unwrap for display. */
const errText = (e: unknown): string =>
  e instanceof Error ? e.message
    : typeof e === "object" && e != null && "message" in e
      ? String((e as { message: unknown }).message)
    : String(e);

/** Subject -> its pastel tile tone (mockup's four subject colors). */
const SUBJECT_PASTEL: Record<string, "blue" | "purple" | "yellow" | "mint"> = {
  "Physics": "blue",
  "Chemistry": "purple",
  "General Science": "yellow",
  "Earth Science": "mint",
};
const subjectTile = (s: string) => SUBJECT_PASTEL[s] ?? "blue";

/** Release-mode chip on the activity card — mint when instant, sun when manual. */
function releaseChip(a: Assessment) {
  if (a.release_scores === "manual") {
    return a.scores_released
      ? <Chip variant="pastel" pastelColor="mint">Scores released</Chip>
      : <Chip variant="pastel" pastelColor="yellow">Manual release</Chip>;
  }
  return (
    <Chip variant="pastel" pastelColor="mint">
      <Icon name="check" size={13} /> Instant scores
    </Chip>
  );
}

/** One activity card on the right column. */
function ActivityCard({ a, lessonId, classId }: {
  a: Assessment; lessonId: string; classId: string;
}) {
  const nav = useNavigate();
  const qc = useQueryClient();
  const [renameOpen, setRenameOpen] = useState(false);
  const [rTitle, setRTitle] = useState(a.title);
  const [rDesc, setRDesc] = useState(a.description);
  const [relOpen, setRelOpen] = useState(false);
  const [delOpen, setDelOpen] = useState(false);
  const [blocked, setBlocked] = useState(false);
  const [releaseConfirm, setReleaseConfirm] = useState(false);
  const [toast, setToast] = useState<string | null>(null);

  const inv = () => qc.invalidateQueries({ queryKey: ["lesson-assessments", lessonId] });
  const qCount = a.question_count ?? 0;

  const pub = useMutation({
    mutationFn: (on: boolean) => setAssessmentPublished(a.id, on),
    onSuccess: inv,
    onError: (e) => setToast(errText(e)),
  });
  const rename = useMutation({
    mutationFn: () => renameAssessment(a.id, { title: rTitle, description: rDesc }),
    onSuccess: () => { setRenameOpen(false); inv(); },
  });
  const rel = useMutation({
    mutationFn: (mode: "immediate" | "manual") => setScoreRelease(a.id, mode),
    onSuccess: inv,
  });
  const relNow = useMutation({
    mutationFn: () => releaseScores(a.id),
    onSuccess: () => { setReleaseConfirm(false); inv(); },
  });
  const del = useMutation({
    mutationFn: () => deleteAssessment(a.id),
    onSuccess: () => { setDelOpen(false); inv(); },
    onError: (e) => setToast(errText(e)),
  });
  /** Delete guard pre-check — the server trigger (0032) is the hard block. */
  const tryDelete = async () => {
    try {
      const n = await assessmentAttemptCount(a.id);
      if (n > 0) { setBlocked(true); return; }
    } catch { /* count fetch failed — the server still guards */ }
    setDelOpen(true);
  };

  const releaseOpts = [
    { value: "immediate", label: "Instant scores" },
    { value: "manual", label: "Manual release" },
    ...(a.release_scores === "manual" && !a.scores_released
      ? [{ value: "__now", label: "Release scores now" }] : []),
  ];

  return (
    <Card variant="white" className="td-qcard">
      <div className="td-spread">
        <span className="td-qcard-title">
          <strong>{a.title}</strong>
          <StatusBadge status={a.is_published ? "published" : "draft"} />
        </span>
      </div>
      {a.description !== "" && (
        <p className="td-qcard-desc">{a.description}</p>
      )}
      <div className="td-qcard-chips">
        <Chip variant="pastel" pastelColor="blue" className="td-qchip">
          {qCount} {qCount === 1 ? "question" : "questions"}
        </Chip>
        {releaseChip(a)}
        {qCount === 0 && (
          <Chip variant="pastel" pastelColor="yellow">Add questions to publish</Chip>
        )}
      </div>
      <div className="td-qcard-actions">
        <Switch tone="teal" checked={a.is_published}
          disabled={qCount === 0 || pub.isPending}
          onChange={(e) => pub.mutate(e.target.checked)} />
        <span style={{ flex: 1 }} />
        <Button size="xs"
          onClick={() => nav(`/teacher/c/${classId}/quiz/a/${a.id}`)}>
          Questions
        </Button>
        <span className="td-qcard-prev">
          <Button variant="line" size="sm" leadingIcon="show"
            onClick={() => nav(`/teacher/c/${classId}/quiz/a/${a.id}/preview`)}>
            Preview
          </Button>
          <span className="td-new-pill">NEW</span>
        </span>
        <PopoverMenu label="Activity actions" items={[
          { key: "rename", label: "Rename", icon: <Icon name="edit" size={16} />,
            onSelect: () => { setRTitle(a.title); setRDesc(a.description); setRenameOpen(true); } },
          { key: "release", label: "Release settings", icon: <Icon name="settings" size={16} />,
            onSelect: () => setRelOpen(true) },
          { key: "del", label: "Delete", icon: <Icon name="delete" size={16} />,
            danger: true, onSelect: tryDelete },
        ]} />
      </div>

      {/* rename modal */}
      <Modal open={renameOpen} onClose={() => setRenameOpen(false)} title="Rename activity"
        actions={
          <>
            <Button variant="outline" onClick={() => setRenameOpen(false)}>Cancel</Button>
            <Button disabled={rename.isPending || !rTitle.trim()} loading={rename.isPending}
              onClick={() => rename.mutate()}>
              Save
            </Button>
          </>
        }>
        <div className="td-stack">
          <TextField clean label="Title" value={rTitle}
            onChange={(e) => setRTitle(e.target.value)} />
          <TextField clean label="Description" value={rDesc}
            placeholder="optional"
            onChange={(e) => setRDesc(e.target.value)} />
        </div>
        {rename.error != null && <p className="td-err">{errText(rename.error)}</p>}
      </Modal>

      {/* release settings — same choices as the builder header dropdown */}
      <Modal open={relOpen} onClose={() => setRelOpen(false)} title="Release settings"
        actions={
          <>
            <Button variant="outline" onClick={() => setRelOpen(false)}>Close</Button>
          </>
        }>
        <div className="td-stack">
          <Select label="Score release" value={a.release_scores}
            onChange={(e) => {
              const v = e.target.value;
              if (v === "__now") setReleaseConfirm(true);
              else rel.mutate(v as "immediate" | "manual");
            }}
            options={releaseOpts} />
          <p className="ds-caption" style={{ color: "var(--ds-muted)", margin: 0 }}>
            Instant shows the score right after submit; manual holds it until you release.
          </p>
          {a.scores_released && <StatusBadge status="released" label="Scores released" />}
          {rel.error != null && <p className="td-err">{errText(rel.error)}</p>}
        </div>
      </Modal>

      {/* release-now confirm */}
      <Modal open={releaseConfirm} onClose={() => setReleaseConfirm(false)}
        title="Release scores now?"
        actions={
          <>
            <Button variant="outline" onClick={() => setReleaseConfirm(false)}>Cancel</Button>
            <Button loading={relNow.isPending} onClick={() => relNow.mutate()}>
              Release
            </Button>
          </>
        }>
        <p className="ds-body">
          Students who already took “{a.title}” will see their scores right away.
        </p>
        {relNow.error != null && <p className="td-err">{errText(relNow.error)}</p>}
      </Modal>

      {/* delete confirm / blocked notice */}
      <Modal open={delOpen} onClose={() => setDelOpen(false)} title="Delete activity?"
        actions={
          <>
            <Button variant="ghost" onClick={() => setDelOpen(false)}>Keep it</Button>
            <Button variant="danger" disabled={del.isPending} loading={del.isPending}
              onClick={() => del.mutate()}>
              Delete
            </Button>
          </>
        }>
        <p className="ds-body">This removes “{a.title}” and its questions.</p>
      </Modal>
      <Modal open={blocked} onClose={() => setBlocked(false)} title="Can't delete yet"
        actions={
          <Button variant="outline" onClick={() => setBlocked(false)}>Got it</Button>
        }>
        <p className="ds-body">
          Students already took this. Unpublish it instead.
        </p>
      </Modal>
      <Toast open={toast != null} message={toast ?? ""} tone="error"
        onClose={() => setToast(null)} />
    </Card>
  );
}

/** Create Quiz: "Pick a lesson" card on the left, activities + cards on the
 *  right. The old always-open form and lesson dropdown are gone — "New
 *  activity" opens a small modal. */
export default function ClassQuiz() {
  const { classId = "" } = useParams();
  const [params] = useSearchParams();
  const { lessons, counts } = useLessons(classId);
  const qc = useQueryClient();
  const [lessonId, setLessonId] = useState(params.get("lesson") ?? "");
  const [newOpen, setNewOpen] = useState(false);
  const [title, setTitle] = useState("");
  const [desc, setDesc] = useState("");
  const list = lessons.data ?? [];
  const chosen = lessonId || list[0]?.id || "";

  const assessments = useQuery({
    queryKey: ["lesson-assessments", chosen],
    queryFn: () => fetchLessonAssessments(chosen),
    enabled: chosen !== "",
  });

  const create = useMutation({
    mutationFn: () => createAssessment({
      lesson_id: chosen, kind: "topic_quiz",
      title: title.trim(), description: desc.trim(),
    }),
    onSuccess: () => {
      setTitle(""); setDesc(""); setNewOpen(false);
      qc.invalidateQueries({ queryKey: ["lesson-assessments", chosen] });
      qc.invalidateQueries({ queryKey: ["lesson-activity-counts"] });
    },
  });

  if (lessons.isLoading) return <p className="ds-body">Loading lessons…</p>;
  if (lessons.error) return <p className="td-err">{errText(lessons.error)}</p>;

  if (list.length === 0) {
    return (
      <Card variant="white">
        <EmptyState icon="lessons" title="No lessons yet"
          body="Quizzes attach to lessons — create a lesson first."
          action={<Link to={`/teacher/c/${classId}/lessons`} className="td-link">Go to Lessons →</Link>} />
      </Card>
    );
  }

  const lesson = list.find((l) => l.id === chosen);
  const acts = assessments.data ?? [];
  const countMap = counts.data ?? {};

  return (
    <div className="td-quiz-grid">
      {/* left: lesson picker */}
      <Card variant="white" className="td-pick">
        <span className="ds-label">Pick a lesson</span>
        <div className="td-pick-list">
          {list.map((l) => (
            <button key={l.id} type="button"
              className={`td-lrow${chosen === l.id ? " on" : ""}`}
              onClick={() => setLessonId(l.id)}>
              <span className={`td-ltile td-ltile-${subjectTile(l.subject)}`}>
                <Icon name="lessons" size={20} />
              </span>
              <span className="td-lrow-main">
                <span className="td-lrow-title">{l.title}</span>
                <span className="td-lrow-sub">
                  {l.subject} · {countMap[l.id] ?? 0}{" "}
                  {(countMap[l.id] ?? 0) === 1 ? "activity" : "activities"}
                </span>
              </span>
              <Icon name="chevron" size={18}
                color={chosen === l.id ? "var(--ds-blue)" : "var(--ds-muted)"} />
            </button>
          ))}
        </div>
      </Card>

      {/* right: activities for the picked lesson */}
      <div className="td-stack">
        <div className="td-quiz-head">
          <div>
            <span className="ds-label">Activities for</span>
            <h3 className="ds-h3" style={{ margin: 0 }}>{lesson?.title ?? "—"}</h3>
          </div>
        </div>

        {assessments.isLoading && <p className="ds-body">Loading activities…</p>}
        {assessments.error && <p className="td-err">{errText(assessments.error)}</p>}

        {!assessments.isLoading && acts.length === 0 && (
          <Card variant="white">
            <div className="td-quiz-empty-wrap">
              <div data-slot="quiz-empty" className="td-quiz-empty">
                <img src={lessonsEmptyArt} alt="" width={220} height={160} />
              </div>
              <EmptyState icon="assessment" title="No activities yet"
                body="Create one with New activity, then add questions." />
            </div>
          </Card>
        )}

        {acts.map((a) => (
          <ActivityCard key={a.id} a={a} lessonId={chosen} classId={classId} />
        ))}

        {/* dashed "New activity" card at the end */}
        <button type="button" className="td-quiz-new"
          onClick={() => setNewOpen(true)}>
          <Icon name="add" size={20} />
          <span>New activity</span>
        </button>
      </div>

      {/* create modal */}
      <Modal open={newOpen} onClose={() => setNewOpen(false)} title="New activity"
        actions={
          <>
            <Button variant="outline" onClick={() => setNewOpen(false)}>Cancel</Button>
            <Button disabled={create.isPending || !title.trim()} loading={create.isPending}
              onClick={() => create.mutate()}>
              Create
            </Button>
          </>
        }>
        <div className="td-stack">
          <TextField clean label="Title" value={title}
            placeholder="e.g. ELABORATE — Reaction Detective"
            onChange={(e) => setTitle(e.target.value)} />
          <TextField clean label="Description" value={desc}
            placeholder="optional"
            onChange={(e) => setDesc(e.target.value)} />
        </div>
        {create.error != null && <p className="td-err">{errText(create.error)}</p>}
      </Modal>
    </div>
  );
}
