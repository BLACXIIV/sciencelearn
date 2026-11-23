import { useState } from "react";
import { Link } from "react-router-dom";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { E, I, type EmojiName } from "../../components/icons";
import { useAuth } from "../../hooks/useAuth";
import { fetchEnrolledClasses, joinClass } from "../../services/classes";
import { fetchMyProgress, fetchRecentActivity } from "../../services/learning";

const TILES: { to: string; label: string; emoji: EmojiName }[] = [
  { to: "/student/classes", label: "My Classes", emoji: "school" },
  { to: "/student/assessments", label: "Assessment Center", emoji: "assessment" },
  { to: "/student/review", label: "Review Center", emoji: "review" },
  { to: "/student/progress", label: "Progress Tracker", emoji: "progress" },
  { to: "/student/account", label: "Account", emoji: "account" },
];

/** Join a class by code + see classes already joined. */
function MyClasses() {
  const qc = useQueryClient();
  const enrolled = useQuery({ queryKey: ["enrolled"], queryFn: fetchEnrolledClasses });
  const [code, setCode] = useState("");
  const [msg, setMsg] = useState<string | null>(null);
  const join = useMutation({
    mutationFn: () => joinClass(code),
    onSuccess: (r) => {
      setCode("");
      setMsg(r.status === "pending"
        ? `Request sent to ${r.name}, waiting for teacher approval`
        : `Joined ${r.name}`);
      qc.invalidateQueries({ queryKey: ["enrolled"] });
    },
    onError: (e) => setMsg(e instanceof Error ? e.message : String(e)),
  });

  return (
    <div className="card">
      <h3>My Classes</h3>
      <div className="row-actions" style={{ marginTop: 0 }}>
        <input className="text-answer" style={{ margin: 0, flex: 1, textTransform: "uppercase" }}
          placeholder="Enter class code" maxLength={8}
          value={code} onChange={(e) => setCode(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && code.trim() && join.mutate()} />
        <button disabled={join.isPending || !code.trim()} onClick={() => join.mutate()}>
          {join.isPending ? "Joining…" : "Join"}
        </button>
      </div>
      {msg && <p className={join.isError ? "err" : "empty-sm"} style={{ textAlign: "left" }}>{msg}</p>}
      {enrolled.isLoading && <p className="empty">Loading…</p>}
      {enrolled.data?.length === 0 && <p className="empty-sm" style={{ textAlign: "left" }}>Not in any class yet. Get a code from your teacher.</p>}
      {enrolled.data?.map((e) => (
        <div key={e.class_id} className="perf">
          <span className="avatar">{(e.classes?.name || "?")[0].toUpperCase()}</span>
          <span>{e.classes?.name}</span>
          {e.status === "pending" && <small className="kind" style={{ color: "#f5a524" }}>Pending</small>}
        </div>
      ))}
    </div>
  );
}

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

      <h3>My Classes</h3>
      <MyClasses />

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
