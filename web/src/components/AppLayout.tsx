import { Outlet, useLocation, useNavigate } from "react-router-dom";
import TopNav from "./TopNav";
import { Icon, NavBar, type IconName } from "../design-system";
import { useAuth } from "../hooks/useAuth";
import { signOut } from "../services/auth";
import "./shell.css";

// Add entries here to extend the sidebar — no layout changes needed.
const NAV_ITEMS: { to: string; label: string; icon: IconName; end: boolean }[] = [
  { to: "/teacher", label: "Dashboard", icon: "dashboard", end: true },
  { to: "/teacher/classes", label: "Classes", icon: "students", end: false },
];

/** Staff shell: DS NavBar rail + top bar + routed content. Rendered inside RequireTeacher. */
export default function AppLayout() {
  const { profile } = useAuth();
  const nav = useNavigate();
  const path = useLocation().pathname;
  const items = profile?.role === "admin"
    ? [...NAV_ITEMS, { to: "/teacher/users", label: "Users", icon: "userAdmin" as IconName, end: false }]
    : NAV_ITEMS;
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
          <button type="button" className="ds-nav-item" onClick={signOut}>
            <Icon name="signOut" size={20} />
            <span className="ds-nav-label">Sign out</span>
          </button>
        }
      />
      <main className="sh-main">
        <TopNav />
        <header className="sh-head">
          <div><h1 className="ds-h2">Good Day, {profile?.full_name}!</h1><p className="ds-body-sm sh-dim">Manage. Monitor. Support.</p></div>
        </header>
        <Outlet />
      </main>
    </div>
  );
}
