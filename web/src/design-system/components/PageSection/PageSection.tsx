import { ReactNode } from "react";
import "./PageSection.css";

export interface PageSectionProps {
  /** Section heading (h2 style). */
  title?: string;
  /** Right-aligned header content — links, filters, actions. */
  aside?: ReactNode;
  children: ReactNode;
  /** Constrain content to --ds-content-max and center. Default true. */
  contained?: boolean;
}

/**
 * PageSection — page body block: optional title row + content with the
 * standard gutter and 48px vertical rhythm.
 */
export function PageSection({ title, aside, children, contained = true }: PageSectionProps) {
  return (
    <section className={`ds-section${contained ? " contained" : ""}`}>
      {(title || aside) && (
        <div className="ds-section-head">
          {title && <h2 className="ds-h1 ds-section-title">{title}</h2>}
          {aside}
        </div>
      )}
      {children}
    </section>
  );
}
