import { NavLink, Outlet } from "react-router-dom";
import { useAuth } from "../hooks/useAuth";
import { signOut } from "../services/auth";

// Add entries here to extend the sidebar — no layout changes needed.
const NAV_ITEMS = [
  { to: "/", label: "Dashboard", end: true },
  { to: "/lessons", label: "Manage Lessons", end: false },
];

/** Authenticated shell: sidebar nav + header + routed content. Rendered inside RequireTeacher. */
export default function AppLayout() {
  const { profile } = useAuth();
  return (
    <div className="shell">
      <aside>
        <h2>ScienceLearn</h2>
        <nav>
          {NAV_ITEMS.map((item) => (
            <NavLink key={item.to} to={item.to} end={item.end}>{item.label}</NavLink>
          ))}
          <a href="#" onClick={(e) => { e.preventDefault(); signOut(); }}>Sign out</a>
        </nav>
      </aside>
      <main>
        <header><h1>Good Day, {profile?.full_name}!</h1><p>Manage. Monitor. Support.</p></header>
        <Outlet />
      </main>
    </div>
  );
}
