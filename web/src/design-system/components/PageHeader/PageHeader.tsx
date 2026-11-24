import { ReactNode } from "react";
import "./PageHeader.css";

export interface PageHeaderProps {
  /** Navy band content — title, greeting, search row. */
  children: ReactNode;
  /** Compact = 24px padding instead of 32. */
  compact?: boolean;
}

/**
 * PageHeader — navy band with 40px rounded bottom corners (the landing hero
 * shape, reused as a page top). White content; place titles/actions inside.
 */
export function PageHeader({ children, compact }: PageHeaderProps) {
  return <header className={`ds-page-header${compact ? " compact" : ""}`}>{children}</header>;
}
