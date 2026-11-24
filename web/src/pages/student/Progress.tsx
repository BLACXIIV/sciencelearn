import { useQuery } from "@tanstack/react-query";
import {
  Card, EmptyState, ProgressBar, RingChart, StatCard, StickerBadge,
} from "../../design-system";
import { useAuth } from "../../hooks/useAuth";
import { fetchMyProgress } from "../../services/learning";
import "./student.css";

export default function StudentProgress() {
  const { session } = useAuth();
  const uid = session?.user.id;
  const progress = useQuery({ queryKey: ["my-progress", uid], queryFn: () => fetchMyProgress(uid!), enabled: !!uid });

  if (progress.isLoading) return <p className="sd-dim">Loading progress…</p>;
  if (progress.error) return <p className="sd-err">{String(progress.error)}</p>;

  const p = progress.data;
  const lessons = p?.lessons_pct ?? 0;
  const quizzes = p?.quizzes_pct ?? 0;
  const pre = p?.pre_score ?? null;
  const post = p?.post_score ?? null;
  const overall = (lessons + quizzes + (post ?? 0)) / 3;
  const gain = pre != null && post != null ? Math.round(post - pre) : null;

  const rings: { label: string; pct: number; series: 1 | 2 | 3 | 4 }[] = [
    { label: "Lessons", pct: lessons, series: 1 },
    { label: "Quizzes", pct: quizzes, series: 2 },
    { label: "Pre-test", pct: pre ?? 0, series: 3 },
    { label: "Post-test", pct: post ?? 0, series: 4 },
  ];

  const breakdown = [
    { label: "Lessons completed", pct: lessons, value: `${Math.round(lessons)} / 100`, tone: "sun" as const },
    { label: "Quiz average", pct: quizzes, value: quizzes > 0 ? `${Math.round(quizzes)}%` : "-", tone: "blue" as const },
    { label: "Pre-test", pct: pre, value: pre == null ? "-" : `${Math.round(pre)}%`, tone: "blue" as const },
    { label: "Post-test", pct: post, value: post == null ? "-" : `${Math.round(post)}%`, tone: "mint" as const },
  ];

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
        <span className="ds-caption">Gain = post-test − pre-test</span>
        <div className="sd-bar">
          <span className="ds-label">Pre-test</span>
          <span className="ds-label">{pre == null ? "-" : `${Math.round(pre)}%`}</span>
        </div>
        <ProgressBar value={pre ?? 0} />
        <div className="sd-bar">
          <span className="ds-label">Post-test</span>
          <span className="ds-label">{post == null ? "-" : `${Math.round(post)}%`}</span>
        </div>
        <ProgressBar value={post ?? 0} tone="mint" />
        {gain != null && (
          <div className="sd-gain">
            <StickerBadge rotation={-5}>{gain >= 0 ? "+" : ""}{gain}% gain</StickerBadge>
          </div>
        )}
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

      {p == null && (
        <Card>
          <EmptyState icon="progress" title="No progress yet" body="Finish a lesson or quiz to start tracking." />
        </Card>
      )}
    </div>
  );
}
