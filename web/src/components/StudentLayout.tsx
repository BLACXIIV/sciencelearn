import { NavLink, Outlet } from "react-router-dom";
import { useAuth } from "../hooks/useAuth";
import { signOut } from "../services/auth";

const STUDENT_NAV = [
  { to: "/student", label: "Home", end: true },
  { to: "/student/lessons", label: "My Lessons", end: false },
  { to: "/student/assessments", label: "Assessment Center", end: false },
  { to: "/student/review", label: "Review Center", end: false },
  { to: "/student/progress", label: "Progress Tracker", end: false },
  { to: "/student/account", label: "Account", end: false },
];

/** Student shell: same sidebar layout as the staff portal, student destinations. */
export default function StudentLayout() {
  const { profile } = useAuth();
  return (
    <div className="shell">
      <aside>
        <h2><span className="brand-mark">⚛</span>ScienceLearn</h2>
        <nav>
          {STUDENT_NAV.map((item) => (
            <NavLink key={item.to} to={item.to} end={item.end}>{item.label}</NavLink>
          ))}
        </nav>
        <button type="button" className="nav-action" onClick={signOut}>Sign out</button>
      </aside>
      <main>
        <header><h1>Welcome, {profile?.full_name}!</h1><p>Keep learning, keep growing!</p></header>
        <Outlet />
      </main>
    </div>
  );
}
