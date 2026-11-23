import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Link } from "react-router-dom";
import { fetchEnrolledClasses, joinClass } from "../../services/classes";
import { I } from "../../components/icons";

/** Student class list: join by code + enrolled classes with pending/active status. */
export default function StudentClasses() {
  const qc = useQueryClient();
  const classes = useQuery({ queryKey: ["enrolled-classes"], queryFn: fetchEnrolledClasses });
  const [code, setCode] = useState("");
  const [msg, setMsg] = useState<{ text: string; err: boolean } | null>(null);

  const join = useMutation({
    mutationFn: () => joinClass(code.trim()),
    onSuccess: (r) => {
      setCode("");
      setMsg({
        err: false,
        text: r.status === "pending"
          ? `Request sent to ${r.name}, waiting for teacher approval`
          : `Joined ${r.name}`,
      });
      qc.invalidateQueries({ queryKey: ["enrolled-classes"] });
    },
    onError: (e) => setMsg({ err: true, text: String(e).replace("Error: ", "") }),
  });

  return (
    <>
      <div className="card">
        <h3>Join a class</h3>
        <div className="row-actions" style={{ marginTop: 0 }}>
          <input className="text-answer" style={{ margin: 0, flex: 1, textTransform: "uppercase" }}
            placeholder="Enter class code" value={code}
            onChange={(e) => setCode(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && code.trim() && join.mutate()} />
          <button disabled={join.isPending || !code.trim()} onClick={() => join.mutate()}>
            {join.isPending ? "Joining…" : "Join"}
          </button>
        </div>
        {msg && <p className={msg.err ? "err" : "empty"} style={{ textAlign: "left", padding: 0 }}>{msg.text}</p>}
      </div>

      {classes.isLoading && <p className="empty">Loading classes…</p>}
      {classes.error && <p className="err">{String(classes.error)}</p>}
      {classes.data?.length === 0 && (
        <div className="card"><p className="empty">No classes yet. Get a class code from your teacher.</p></div>
      )}
      {classes.data?.map((e) =>
        e.status === "active" ? (
          <Link key={e.class_id} to={`/student/classes/${e.class_id}`} className="card lesson-row">
            <span className="lesson-ico"><I name="school" size={22} /></span>
            <span className="lesson-body"><strong>{e.classes?.name ?? "Class"}</strong></span>
            <span className="chev"><I name="chevron" size={20} /></span>
          </Link>
        ) : (
          <div key={e.class_id} className="card lesson-row" style={{ cursor: "default" }}>
            <span className="lesson-ico"><I name="pending" size={22} /></span>
            <span className="lesson-body">
              <strong>{e.classes?.name ?? "Class"}</strong>
              <small>Waiting for teacher approval</small>
            </span>
            <span className="kind" style={{ color: "#f5a524" }}>Pending</span>
          </div>
        ),
      )}
    </>
  );
}
