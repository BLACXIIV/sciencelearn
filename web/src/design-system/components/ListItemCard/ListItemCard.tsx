import { ReactNode } from "react";
import { Link } from "react-router-dom";
import { Card } from "../Card/Card";
import "./ListItemCard.css";

export interface ListItemCardProps {
  /** Leading slot — Thumbnail, Icon or Avatar. */
  leading?: ReactNode;
  title: ReactNode;
  /** Secondary line under the title — text or a small element
   *  (e.g. a ProgressBar wrapped in `.ds-lic-progress`). */
  subtitle?: ReactNode;
  /** Trailing slot — Badge, score, chevron. */
  trailing?: ReactNode;
  /** SPA destination — the whole card navigates. */
  to?: string;
  onClick?: () => void;
  /** Awaiting state (e.g. pending class join): non-interactive, dimmed leading. */
  pending?: boolean;
  disabled?: boolean;
}

/**
 * ListItemCard — the standard tappable list row: white card with leading
 * media, title + subtitle, and a trailing slot. `to`/`onClick` make it
 * interactive (hover lift); `pending`/`disabled` mute it. Replaces
 * hand-rolled icon+text+chevron rows.
 */
export function ListItemCard({
  leading, title, subtitle, trailing, to, onClick, pending, disabled,
}: ListItemCardProps) {
  const interactive = !pending && !disabled && (!!to || !!onClick);
  const cls = [
    "ds-lic",
    interactive ? "ds-lic-hot" : "",
    pending ? "ds-lic-pending" : "",
    disabled ? "ds-lic-disabled" : "",
  ].filter(Boolean).join(" ");

  const card = (
    <Card className={cls} onClick={interactive && onClick ? onClick : undefined}>
      {leading && <span className="ds-lic-leading">{leading}</span>}
      <span className="ds-lic-body">
        <span className="ds-lic-title">{title}</span>
        {subtitle && <span className="ds-lic-sub">{subtitle}</span>}
      </span>
      {trailing && <span className="ds-lic-trail">{trailing}</span>}
    </Card>
  );

  if (interactive && to) return <Link to={to} className="ds-lic-link">{card}</Link>;
  return <div className="ds-lic-link">{card}</div>;
}
