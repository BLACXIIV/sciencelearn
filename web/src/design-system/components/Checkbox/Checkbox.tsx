import { InputHTMLAttributes, forwardRef, useId } from "react";
import "./Checkbox.css";

export interface CheckboxProps
  extends Omit<InputHTMLAttributes<HTMLInputElement>, "id" | "type"> {
  /** Text label next to the box. Row tap target is ≥44px. */
  label: string;
  id?: string;
}

/**
 * Checkbox — 18px box with the DS accent blue + focus halo, label in Inter.
 * Whole row is a ≥44px tap target.
 */
export const Checkbox = forwardRef<HTMLInputElement, CheckboxProps>(function Checkbox(
  { label, id, className = "", ...rest },
  ref,
) {
  const uid = useId();
  const inputId = id ?? uid;
  return (
    <label className={`ds-check ${className}`} htmlFor={inputId}>
      <input id={inputId} type="checkbox" ref={ref} {...rest} />
      <span className="ds-check-text">{label}</span>
    </label>
  );
});
