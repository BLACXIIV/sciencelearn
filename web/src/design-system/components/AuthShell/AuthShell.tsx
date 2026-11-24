import { ReactNode } from "react";
import "./AuthShell.css";

export interface AuthShellProps {
  /** Left hero panel content — brand, illustration, sticker badges, trivia. */
  hero: ReactNode;
  /** Right column content — segmented control, form, links. */
  children: ReactNode;
}

/**
 * AuthShell — the split-screen auth layout: navy gradient hero panel (left)
 * + centered form column (right, max 420px). Below the 1024px breakpoint the
 * hero collapses and the form fills the viewport — mirroring the mobile
 * sheet flow. Hero art belongs to the caller (image + decorations).
 */
export function AuthShell({ hero, children }: AuthShellProps) {
  return (
    <div className="ds-auth">
      <aside className="ds-auth-hero">{hero}</aside>
      <main className="ds-auth-main">
        <div className="ds-auth-card">{children}</div>
      </main>
    </div>
  );
}
