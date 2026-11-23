import { NavLink, Outlet } from "react-router-dom";
import { useAuth } from "../hooks/useAuth";
import { signOut } from "../services/auth";

// Add entries here to extend the sidebar — no layout changes needed.
const NAV_ITEMS = [
  { to: "/teacher", label: "Dashboard", end: true },
  { to: "/teacher/lessons", label: "Manage Lessons", end: false },
];

/** Staff shell: sidebar nav + header + routed content. Rendered inside RequireTeacher. */
export default function AppLayout() {
  const { profile } = useAuth();
  const items = profile?.role === "admin"
    ? [...NAV_ITEMS, { to: "/teacher/users", label: "Users", end: false }]
    : NAV_ITEMS;
  return (
    <div className="shell">
      <aside>
        <h2><span className="brand-mark">⚛</span>ScienceLearn</h2>
        <nav>
          {items.map((item) => (
            <NavLink key={item.to} to={item.to} end={item.end}>{item.label}</NavLink>
          ))}
        </nav>
        <button type="button" className="nav-action" onClick={signOut}>Sign out</button>
      </aside>
      <main>
        <header><h1>Good Day, {profile?.full_name}!</h1><p>Manage. Monitor. Support.</p></header>
        <Outlet />
      </main>
    </div>
  );
}
