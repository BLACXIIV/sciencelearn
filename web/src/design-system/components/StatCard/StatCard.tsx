import { ReactNode } from "react";
import { Icon, type IconName } from "../../icons/Icon";
import "./StatCard.css";

export interface StatCardProps {
  /** Registry icon in a white/pastel square. */
  icon: IconName;
  /** Big Lexend value (e.g. "82%", "12", or "—" for no data). */
  value: string;
  /** Caption under the value. */
  label: string;
  /** Pastel swatch. Default blue. */
  pastelColor?: "blue" | "yellow" | "purple" | "mint";
  /** Fill the whole card with the pastel (teacher dashboard tiles);
   *  default keeps the white card + pastel icon square. */
  filled?: boolean;
  /** Small reason/context line under the label ("1 active", "No quiz attempts yet"). */
  note?: string;
  /** Alert chrome: white card + 3px sun border (pending-request tile). */
  alert?: boolean;
  /** Optional action at the card foot (e.g. a Review button). */
  action?: ReactNode;
}

/**
 * StatCard — chunky dashboard stat tile. Default: white card + pastel icon
 * square + big value + caption. `filled` makes the whole card pastel with a
 * white icon square (teacher portal). `alert` gives the white card a sun
 * border for action-needed tiles. Icon must come from the registry.
 */
export function StatCard({
  icon, value, label, pastelColor = "blue", filled = false, note, alert, action,
}: StatCardProps) {
  return (
    <div className={[
      "ds-stat",
      filled ? `ds-stat-f ds-stat-f-${pastelColor}` : "",
      alert ? "ds-stat-alert" : "",
    ].filter(Boolean).join(" ")}>
      <span className={`ds-stat-ic${filled ? " ds-stat-ic-w" : ` ds-stat-ic-${pastelColor}`}`}>
        <Icon name={icon} size={22} />
      </span>
      <span className="ds-stat-value">{value}</span>
      <span className="ds-stat-label">{label}</span>
      {note && <span className="ds-stat-note">{note}</span>}
      {action && <div className="ds-stat-action">{action}</div>}
    </div>
  );
}
