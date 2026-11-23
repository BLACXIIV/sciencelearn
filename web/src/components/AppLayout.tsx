import { NavLink, Outlet } from "react-router-dom";
import TopNav from "./TopNav";
import { I, type IconName } from "./icons";
import { useAuth } from "../hooks/useAuth";
import { signOut } from "../services/auth";

// Add entries here to extend the sidebar — no layout changes needed.
const NAV_ITEMS: { to: string; label: string; icon: IconName; end: boolean }[] = [
  { to: "/teacher", label: "Dashboard", icon: "dashboard", end: true },
  { to: "/teacher/classes", label: "Classes", icon: "students", end: false },
];

/** Staff shell: sidebar nav + header + routed content. Rendered inside RequireTeacher. */
export default function AppLayout() {
  const { profile } = useAuth();
  const items = profile?.role === "admin"
    ? [...NAV_ITEMS, { to: "/teacher/users", label: "Users", icon: "userAdmin" as IconName, end: false }]
    : NAV_ITEMS;
  return (
    <div className="shell">
      <aside>
        <h2><span className="brand-mark"><I name="atom" size={22} /></span>ScienceLearn</h2>
        <nav>
          {items.map((item) => (
            <NavLink key={item.to} to={item.to} end={item.end}>
              <I name={item.icon} size={18} />{item.label}
            </NavLink>
          ))}
        </nav>
        <button type="button" className="nav-action" onClick={signOut}><I name="signOut" size={18} />Sign out</button>
      </aside>
      <main>
        <TopNav />
        <header className="page-head">
          <div><h1>Good Day, {profile?.full_name}!</h1><p>Manage. Monitor. Support.</p></div>
        </header>
        <Outlet />
      </main>
    </div>
  );
}
