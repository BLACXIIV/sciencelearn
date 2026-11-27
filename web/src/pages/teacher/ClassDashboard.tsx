import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Link, useNavigate, useParams } from "react-router-dom";
import {
  fetchClass, fetchClassCompletedCount, fetchClassMembers, fetchClassStudentProgress,
} from "../../services/classes";
import { computeClassStats } from "../../utils/stats";
import ClassChart from "../../components/ClassChart";
import {
  Avatar, Badge, Button, Card, EmptyState, ListItemCard, StatCard, Toast,
} from "../../design-system";
import bannerArt from "../../assets/illustrations/teacher-banner.png";
import emptyArt from "../../assets/illustrations/needs-attention.png";
import "../teacher.css";

/** Class-scoped dashboard: is THIS class on track? Hero, stat tiles,
 *  class-average rings, then the students who need attention. Roster
 *  detail lives in Students. */
export default function ClassDashboard() {
  const { classId = "" } = useParams();
  const nav = useNavigate();
  const cls = useQuery({ queryKey: ["class", classId], queryFn: () => fetchClass(classId) });
  const students = useQuery({ queryKey: ["class-progress", classId], queryFn: () => fetchClassStudentProgress(classId) });
  const members = useQuery({ queryKey: ["class-members", classId], queryFn: () => fetchClassMembers(classId) });
  const completed = useQuery({ queryKey: ["class-completed", classId], queryFn: () => fetchClassCompletedCount(classId) });
  const [copied, setCopied] = useState(false);

  const rows = students.data ?? [];
  const active = (members.data ?? []).filter((m) => m.status === "active").length;
  const pending = (members.data ?? []).filter((m) => m.status === "pending").length;

  // Empty vs true-zero: no scored students → "—" + reason, never "0%"/"+0%".
  const scored = rows.filter((s) => s.quizzes_pct != null);
  const both = rows.filter((s) => s.pre_score != null && s.post_score != null);
  const stats = computeClassStats(rows, completed.data ?? 0);
  const [studentsStat, completedStat, avgStat, gainStat] = stats;

  // Lowest scores first — nulls (no attempts) sort below 0 so they surface first.
  const attention = [...rows]
    .sort((a, b) => (a.quizzes_pct ?? -1) - (b.quizzes_pct ?? -1))
    .filter((r) => r.quizzes_pct == null || r.quizzes_pct < 70)
    .slice(0, 5);

  function copy() {
    if (!cls.data) return;
    navigator.clipboard.writeText(cls.data.code).then(() => setCopied(true));
  }

  if (students.isLoading) return <p className="ds-body">Loading class dashboard…</p>;
  if (students.error) return <p className="td-err">{String(students.error)}</p>;

  return (
    <>
      {cls.data && (
        <section className="td-hero edge-8">
          <div className="td-hero-info">
            <span className="td-hero-pill">
              {cls.data.join_policy === "approval" ? "Approval required" : "Instant join"}
            </span>
            <h1 className="td-hero-title">{cls.data.name}</h1>
            <div className="td-hero-row">
              <span className="td-code-chip edge-4">{cls.data.code}</span>
              <Button variant="ghost" size="sm" leadingIcon="copy" onClick={copy}>
                Copy code
              </Button>
              <span className="td-hero-cap">Share it so students can join</span>
            </div>
          </div>
          {/* Banner art — swap the PNG for the final SVG export when it lands. */}
          <div className="td-hero-art" data-slot="teacher-banner">
            <img src={bannerArt} alt="" />
          </div>
        </section>
      )}

      <div className="td-stats bento bento-sm">
        <StatCard filled pastelColor="blue" icon={studentsStat.icon!}
          value={String(studentsStat.value)} label="Total students"
          note={`${active} active`} />
        <StatCard filled pastelColor="mint" icon={completedStat.icon!}
          value={String(completedStat.value)} label="Lessons completed"
          note="Total 100% completions" />
        <StatCard filled pastelColor="purple" icon={avgStat.icon!}
          value={scored.length ? String(avgStat.value) : "—"} label="Quiz average"
          note={scored.length ? `${scored.length} attempted` : "No quiz attempts yet"} />
        <StatCard filled pastelColor="yellow" icon={gainStat.icon!}
          value={both.length ? String(gainStat.value) : "—"} label="Class gain"
          note={both.length ? "Pre → post average" : "Needs pre and post-test"} />
        <StatCard alert pastelColor="yellow" icon="pending" value={String(pending)}
          label={pending === 1 ? "Pending request" : "Pending requests"}
          note={pending ? "Waiting for approval" : "No open requests"}
          action={
            <Button variant="sun" size="sm" onClick={() => nav(`/teacher/c/${classId}/students`)}>
              Review
            </Button>
          } />
      </div>

      <div className="bento">
        <ClassChart students={rows} />

        <Card variant="white" className="td-attn">
          <div className="td-attn-head">
            <h3 className="ds-h3">Needs attention</h3>
            <Link to={`/teacher/c/${classId}/students`} className="td-link">All students</Link>
          </div>
          {attention.length === 0 ? (
            <>
              <EmptyState icon="done" title="Everyone's on track"
                body="No students are behind on quizzes right now." />
              {/* Empty-state art — swap the PNG for the final SVG when it lands. */}
              <div className="td-attn-art" data-slot="needs-attention-empty">
                <img src={emptyArt} alt="" width={140} height={100} />
              </div>
            </>
          ) : (
            <div className="td-stack">
              {attention.map((s) => (
                <ListItemCard
                  key={s.student_id}
                  leading={<Avatar name={s.full_name || "?"} />}
                  title={s.full_name}
                  subtitle={s.quizzes_pct == null ? "No quiz attempts yet" : `Quiz average ${s.quizzes_pct}%`}
                  trailing={
                    s.quizzes_pct == null
                      ? <span className="td-chip-soft">—</span>
                      : <Badge tone="sun">{s.quizzes_pct}%</Badge>
                  }
                />
              ))}
            </div>
          )}
        </Card>
      </div>

      <div className="td-quick">
        <Button leadingIcon="add" onClick={() => nav(`/teacher/c/${classId}/lessons`)}>
          Create lesson
        </Button>
        <Button variant="mint" leadingIcon="quiz" onClick={() => nav(`/teacher/c/${classId}/quiz`)}>
          Build a quiz
        </Button>
        <Button variant="sun" leadingIcon="check" onClick={() => nav(`/teacher/c/${classId}/students`)}>
          Approve requests
        </Button>
      </div>

      <Toast open={copied} message="Code copied" tone="success" onClose={() => setCopied(false)} />
    </>
  );
}
