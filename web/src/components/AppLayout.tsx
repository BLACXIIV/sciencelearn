import { useQuery } from "@tanstack/react-query";
import { Outlet, useLocation, useMatch, useNavigate } from "react-router-dom";
import TopNav from "./TopNav";
import { Button, Chip, Icon, NavBar, type IconName } from "../design-system";
import { useAuth } from "../hooks/useAuth";
import { signOut } from "../services/auth";
import { fetchClass } from "../services/classes";
import "./shell.css";

/** Staff shell: DS NavBar rail + top bar + routed content. Inside
 *  /teacher/c/:classId the rail becomes that class's portal (4 tabs). */
export default function AppLayout() {
  const { profile } = useAuth();
  const nav = useNavigate();
  const path = useLocation().pathname;
  const classId = useMatch("/teacher/c/:classId/*")?.params.classId ?? null;
  const cls = useQuery({
    queryKey: ["class", classId],
    queryFn: () => fetchClass(classId!),
    enabled: !!classId,
  });

  const items: { to: string; label: string; icon: IconName; end: boolean }[] = classId
    ? [
        { to: `/teacher/c/${classId}`, label: "Dashboard", icon: "dashboard", end: true },
        { to: `/teacher/c/${classId}/lessons`, label: "Lessons", icon: "lessons", end: false },
        { to: `/teacher/c/${classId}/quiz`, label: "Create Quiz", icon: "quiz", end: false },
        { to: `/teacher/c/${classId}/students`, label: "Students", icon: "students", end: false },
      ]
    : [];
  if (profile?.role === "admin")
    items.push({ to: "/teacher/users", label: "Users", icon: "userAdmin", end: false });

  // Same match semantics as NavLink: exact for `end`, prefix otherwise.
  const active = [...items]
    .sort((a, b) => b.to.length - a.to.length)
    .find((i) => i.end ? path === i.to : path === i.to || path.startsWith(`${i.to}/`))?.to;

  return (
    <div className="sh">
      <NavBar
        brand={<div className="sh-brand"><img src="/logo.png" alt="" /><span>ScienceLearn</span></div>}
        items={items.map((i) => ({ key: i.to, label: i.label, icon: i.icon }))}
        active={active}
        onSelect={(key) => nav(key)}
        footer={
          <>
            <button type="button" className="ds-nav-item" onClick={() => nav("/select-classroom")}>
              <Icon name="school" size={20} />
              <span className="ds-nav-label">Switch class</span>
            </button>
            <button type="button" className="ds-nav-item" onClick={signOut}>
              <Icon name="signOut" size={20} />
              <span className="ds-nav-label">Sign out</span>
            </button>
          </>
        }
      />
      <main className="sh-main">
        <TopNav />
        <header className="sh-head">
          {cls.data ? (
            <div className="sh-spread">
              <div>
                <h1 className="ds-h2">{cls.data.name}</h1>
                <p className="ds-body-sm sh-dim">
                  {cls.data.join_policy === "approval" ? "Approval required" : "Instant join"}
                </p>
              </div>
              <div className="sh-actions">
                <Chip><span className="sh-code">{cls.data.code}</span></Chip>
                <Button variant="outline" size="sm" leadingIcon="school"
                  onClick={() => nav("/select-classroom")}>
                  Switch class
                </Button>
              </div>
            </div>
          ) : (
            <div><h1 className="ds-h2">Good Day, {profile?.full_name}!</h1><p className="ds-body-sm sh-dim">Manage. Monitor. Support.</p></div>
          )}
        </header>
        <Outlet />
      </main>
    </div>
  );
}
