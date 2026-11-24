import "./Badge.css";

export type BadgeTone = "blue" | "mint" | "sun" | "error";

export interface BadgeProps {
  /** Content — usually a count or short label. */
  children: React.ReactNode;
  tone?: BadgeTone;
}

/**
 * Badge — tiny count/status pill (radius 99, Lexend 800/11). For counts on
 * nav items, avatars and cards — not clickable.
 */
export function Badge({ children, tone = "blue" }: BadgeProps) {
  return <span className={`ds-badge ds-badge-${tone}`}>{children}</span>;
}
