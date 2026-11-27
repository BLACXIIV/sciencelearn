import { Icon, type IconName } from "../../icons/Icon";
import "./StatusBadge.css";

export type StatusTone = "success" | "warning" | "danger" | "neutral";

/** Domain statuses — one meaning, one look (tone + icon are automatic). */
export type StatusKind =
  | "active" | "published" | "released"
  | "pending" | "manual"
  | "failed" | "declined" | "offline"
  | "draft" | "hidden";

const MAP: Record<StatusKind, { tone: StatusTone; icon: IconName; label: string }> = {
  active:    { tone: "success", icon: "check",   label: "Active" },
  published: { tone: "success", icon: "check",   label: "Published" },
  released:  { tone: "success", icon: "check",   label: "Released" },
  pending:   { tone: "warning", icon: "pending", label: "Pending" },
  manual:    { tone: "warning", icon: "pending", label: "Manual" },
  failed:    { tone: "danger",  icon: "close",   label: "Failed" },
  declined:  { tone: "danger",  icon: "close",   label: "Declined" },
  offline:   { tone: "danger",  icon: "offline", label: "Offline" },
  draft:     { tone: "neutral", icon: "hide",    label: "Draft" },
  hidden:    { tone: "neutral", icon: "hide",    label: "Hidden" },
};

export interface StatusBadgeProps {
  /** Semantic status — resolves tone + icon from the shared vocabulary. */
  status?: StatusKind;
  /** Escape hatch for one-off states not in the vocabulary. */
  tone?: StatusTone;
  icon?: IconName;
  /** Defaults to the status's canonical label. */
  label?: React.ReactNode;
}

/**
 * StatusBadge — quiet 12%-tint status pill (22px, pill radius, 12px text,
 * one icon per status). For state ("published", "pending") — not counts
 * (use Badge) or tags (use Chip).
 */
export function StatusBadge({ status, tone, icon, label }: StatusBadgeProps) {
  const mapped = status ? MAP[status] : undefined;
  const t = mapped?.tone ?? tone ?? "neutral";
  const ic = icon ?? mapped?.icon;
  return (
    <span className={`ds-status ds-status-${t}`}>
      {ic && <Icon name={ic} size={12} />}
      <span>{label ?? mapped?.label ?? status}</span>
    </span>
  );
}
