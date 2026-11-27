import { ButtonHTMLAttributes, ReactNode } from "react";
import { Icon, type IconName } from "../../icons/Icon";
import "./Button.css";

export type ButtonVariant = "primary" | "mint" | "sun" | "white" | "outline" | "danger" | "ghost" | "line";
export type ButtonSize = "md" | "sm" | "xs";

export interface ButtonProps extends Omit<ButtonHTMLAttributes<HTMLButtonElement>, "disabled"> {
  /** Visual variant. `primary` = blue CTA (default). `ghost` = border-only,
   *  intended for use on navy surfaces. */
  variant?: ButtonVariant;
  /** `md` = 52px primary-form size (default). `sm` = compact nav size.
   *  `xs` = tight in-card action (activity-card footer). */
  size?: ButtonSize;
  /** Shows a spinner and blocks interaction. */
  loading?: boolean;
  disabled?: boolean;
  /** Stretch to the container width. */
  fullWidth?: boolean;
  /** Optional registry icon before the label. */
  leadingIcon?: IconName;
  children: ReactNode;
}

/**
 * Chunky button — the signature SL control: solid fill + solid bottom edge in
 * a darker shade, radius 16. Presses translate 4px and the edge collapses to
 * 1px. Use `primary` for the one main action, `mint`/`white` on navy, `outline`
 * for secondary actions, `danger` for destructive ones, `ghost` on dark panels.
 */
export function Button({
  variant = "primary",
  size = "md",
  loading = false,
  disabled = false,
  fullWidth = false,
  leadingIcon,
  className = "",
  children,
  type = "button",
  ...rest
}: ButtonProps) {
  const cls = [
    "ds-btn", `ds-btn-${variant}`, `ds-btn-${size}`,
    fullWidth ? "ds-btn-block" : "", className,
  ].filter(Boolean).join(" ");
  return (
    <button type={type} className={cls} disabled={disabled || loading} {...rest}>
      {loading
        ? <span className="ds-btn-spin" aria-label="Working" />
        : <>{leadingIcon && <Icon name={leadingIcon} size={size === "md" ? 18 : 16} />}{children}</>}
    </button>
  );
}
