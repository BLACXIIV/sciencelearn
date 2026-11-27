import { useQuery } from "@tanstack/react-query";
import {
  Badge, Card, EmptyState, ProgressBar, RingChart, StatCard,
} from "../../design-system";
import { useAuth } from "../../hooks/useAuth";
import {
  fetchMyProgress, fetchMyQuizScores, fetchPublishedLessons,
  fetchRecentActivity,
} from "../../services/learning";
import "./student.css";

/* Progress tracker — completed lessons, quiz scores and recent activity.
   (Pre/post gain was removed; overall = mean of lessons % + quiz avg.) */
export default function StudentProgress() {
  const { session } = useAuth();
  const uid = session?.user.id;
  const progress = useQuery({ queryKey: ["my-progress", uid], queryFn: () => fetchMyProgress(uid!), enabled: !!uid });
  const lessons = useQuery({ queryKey: ["my-lessons", uid], queryFn: () => fetchPublishedLessons(), enabled: !!uid });
  const scores = useQuery({ queryKey: ["my-quiz-scores", uid], queryFn: () => fetchMyQuizScores(uid!), enabled: !!uid });
  const recent = useQuery({ queryKey: ["my-recent", uid], queryFn: () => fetchRecentActivity(uid!), enabled: !!uid });

  if (progress.isLoading) return <p className="sd-dim">Loading progress…</p>;
  if (progress.error) return <p className="sd-err">{String(progress.error)}</p>;

  const p = progress.data;
  const lessonsPct = p?.lessons_pct ?? 0;
  const quizzesPct = p?.quizzes_pct ?? 0;
  const overall = (lessonsPct + quizzesPct) / 2;

  const lessonRows = lessons.data ?? [];
  const total = lessonRows.length;
  const done = lessonRows.filter((l) => ((l.lesson_progress?.[0]?.percent as number) ?? 0) >= 100).length;
  const donePct = total === 0 ? 0 : (done / total) * 100;
  const scoreRows = scores.data ?? [];
  const recentRows = recent.data ?? [];

  const rings: { label: string; pct: number; series: 1 | 2 | 4 }[] = [
    { label: "Lessons", pct: lessonsPct, series: 1 },
    { label: "Quizzes", pct: quizzesPct, series: 2 },
    { label: "Lessons done", pct: donePct, series: 4 },
  ];

  const breakdown = [
    { label: "Lessons completed", pct: lessonsPct, value: `${Math.round(lessonsPct)} / 100`, tone: "sun" as const },
    { label: "Quiz average", pct: quizzesPct, value: quizzesPct > 0 ? `${Math.round(quizzesPct)}%` : "-", tone: "blue" as const },
    { label: "Lessons done", pct: donePct, value: total === 0 ? "-" : `${done} of ${total}`, tone: "mint" as const },
  ];

  const empty = p == null && done === 0 && scoreRows.length === 0 && recentRows.length === 0;

  return (
    <div className="sd-stack">
      <h2 className="ds-h2">Progress tracker</h2>
      <StatCard icon="progress" value={`${Math.round(overall)}%`} label="Overall progress" />

      <Card>
        <div className="sd-rings">
          {rings.map((r) => (
            <div key={r.label} className="sd-ring-item">
              <RingChart
                size={64}
                slices={[
                  { value: r.pct, series: r.series },
                  { value: 100 - r.pct, series: 0 },
                ]}
              />
              <span className="ds-caption">{r.label}</span>
            </div>
          ))}
        </div>
      </Card>

      <Card>
        <h3 className="ds-title">Score breakdown</h3>
        {breakdown.map((b) => (
          <div key={b.label} className="sd-brow">
            <div className="sd-bar">
              <span className="ds-body-sm">{b.label}</span>
              <span className="ds-label">{b.value}</span>
            </div>
            <ProgressBar value={b.pct ?? 0} size="sm" tone={b.tone} />
          </div>
        ))}
      </Card>

      <Card>
        <h3 className="ds-title">Quiz scores</h3>
        {scoreRows.length === 0 && (
          <p className="ds-body-sm sd-dim">No quiz scores yet — take a quiz to see it here.</p>
        )}
        {scoreRows.map((s, i) => (
          <div key={i} className="sd-bar sd-brow">
            <span className="ds-body-sm">{s.assessments?.title ?? "Quiz"}</span>
            <Badge tone="mint">{Math.round(s.score)}%</Badge>
          </div>
        ))}
      </Card>

      <Card>
        <h3 className="ds-title">Recent activity</h3>
        {recentRows.length === 0 && (
          <p className="ds-body-sm sd-dim">Nothing yet — open a lesson to start tracking.</p>
        )}
        {recentRows.map((r, i) => (
          <div key={i} className="sd-brow">
            <div className="sd-bar">
              <span className="ds-body-sm">{r.lessons?.title ?? "Lesson"}</span>
              <span className="ds-label">{Math.round(r.percent ?? 0)}%</span>
            </div>
            <ProgressBar value={r.percent ?? 0} size="sm" tone="sun" />
          </div>
        ))}
      </Card>

      {empty && (
        <Card>
          <EmptyState icon="progress" title="No progress yet" body="Finish a lesson or quiz to start tracking." />
        </Card>
      )}
    </div>
  );
}
