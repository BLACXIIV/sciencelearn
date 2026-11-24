import { Outlet, useLocation, useNavigate } from "react-router-dom";
import TopNav from "./TopNav";
import { Icon, NavBar, type IconName } from "../design-system";
import { useAuth } from "../hooks/useAuth";
import { signOut } from "../services/auth";
import "./shell.css";

const STUDENT_NAV: { to: string; label: string; icon: IconName; end: boolean }[] = [
  { to: "/student", label: "Home", icon: "home", end: true },
  { to: "/student/classes", label: "My Classes", icon: "students", end: false },
  { to: "/student/assessments", label: "Assessment Center", icon: "assessment", end: false },
  { to: "/student/review", label: "Review Center", icon: "review", end: false },
  { to: "/student/progress", label: "Progress Tracker", icon: "progress", end: false },
  { to: "/student/account", label: "Account", icon: "account", end: false },
];

/** Student shell: same DS NavBar rail as the staff portal, student destinations. */
export default function StudentLayout() {
  const { profile } = useAuth();
  const nav = useNavigate();
  const path = useLocation().pathname;
  const active = [...STUDENT_NAV]
    .sort((a, b) => b.to.length - a.to.length)
    .find((i) => i.end ? path === i.to : path === i.to || path.startsWith(`${i.to}/`))?.to;

  return (
    <div className="sh">
      <NavBar
        brand={<div className="sh-brand"><img src="/logo.png" alt="" /><span>ScienceLearn</span></div>}
        items={STUDENT_NAV.map((i) => ({ key: i.to, label: i.label, icon: i.icon }))}
        active={active}
        onSelect={(key) => nav(key)}
        footer={
          <button type="button" className="ds-nav-item" onClick={signOut}>
            <Icon name="signOut" size={20} />
            <span className="ds-nav-label">Sign out</span>
          </button>
        }
      />
      <main className="sh-main">
        <TopNav />
        <header className="sh-head">
          <div><h1 className="ds-h2">Welcome, {profile?.full_name}!</h1><p className="ds-body-sm sh-dim">Keep learning, keep growing!</p></div>
        </header>
        <Outlet />
      </main>
    </div>
  );
}
