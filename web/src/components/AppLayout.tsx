import { useQuery } from "@tanstack/react-query";
import { Outlet, useLocation, useMatch, useNavigate } from "react-router-dom";
import TopNav from "./TopNav";
import { Avatar, Badge, Icon, NavBar, type NavSection } from "../design-system";
import { useAuth } from "../hooks/useAuth";
import { signOut } from "../services/auth";
import { fetchClass, fetchClassMembers } from "../services/classes";
import { getR2Url } from "../services/storage";
import "./shell.css";

const NEW = <Badge tone="mint">NEW</Badge>;

/** Staff shell: DS NavBar rail (brand + class switcher + grouped nav) +
 *  top bar + routed content. Inside /teacher/c/:classId the rail becomes
 *  that class's portal — TEACH / CLASS groups; admins also get ADMIN. */
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
  const members = useQuery({
    queryKey: ["class-members", classId],
    queryFn: () => fetchClassMembers(classId!),
    enabled: !!classId,
  });
  const avatarKey = profile?.avatar_url ?? null;
  const avatar = useQuery({
    queryKey: ["r2-url", avatarKey],
    queryFn: () => getR2Url(avatarKey!),
    enabled: !!avatarKey,
    staleTime: 5 * 60 * 1000,
  });

  const base = classId ? `/teacher/c/${classId}` : null;
  const pending = (members.data ?? []).filter((m) => m.status === "pending").length;

  const sections: NavSection[] = [];
  if (base) {
    sections.push(
      {
        label: "TEACH",
        items: [
          { key: base, label: "Dashboard", icon: "dashboard" },
          { key: `${base}/lessons`, label: "Lessons", icon: "lessons" },
          { key: `${base}/quiz`, label: "Create Quiz", icon: "quiz" },
          { key: `${base}/review`, label: "Review Content", icon: "review", badge: NEW },
        ],
      },
      {
        label: "CLASS",
        items: [
          {
            key: `${base}/students`, label: "Students", icon: "students",
            badge: pending > 0 ? <Badge tone="sun">{pending}</Badge> : undefined,
          },
          { key: `${base}/reports`, label: "Reports", icon: "progress", badge: NEW },
        ],
      },
    );
  }
  if (profile?.role === "admin") {
    sections.push({
      label: "ADMIN",
      items: [{ key: "/teacher/users", label: "Users", icon: "userAdmin" }],
    });
  }

  // Exact match wins; otherwise longest prefix — but the bare class root only
  // matches itself (Dashboard shouldn't stay lit on every sub-page).
  const keys = sections.flatMap((s) => s.items.map((i) => i.key));
  const active = keys.includes(path)
    ? path
    : keys.filter((k) => k !== base).sort((a, b) => b.length - a.length)
        .find((k) => path.startsWith(`${k}/`));

  return (
    <div className="sh">
      <NavBar
        brand={<div className="sh-brand"><img src="/logo.png" alt="" /><span>ScienceLearn</span></div>}
        context={
          cls.data ? (
            <div className="sh-class">
              <div className="sh-class-cap">Classroom</div>
              <div className="sh-class-name">{cls.data.name}</div>
              <div className="sh-class-row">
                <span className="sh-class-code">{cls.data.code}</span>
                <button type="button" className="sh-class-switch"
                  onClick={() => nav("/select-classroom")}>
                  Switch
                </button>
              </div>
            </div>
          ) : undefined
        }
        sections={sections}
        active={active}
        onSelect={(key) => nav(key)}
        footer={
          <>
            <button type="button" className="sh-user-card sh-user-btn"
              onClick={() => nav("/teacher/account")}>
              <Avatar name={profile?.full_name ?? ""} src={avatar.data} size={38} />
              <span className="sh-user-who">
                <span className="sh-user-nm">{profile?.full_name ?? "…"}</span>
                <span className="sh-user-rl">{profile?.role ?? ""}</span>
              </span>
            </button>
            <button type="button" className="ds-nav-item" onClick={signOut}>
              <Icon name="signOut" size={22} />
              <span className="ds-nav-label">Sign out</span>
            </button>
          </>
        }
      />
      <main className="sh-main">
        <TopNav />
        <Outlet />
      </main>
    </div>
  );
}
