import { useState } from "react";
import { Navigate, useNavigate } from "react-router-dom";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  Avatar, Badge, Button, Card, CodeInput, EmptyState, Icon, ListItemCard, Modal, PageHeader,
  SegmentedControl, TextField, type IconName,
} from "../design-system";
import { useAuth } from "../hooks/useAuth";
import { signOut } from "../services/auth";
import { createClass, fetchAwaitingByClass, fetchEnrolledClasses, fetchMyClasses, joinClass, markClassPicked } from "../services/classes";
import "./select-classroom.css";

/** Pastel subject tiles — color cycles by list position, like the mockup. */
const TILES: { pastel: "b" | "m" | "y" | "p"; icon: IconName }[] = [
  { pastel: "b", icon: "science" },
  { pastel: "m", icon: "atom" },
  { pastel: "y", icon: "university" },
  { pastel: "p", icon: "puzzle" },
];
const tile = (i: number) => TILES[i % TILES.length];

/** Post-login gate: signed-in users land here and pick a classroom to open.
 *  It's a session landing step — portal tabs stay cross-class. */
export default function SelectClassroom() {
  const { session, profile, loading } = useAuth();

  if (loading) return <p className="ds-body sc-load">Loading…</p>;
  if (!session) return <Navigate to="/login" replace />;
  if (!profile)
    return <p className="ds-body sc-load">Couldn't load your profile. Check your connection and refresh.</p>;

  const student = profile.role === "student";
  return (
    <div className="sc">
      <main className="sc-col sc-body">
        <div className="sc-hero edge-6">
          <PageHeader compact>
            <div className="sc-head">
              <div className="sc-who">
                <Avatar name={profile.full_name} size={46} pastelColor="mint" />
                <div className="sc-grow">
                  <p className="ds-title sc-name">Hi, {profile.full_name}</p>
                  <p className="ds-caption sc-role">{session.user.email}</p>
                </div>
                <span className="sc-chip edge-3"><Badge tone="sun">{student ? "Student" : "Teacher"}</Badge></span>
              </div>
              <h1 className="sc-h1">Choose your classroom</h1>
              <p className="ds-body-sm sc-sub">
                {student
                  ? "Pick a class to continue to your lessons and quizzes."
                  : "Pick a class to open its lessons, quizzes and reports."}
              </p>
            </div>
          </PageHeader>
        </div>
        {student ? <StudentPick /> : <TeacherPick />}
      </main>
    </div>
  );
}

/** Sticky Continue + account escape, shown under both variants. */
function Foot({ sel, onGo }: { sel: string | null; onGo: () => void }) {
  return (
    <div className="sc-foot">
      <Button fullWidth disabled={sel == null} onClick={onGo}>Continue</Button>
      <p className="ds-body-sm sc-alt">
        Not your account?{" "}
        <button type="button" className="sc-signout" onClick={() => signOut()}>Switch user</button>
      </p>
    </div>
  );
}

function StudentPick() {
  const qc = useQueryClient();
  const nav = useNavigate();
  const classes = useQuery({ queryKey: ["enrolled-classes"], queryFn: fetchEnrolledClasses });
  const awaiting = useQuery({ queryKey: ["awaiting-by-class"], queryFn: fetchAwaitingByClass });
  const [sel, setSel] = useState<string | null>(null);
  const [joinOpen, setJoinOpen] = useState(false);
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
      <div className="sc-stack">
        {classes.isLoading && <Card><p className="sc-dim">Loading classes…</p></Card>}
        {classes.error != null && <Card><p className="sc-err">{String(classes.error)}</p></Card>}
        {classes.data?.length === 0 && (
          <Card>
            <EmptyState icon="school" title="No classes yet" body="Get a class code from your teacher." />
          </Card>
        )}
        {classes.data?.map((e, i) =>
          e.status === "active" ? (
            <div key={e.class_id} className={`sc-pick${sel === e.class_id ? " sel" : ""}`}>
              <ListItemCard
                onClick={() => setSel(e.class_id)}
                leading={
                  <span className={`sc-tile ${tile(i).pastel}`}>
                    <Icon name={tile(i).icon} size={26} />
                  </span>
                }
                title={e.classes?.name ?? "Class"}
                subtitle={
                  <span className="sc-meta">
                    {e.classes?.profiles?.full_name && (
                      <span className="sc-teacher">{e.classes.profiles.full_name}</span>
                    )}
                    <span className="sc-chips">
                      <span className="sc-mchip">
                        <Icon name="students" size={12} />
                        {(e.classes?.enrollments ?? []).filter((x) => x.status === "active").length}
                      </span>
                      {e.classes?.code && <span className="sc-mchip sc-tag">{e.classes.code}</span>}
                      {(awaiting.data?.[e.class_id] ?? 0) > 0 && (
                        <span className="sc-mchip sun">
                          <Icon name="assessment" size={12} />
                          {awaiting.data![e.class_id]} to do
                        </span>
                      )}
                    </span>
                  </span>
                }
                trailing={<Icon name="chevron" size={20} color="var(--ds-muted)" />}
              />
              {sel === e.class_id && (
                <span className="sc-check"><Icon name="check" size={15} /></span>
              )}
            </div>
          ) : (
            <ListItemCard
              key={e.class_id}
              pending
              leading={
                <span className="sc-tile p">
                  <Icon name="pending" size={24} />
                </span>
              }
              title={e.classes?.name ?? "Class"}
              subtitle="Waiting for teacher approval"
              trailing={<Badge tone="sun">Pending</Badge>}
            />
          ),
        )}
        <div className="sc-ghost">
          <button type="button" className="sc-ghost-head" onClick={() => setJoinOpen((v) => !v)}>
            <span className="sc-plus"><Icon name="add" size={15} /></span>
            <span className="sc-grow">
              <span className="sc-ghost-title">Join with a class code</span>
              <span className="sc-ghost-sub">Get the 6-letter code from your teacher</span>
            </span>
            <Icon name="chevron" size={20} color="var(--ds-muted)" />
          </button>
          {joinOpen && (
            <>
              <div className="sc-row">
                <div className="sc-grow">
                  <CodeInput value={code} onChange={setCode} disabled={join.isPending} />
                </div>
                <Button loading={join.isPending} disabled={join.isPending || !code.trim()} onClick={() => join.mutate()}>
                  Join
                </Button>
              </div>
              {msg && <p className={msg.err ? "sc-err" : "sc-ok"}>{msg.text}</p>}
            </>
          )}
        </div>
      </div>
      <Foot sel={sel} onGo={() => { markClassPicked(sel ?? undefined); nav(`/student/classes/${sel}`); }} />
    </>
  );
}

function TeacherPick() {
  const nav = useNavigate();
  const qc = useQueryClient();
  const classes = useQuery({ queryKey: ["my-classes"], queryFn: fetchMyClasses });
  const [sel, setSel] = useState<string | null>(null);
  const [createOpen, setCreateOpen] = useState(false);
  const [name, setName] = useState("");
  const [policy, setPolicy] = useState<"open" | "approval">("open");

  /** Create stays inside the picker: on success the new class lands in the
   *  list already selected, so Continue opens it right away. */
  const create = useMutation({
    mutationFn: () => createClass(name.trim(), policy),
    onSuccess: (c) => {
      setCreateOpen(false);
      setName("");
      qc.invalidateQueries({ queryKey: ["my-classes"] });
      setSel(c.id);
    },
  });

  return (
    <>
      <div className="sc-stack">
        {classes.isLoading && <Card><p className="sc-dim">Loading classes…</p></Card>}
        {classes.error != null && <Card><p className="sc-err">{String(classes.error)}</p></Card>}
        {classes.data?.length === 0 && (
          <Card>
            <EmptyState
              icon="school"
              title="No classes yet"
              body="Create one and share its join code with students."
              action={<Button onClick={() => setCreateOpen(true)}>Create a class</Button>}
            />
          </Card>
        )}
        {classes.data?.map((c, i) => {
          const enr = c.enrollments ?? [];
          const active = enr.filter((x) => x.status === "active").length;
          const pending = enr.filter((x) => x.status === "pending").length;
          return (
            <div key={c.id} className={`sc-pick${sel === c.id ? " sel" : ""}`}>
              <ListItemCard
                onClick={() => setSel(c.id)}
                leading={
                  <span className={`sc-tile ${tile(i).pastel}`}>
                    <Icon name={tile(i).icon} size={26} />
                  </span>
                }
                title={c.name}
                subtitle={
                  <span className="sc-chips">
                    <span className="sc-mchip">
                      <Icon name="students" size={12} />
                      {active} student{active === 1 ? "" : "s"}
                    </span>
                    {c.code && <span className="sc-mchip sc-tag">{c.code}</span>}
                    {pending > 0 && (
                      <span className="sc-mchip sun">
                        <Icon name="pending" size={12} />
                        {pending} request{pending === 1 ? "" : "s"}
                      </span>
                    )}
                  </span>
                }
                trailing={<Icon name="chevron" size={20} color="var(--ds-muted)" />}
              />
              {sel === c.id && (
                <span className="sc-check"><Icon name="check" size={15} /></span>
              )}
            </div>
          );
        })}
        {(classes.data?.length ?? 0) > 0 && (
          <button type="button" className="sc-ghost" onClick={() => setCreateOpen(true)}>
            <span className="sc-plus"><Icon name="add" size={15} /></span>
            <span className="sc-grow">
              <span className="sc-ghost-title">Create a new class</span>
              <span className="sc-ghost-sub">Get a join code to share with students</span>
            </span>
            <Icon name="chevron" size={20} color="var(--ds-muted)" />
          </button>
        )}
      </div>
      <Foot sel={sel} onGo={() => { markClassPicked(sel ?? undefined); nav(`/teacher/c/${sel}`); }} />

      <Modal open={createOpen} onClose={() => setCreateOpen(false)} title="Create a class">
        <div className="sc-create">
          <TextField
            label="Class name" placeholder="e.g. Grade 7 - Diamond" value={name}
            onChange={(e) => setName(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && name.trim() && create.mutate()}
          />
          <SegmentedControl
            ariaLabel="How do students join?"
            options={[
              { value: "open", label: "Instant" },
              { value: "approval", label: "Approval" },
            ]}
            value={policy}
            onChange={(v) => setPolicy(v as "open" | "approval")}
          />
          <p className="ds-caption sc-dim">
            {policy === "open"
              ? "Anyone with the code joins immediately."
              : "You confirm each request before they see class content."}
          </p>
          {create.error != null && <p className="sc-err">{String(create.error)}</p>}
          <Button fullWidth loading={create.isPending} disabled={create.isPending || !name.trim()}
            onClick={() => create.mutate()}>
            Create class
          </Button>
        </div>
      </Modal>
    </>
  );
}
