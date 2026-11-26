import { InputHTMLAttributes, forwardRef, useId } from "react";
import "./Switch.css";

export interface SwitchProps
  extends Omit<InputHTMLAttributes<HTMLInputElement>, "id" | "type"> {
  /** Optional label next to the toggle. */
  label?: string;
  /** Checked-track color. `blue` (default) for settings; `teal` for publish
   *  toggles where "on" means live. */
  tone?: "blue" | "teal";
  id?: string;
}

/**
 * Switch — pill toggle, radius 99. Track goes blue when on; the knob is a
 * white circle with a card edge. Row tap target ≥44px.
 */
export const Switch = forwardRef<HTMLInputElement, SwitchProps>(function Switch(
  { label, tone = "blue", id, className = "", ...rest },
  ref,
) {
  const uid = useId();
  const inputId = id ?? uid;
  const input = (
    <span className={`ds-switch${tone === "teal" ? " tone-teal" : ""}`}>
      <input id={inputId} type="checkbox" role="switch" ref={ref} {...rest} />
      <span className="ds-switch-track" aria-hidden="true"><span className="ds-switch-knob" /></span>
    </span>
  );
  return label ? (
    <label className={`ds-switch-row ${className}`} htmlFor={inputId}>
      {input}
      <span className="ds-switch-text">{label}</span>
    </label>
  ) : (
    <span className={className}>{input}</span>
  );
});
