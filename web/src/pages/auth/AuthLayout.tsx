import { ReactNode } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { AuthShell, SegmentedControl } from "../../design-system";
import { AuthHero } from "./AuthHero";
import "./auth.css";

/** Auth page composer on the DS AuthShell: navy AuthHero (art circle,
 *  orbit, sticker badges, trivia card) left, centered form column right.
 *  Shows the Log in / Sign up segmented control only on those two routes —
 *  Forgot/Reset password get the same shell without the tabs. */
export function AuthLayout({
  title,
  subtitle,
  art,
  children,
  footer,
}: {
  title: string;
  subtitle: ReactNode;
  art?: string;
  children: ReactNode;
  footer?: ReactNode;
}) {
  const nav = useNavigate();
  const path = useLocation().pathname;
  const mode = path.startsWith("/signup") ? "signup" : path.startsWith("/login") ? "login" : null;

  return (
    <AuthShell hero={<AuthHero art={art} />}>
      <Link to="/" className="a-logo-m" aria-label="ScienceLearn home">
        <img src="/logo.png" alt="" />
        ScienceLearn
      </Link>
      {mode && (
        <SegmentedControl
          ariaLabel="Log in or sign up"
          options={[
            { value: "login", label: "Log in" },
            { value: "signup", label: "Sign up" },
          ]}
          value={mode}
          onChange={(v) => nav(v === "login" ? "/login" : "/signup")}
        />
      )}
      <h2 className="ds-h2 a-title">{title}</h2>
      <p className="ds-body-sm a-sub">{subtitle}</p>
      {children}
      {footer && <div className="a-foot">{footer}</div>}
    </AuthShell>
  );
}
