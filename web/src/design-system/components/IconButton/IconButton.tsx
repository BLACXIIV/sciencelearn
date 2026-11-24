import { ButtonHTMLAttributes } from "react";
import { Icon, type IconName } from "../../icons/Icon";
import "./IconButton.css";

export interface IconButtonProps
  extends Omit<ButtonHTMLAttributes<HTMLButtonElement>, "disabled" | "children"> {
  /** Registry icon to render. */
  icon: IconName;
  /** Accessible label — required (there is no visible text). */
  label: string;
  disabled?: boolean;
}

/**
 * Compact icon-only control: white tile, line border, 3px card edge, radius 14.
 * Min hit target 44px. For toolbars, row actions, and close buttons.
 */
export function IconButton({ icon, label, disabled, className = "", type = "button", ...rest }: IconButtonProps) {
  return (
    <button
      type={type}
      className={`ds-icon-btn ${className}`}
      aria-label={label}
      title={label}
      disabled={disabled}
      {...rest}
    >
      <Icon name={icon} size={20} />
    </button>
  );
}
