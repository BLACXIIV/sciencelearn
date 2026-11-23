import { useQuery } from "@tanstack/react-query";
import { useAuth } from "../../hooks/useAuth";
import Ring from "../../components/Ring";
import { fetchMyProgress } from "../../services/learning";

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

  const rings = [
    { label: "Lessons", pct: lessons, color: "#f5c518" },
    { label: "Quizzes", pct: quizzes, color: "#4c8dff" },
    { label: "Pre-Test", pct: pre ?? 0, color: "#f0759c" },
    { label: "Post-Test", pct: post ?? 0, color: "#2ed3b7" },
  ];

  return (
    <>
      <h2 style={{ marginBottom: 0 }}>Overall Progress</h2>
      <strong className="big-num">{Math.round(overall)}%</strong>
      <div className="card rings-row" style={{ marginTop: 12 }}>
        {rings.map((r) => (
          <div key={r.label} className="ring-item">
            <Ring pct={r.pct} color={r.color} />
            <small className="ring-label" style={{ fill: "none" }}>{r.label}</small>
          </div>
        ))}
      </div>

      <h3>Score breakdown</h3>
      <div className="card">
        <div className="brow">
          <i className="b-dot" style={{ background: "#f5c518" }} />
          <span className="b-pct">{Math.round(lessons)}%</span>
          <span className="b-label">Lessons completed</span>
          <span className="b-val">{Math.round(lessons)} / 100</span>
        </div>
        <div className="brow">
          <i className="b-dot" style={{ background: "#4c8dff" }} />
          <span className="b-pct">{Math.round(quizzes)}%</span>
          <span className="b-label">Quiz average</span>
          <span className="b-val">{quizzes > 0 ? Math.round(quizzes) : "-"}</span>
        </div>
        <div className="brow">
          <i className="b-dot" style={{ background: "#f0759c" }} />
          <span className="b-pct">{pre == null ? "-" : `${Math.round(pre)}%`}</span>
          <span className="b-label">Pre-Test</span>
          <span className="b-val">{pre == null ? "-" : Math.round(pre)}</span>
        </div>
        <div className="brow">
          <i className="b-dot" style={{ background: "#2ed3b7" }} />
          <span className="b-pct">{post == null ? "-" : `${Math.round(post)}%`}</span>
          <span className="b-label">Post-Test</span>
          <span className="b-val">{post == null ? "-" : Math.round(post)}</span>
        </div>
        {gain != null && (
          <div className="brow">
            <i className="b-dot" style={{ background: "#3ecf8e" }} />
            <span className="b-pct" />
            <span className="b-label">Learning gain</span>
            <span className="b-val" style={{ color: "#3ecf8e" }}>{gain >= 0 ? "+" : ""}{gain}%</span>
          </div>
        )}
      </div>
    </>
  );
}
