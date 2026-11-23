import { useQuery } from "@tanstack/react-query";
import { useAuth } from "../../hooks/useAuth";
import { fetchMyProgress } from "../../services/learning";

function Ring({ pct }: { pct: number }) {
  const r = 52;
  const circ = 2 * Math.PI * r;
  return (
    <svg width="130" height="130" viewBox="0 0 130 130" className="ring">
      <circle cx="65" cy="65" r={r} fill="none" stroke="#e2e8f0" strokeWidth="12" />
      <circle
        cx="65" cy="65" r={r} fill="none" stroke="#15803d" strokeWidth="12" strokeLinecap="round"
        strokeDasharray={circ} strokeDashoffset={circ * (1 - Math.min(pct, 100) / 100)}
        transform="rotate(-90 65 65)"
      />
      <text x="65" y="62" textAnchor="middle" className="ring-pct">{Math.round(pct)}%</text>
      <text x="65" y="80" textAnchor="middle" className="ring-label">Overall</text>
    </svg>
  );
}

export default function StudentProgress() {
  const { session } = useAuth();
  const uid = session?.user.id;
  const progress = useQuery({ queryKey: ["my-progress", uid], queryFn: () => fetchMyProgress(uid!), enabled: !!uid });

  if (progress.isLoading) return <p>Loading progress…</p>;
  if (progress.error) return <p className="err">{String(progress.error)}</p>;

  const p = progress.data;
  const lessons = p?.lessons_pct ?? 0;
  const quizzes = p?.quizzes_pct ?? 0;
  const pre = p?.pre_score ?? null;
  const post = p?.post_score ?? null;
  const overall = (lessons + quizzes + (post ?? 0)) / 3;
  const gain = pre != null && post != null ? Math.round(post - pre) : null;

  return (
    <>
      <div className="card ring-wrap">
        <Ring pct={overall} />
        <div className="prow-list">
          <div className="prow"><span><i className="legend-dot" style={{ background: "#15803d" }} />Lessons</span><strong>{Math.round(lessons)}%</strong></div>
          <div className="prow"><span><i className="legend-dot" style={{ background: "#2563eb" }} />Quizzes</span><strong>{Math.round(quizzes)}%</strong></div>
          <div className="prow"><span><i className="legend-dot" style={{ background: "#d97706" }} />Post-Test</span><strong>{post == null ? "–" : `${Math.round(post)}%`}</strong></div>
        </div>
      </div>

      <div className="card">
        <h3>Assessment Results</h3>
        <div className="cols">
          <div className="col">
            <small>{Math.round(pre ?? 0)}%</small>
            <div className="bar-v" style={{ height: `${Math.max(pre ?? 0, 2)}%`, background: "#2563eb" }} />
            <small>Pre-Test</small>
          </div>
          <div className="col">
            <small>{Math.round(post ?? 0)}%</small>
            <div className="bar-v" style={{ height: `${Math.max(post ?? 0, 2)}%`, background: "#15803d" }} />
            <small>Post-Test</small>
          </div>
          {gain != null && <strong className="gain">{gain >= 0 ? "+" : ""}{gain}% Gain</strong>}
        </div>
      </div>
    </>
  );
}
