import { NavLink, Outlet } from "react-router-dom";
import Avatar from "./Avatar";
import { I, type IconName } from "./icons";
import { useAuth } from "../hooks/useAuth";
import { signOut } from "../services/auth";

const STUDENT_NAV: { to: string; label: string; icon: IconName; end: boolean }[] = [
  { to: "/student", label: "Home", icon: "home", end: true },
  { to: "/student/lessons", label: "My Lessons", icon: "lessons", end: false },
  { to: "/student/assessments", label: "Assessment Center", icon: "assessment", end: false },
  { to: "/student/review", label: "Review Center", icon: "review", end: false },
  { to: "/student/progress", label: "Progress Tracker", icon: "progress", end: false },
  { to: "/student/account", label: "Account", icon: "account", end: false },
];

/** Student shell: same sidebar layout as the staff portal, student destinations. */
export default function StudentLayout() {
  const { profile } = useAuth();
  return (
    <div className="shell">
      <aside>
        <h2><span className="brand-mark"><I name="atom" size={22} /></span>ScienceLearn</h2>
        <nav>
          {STUDENT_NAV.map((item) => (
            <NavLink key={item.to} to={item.to} end={item.end}>
              <I name={item.icon} size={18} />{item.label}
            </NavLink>
          ))}
        </nav>
        <button type="button" className="nav-action" onClick={signOut}><I name="signOut" size={18} />Sign out</button>
      </aside>
      <main>
        <header className="page-head">
          <Avatar name={profile?.full_name ?? ""} avatarKey={profile?.avatar_url ?? null} size={44} />
          <div><h1>Welcome, {profile?.full_name}!</h1><p>Keep learning, keep growing!</p></div>
        </header>
        <Outlet />
      </main>
    </div>
  );
}
