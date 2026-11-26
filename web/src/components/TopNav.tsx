import { useQuery } from "@tanstack/react-query";
import { Link, useLocation } from "react-router-dom";
import { Avatar, Icon } from "../design-system";
import { useAuth } from "../hooks/useAuth";
import { getR2Url } from "../services/storage";
import "./shell.css";

/** Route → top-bar title (teacher portal). */
function pageTitle(path: string): string {
  if (path === "/teacher/users") return "Users";
  if (path === "/teacher/account") return "Account";
  const m = path.match(/^\/teacher\/c\/[^/]+(?:\/(.*))?$/);
  if (m?.[1]?.startsWith("reports/")) return "Reports / student";
  if (m) {
    // Match the first segment — e.g. "lessons/<id>/activities" still titles
    // "Lessons" (the builder lives under the lessons tree).
    switch (m[1]?.split("/")[0]) {
      case undefined: return "Dashboard";
      case "lessons": return "Lessons";
      case "quiz": return "Create Quiz";
      case "students": return "Students";
      case "review": return "Review Content";
      case "reports": return "Reports";
      default: return "Dashboard";
    }
  }
  return "Dashboard";
}

/** Top bar: page title floats on the paper bg, profile chip (white pill)
 *  on the right → Account. No card chrome — layout lives in shell.css. */
export default function TopNav() {
  const { profile } = useAuth();
  const path = useLocation().pathname;
  const avatarKey = profile?.avatar_url ?? null;
  const url = useQuery({
    queryKey: ["r2-url", avatarKey],
    queryFn: () => getR2Url(avatarKey!),
    enabled: !!avatarKey,
    staleTime: 5 * 60 * 1000,
  });
  return (
    <div className="sh-top">
      <span className="sh-title">{pageTitle(path)}</span>
      <Link to="/teacher/account" className="sh-profile edge-3">
        <span className="sh-pnm">{profile?.full_name ?? "…"}</span>
        <Avatar name={profile?.full_name ?? ""} src={url.data} size={32} />
        <Icon name="chevron" size={16} color="var(--ds-muted)" />
      </Link>
    </div>
  );
}
