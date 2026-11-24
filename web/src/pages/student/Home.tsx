import { useState } from "react";
import { Link } from "react-router-dom";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  Avatar, Badge, Button, Card, CodeInput, Icon, RingChart, type CardPastel, type IconName,
} from "../../design-system";
import { useAuth } from "../../hooks/useAuth";
import { fetchEnrolledClasses, joinClass } from "../../services/classes";
import { fetchMyProgress, fetchRecentActivity } from "../../services/learning";
import "./student.css";

const TILES: { to: string; label: string; icon: IconName; pastel: CardPastel }[] = [
  { to: "/student/classes", label: "My Classes", icon: "school", pastel: "blue" },
  { to: "/student/assessments", label: "Assessment Center", icon: "assessment", pastel: "yellow" },
  { to: "/student/review", label: "Review Center", icon: "review", pastel: "purple" },
  { to: "/student/progress", label: "Progress Tracker", icon: "progress", pastel: "mint" },
  { to: "/student/account", label: "Account", icon: "account", pastel: "blue" },
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
    <Card>
      <h3 className="ds-title">My Classes</h3>
      <div className="sd-row">
        <div className="sd-rowbody">
          <CodeInput value={code} onChange={setCode} disabled={join.isPending} />
        </div>
        <Button loading={join.isPending} disabled={join.isPending || !code.trim()} onClick={() => join.mutate()}>
          Join
        </Button>
      </div>
      {msg && <p className={join.isError ? "sd-err" : "sd-ok"}>{msg}</p>}
      {enrolled.isLoading && <p className="sd-dim">Loading…</p>}
      {enrolled.data?.length === 0 && <p className="sd-dim">Not in any class yet. Get a code from your teacher.</p>}
      {enrolled.data?.map((e) => (
        <div key={e.class_id} className="sd-row">
          <Avatar name={e.classes?.name ?? "?"} size={32} />
          <span className="sd-rowbody">{e.classes?.name}</span>
          {e.status === "pending" && <Badge tone="sun">Pending</Badge>}
        </div>
      ))}
    </Card>
  );
}

export default function StudentHome() {
  const { session } = useAuth();
  const uid = session?.user.id;
  const progress = useQuery({ queryKey: ["my-progress", uid], queryFn: () => fetchMyProgress(uid!), enabled: !!uid });
  const recent = useQuery({ queryKey: ["recent", uid], queryFn: () => fetchRecentActivity(uid!), enabled: !!uid });
  const pct = progress.data?.lessons_pct ?? 0;

  return (
    <div className="sd-stack">
      <Card>
        <div className="sd-row">
          <RingChart size={100} thickness={10} slices={[
            { value: pct, series: 1 },
            { value: 100 - pct, series: 0 },
          ]}>
            <span className="ds-h3">{Math.round(pct)}%</span>
          </RingChart>
          <div className="sd-rowbody">
            <h3 className="ds-title">Your Learning Progress</h3>
            <p className="ds-body-sm">Average lesson completion</p>
          </div>
        </div>
      </Card>

      <h3 className="ds-h3">Quick Access</h3>
      <div className="sd-tiles">
        {TILES.map((t) => (
          <Link key={t.to} to={t.to} className="sd-cardlink">
            <Card variant="pastel" pastelColor={t.pastel} tilt>
              <span className="sd-tile">
                <Icon name={t.icon} size={36} />
                <span className="ds-label">{t.label}</span>
              </span>
            </Card>
          </Link>
        ))}
      </div>

      <h3 className="ds-h3">My Classes</h3>
      <MyClasses />

      <h3 className="ds-h3">Recent Activity</h3>
      <Card>
        {recent.isLoading && <p className="sd-dim">Loading…</p>}
        {recent.error && <p className="sd-err">{String(recent.error)}</p>}
        {recent.data?.length === 0 && <p className="sd-dim">No activity yet, open a lesson to get started.</p>}
        {recent.data?.map((r, i) => (
          <div key={i} className="sd-row">
            <Icon
              name={r.percent === 100 ? "done" : "pending"}
              size={18}
              color={r.percent === 100 ? "var(--ds-success)" : "var(--ds-sun)"}
            />
            <span className="sd-rowbody">
              {r.lessons?.title ?? "Lesson"}
              <small className="ds-caption">{r.percent === 100 ? "Completed" : "In progress"} · {r.percent}%</small>
            </span>
          </div>
        ))}
      </Card>
    </div>
  );
}
