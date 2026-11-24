import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Link } from "react-router-dom";
import { Badge, Button, Card, CodeInput, EmptyState, Icon } from "../../design-system";
import { fetchEnrolledClasses, joinClass } from "../../services/classes";
import "./student.css";

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
    <div className="sd-stack">
      <Card>
        <h3 className="ds-title">Join a class</h3>
        <div className="sd-row">
          <div className="sd-rowbody">
            <CodeInput value={code} onChange={setCode} disabled={join.isPending} />
          </div>
          <Button loading={join.isPending} disabled={join.isPending || !code.trim()} onClick={() => join.mutate()}>
            Join
          </Button>
        </div>
        {msg && <p className={msg.err ? "sd-err" : "sd-ok"}>{msg.text}</p>}
      </Card>

      {classes.isLoading && <p className="sd-dim">Loading classes…</p>}
      {classes.error && <p className="sd-err">{String(classes.error)}</p>}
      {classes.data?.length === 0 && (
        <Card>
          <EmptyState icon="school" title="No classes yet" body="Get a class code from your teacher." />
        </Card>
      )}
      {classes.data?.map((e) =>
        e.status === "active" ? (
          <Link key={e.class_id} to={`/student/classes/${e.class_id}`} className="sd-cardlink">
            <Card>
              <span className="sd-row">
                <Icon name="school" size={22} color="var(--ds-blue)" />
                <span className="sd-rowbody"><strong>{e.classes?.name ?? "Class"}</strong></span>
                <Icon name="chevron" size={20} color="var(--ds-muted)" />
              </span>
            </Card>
          </Link>
        ) : (
          <Card key={e.class_id}>
            <span className="sd-row">
              <Icon name="pending" size={22} color="var(--ds-muted)" />
              <span className="sd-rowbody">
                <strong>{e.classes?.name ?? "Class"}</strong>
                <small className="ds-caption">Waiting for teacher approval</small>
              </span>
              <Badge tone="sun">Pending</Badge>
            </span>
          </Card>
        ),
      )}
    </div>
  );
}
