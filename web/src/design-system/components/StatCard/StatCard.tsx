import { Icon, type IconName } from "../../icons/Icon";
import "./StatCard.css";

export interface StatCardProps {
  /** Registry icon in a pastel square. */
  icon: IconName;
  /** Big Lexend value (e.g. "82%", "12"). */
  value: string;
  /** Caption under the value. */
  label: string;
  /** Icon square fill. Default blue pastel. */
  pastelColor?: "blue" | "yellow" | "purple" | "mint";
}

/**
 * StatCard — white card: pastel icon square + big value + caption.
 * For dashboard stat rows. Icon must come from the registry (never emoji).
 */
export function StatCard({ icon, value, label, pastelColor = "blue" }: StatCardProps) {
  return (
    <div className="ds-stat">
      <span className={`ds-stat-ic ds-stat-ic-${pastelColor}`}>
        <Icon name={icon} size={22} />
      </span>
      <span className="ds-stat-value">{value}</span>
      <span className="ds-stat-label">{label}</span>
    </div>
  );
}
