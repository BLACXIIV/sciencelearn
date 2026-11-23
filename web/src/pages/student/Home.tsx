import type { CSSProperties } from "react";
import { Link } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { useAuth } from "../../hooks/useAuth";
import { fetchMyProgress, fetchRecentActivity } from "../../services/learning";

const TILES = [
  { to: "/student/lessons", label: "My Lessons", color: "#2563eb", bg: "#dbeafe", glyph: "📖" },
  { to: "/student/assessments", label: "Assessment Center", color: "#0d9488", bg: "#ccfbf1", glyph: "✅" },
  { to: "/student/review", label: "Review Center", color: "#7c3aed", bg: "#ede9fe", glyph: "🃏" },
  { to: "/student/progress", label: "Progress Tracker", color: "#15803d", bg: "#dcfce7", glyph: "📈" },
  { to: "/student/account", label: "Account", color: "#3730a3", bg: "#e0e7ff", glyph: "👤" },
];

export default function StudentHome() {
  const { session } = useAuth();
  const uid = session?.user.id;
  const progress = useQuery({ queryKey: ["my-progress", uid], queryFn: () => fetchMyProgress(uid!), enabled: !!uid });
  const recent = useQuery({ queryKey: ["recent", uid], queryFn: () => fetchRecentActivity(uid!), enabled: !!uid });
  const pct = progress.data?.lessons_pct ?? 0;

  return (
    <>
      <div className="card hero-progress">
        <div>
          <h3>Your Learning Progress</h3>
          <strong className="big">{Math.round(pct)}%</strong>
          <div className="bar wide"><div style={{ width: `${Math.min(pct, 100)}%` }} /></div>
        </div>
        <span className="hero-icon">🏆</span>
      </div>

      <h3>Quick Access</h3>
      <div className="tiles">
        {TILES.map((t) => (
          <Link key={t.to} to={t.to} className="tile" style={{ "--tile-bg": t.bg } as CSSProperties}>
            <span className="glyph">{t.glyph}</span>
            {t.label}
          </Link>
        ))}
      </div>

      <h3>Recent Activity</h3>
      <div className="card">
        {recent.isLoading && <p className="empty">Loading…</p>}
        {recent.error && <p className="err">{String(recent.error)}</p>}
        {recent.data?.length === 0 && <p className="empty">No activity yet — open a lesson to get started.</p>}
        {recent.data?.map((r, i) => (
          <div key={i} className="perf">
            <span>{r.percent === 100 ? "✅" : "⏳"}</span>
            <span>
              {r.lessons?.title ?? "Lesson"}
              <br /><small>{r.percent === 100 ? "Completed" : "In progress"} · {r.percent}%</small>
            </span>
          </div>
        ))}
      </div>
    </>
  );
}
