import { Link } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { E, I, type EmojiName } from "../../components/icons";
import { useAuth } from "../../hooks/useAuth";
import { fetchMyProgress, fetchRecentActivity } from "../../services/learning";

const TILES: { to: string; label: string; emoji: EmojiName }[] = [
  { to: "/student/lessons", label: "My Lessons", emoji: "lessons" },
  { to: "/student/assessments", label: "Assessment Center", emoji: "assessment" },
  { to: "/student/review", label: "Review Center", emoji: "review" },
  { to: "/student/progress", label: "Progress Tracker", emoji: "progress" },
  { to: "/student/account", label: "Account", emoji: "account" },
];

export default function StudentHome() {
  const { session } = useAuth();
  const uid = session?.user.id;
  const progress = useQuery({ queryKey: ["my-progress", uid], queryFn: () => fetchMyProgress(uid!), enabled: !!uid });
  const recent = useQuery({ queryKey: ["recent", uid], queryFn: () => fetchRecentActivity(uid!), enabled: !!uid });
  const pct = progress.data?.lessons_pct ?? 0;
  const r = 40;
  const circ = 2 * Math.PI * r;

  return (
    <>
      <div className="card hero-progress">
        <svg width="100" height="100" viewBox="0 0 100 100" aria-hidden="true">
          <circle cx="50" cy="50" r={r} fill="none" stroke="#1b2334" strokeWidth="10" />
          <circle
            cx="50" cy="50" r={r} fill="none" stroke="#4c8dff" strokeWidth="10" strokeLinecap="round"
            strokeDasharray={circ} strokeDashoffset={circ * (1 - Math.min(pct, 100) / 100)}
            transform="rotate(-90 50 50)"
          />
          <text x="50" y="56" textAnchor="middle" className="ring-pct">{Math.round(pct)}%</text>
        </svg>
        <div>
          <h3>Your Learning Progress</h3>
          <p className="empty-sm" style={{ textAlign: "left" }}>Average lesson completion</p>
        </div>
      </div>

      <h3>Quick Access</h3>
      <div className="tiles">
        {TILES.map((t) => (
          <Link key={t.to} to={t.to} className="tile">
            <E name={t.emoji} size={44} />
            {t.label}
          </Link>
        ))}
      </div>

      <h3>Recent Activity</h3>
      <div className="card">
        {recent.isLoading && <p className="empty">Loading…</p>}
        {recent.error && <p className="err">{String(recent.error)}</p>}
        {recent.data?.length === 0 && <p className="empty">No activity yet, open a lesson to get started.</p>}
        {recent.data?.map((r, i) => (
          <div key={i} className="perf">
            <span style={{ color: r.percent === 100 ? "#3ecf8e" : "#f5a623", display: "inline-flex" }}>
              <I name={r.percent === 100 ? "done" : "pending"} size={18} />
            </span>
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
