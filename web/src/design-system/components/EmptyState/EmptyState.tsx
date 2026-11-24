import { ReactNode } from "react";
import { Icon, type IconName } from "../../icons/Icon";
import "./EmptyState.css";

export interface EmptyStateProps {
  /** Registry icon in a large pastel circle. */
  icon: IconName;
  title: string;
  /** Optional muted body line. */
  body?: string;
  /** Optional CTA — typically a Button. */
  action?: ReactNode;
}

/**
 * EmptyState — pastel icon circle + title + body + optional action.
 * For empty lists, no-results, and first-run prompts.
 */
export function EmptyState({ icon, title, body, action }: EmptyStateProps) {
  return (
    <div className="ds-empty">
      <span className="ds-empty-ic">
        <Icon name={icon} size={28} />
      </span>
      <h3 className="ds-empty-title">{title}</h3>
      {body && <p className="ds-empty-body">{body}</p>}
      {action && <div className="ds-empty-action">{action}</div>}
    </div>
  );
}
