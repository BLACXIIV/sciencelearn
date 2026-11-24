import { SelectHTMLAttributes, forwardRef, useId } from "react";
import { Icon } from "../../icons/Icon";
import "../TextField/TextField.css";
import "./Select.css";

export interface SelectOption {
  value: string;
  label: string;
}

export interface SelectProps
  extends Omit<SelectHTMLAttributes<HTMLSelectElement>, "id" | "children"> {
  /** Lexend label rendered above the select. */
  label: string;
  options: SelectOption[];
  /** Error message — shows the error border, icon and text. */
  error?: string | null;
  /** Muted helper line under the select. */
  helper?: string;
  id?: string;
}

/**
 * Labeled dropdown — native `<select>` with `.ds-field` chrome (radius 14,
 * blue focus ring) plus a chevron affordance. Use for short option lists;
 * for 2–4 prominent choices prefer RadioGroup or OptionTile.
 */
export const Select = forwardRef<HTMLSelectElement, SelectProps>(function Select(
  { label, options, error, helper, id, className = "", ...rest },
  ref,
) {
  const uid = useId();
  const inputId = id ?? uid;
  const msgId = `${inputId}-msg`;
  return (
    <div className={`ds-field${error ? " err" : ""} ${className}`.trim()}>
      <label className="ds-label" htmlFor={inputId}>{label}</label>
      <div className="ds-select-wrap">
        <select
          id={inputId}
          ref={ref}
          aria-invalid={error ? true : undefined}
          aria-describedby={error || helper ? msgId : undefined}
          {...rest}
        >
          {options.map((o) => (
            <option key={o.value} value={o.value}>{o.label}</option>
          ))}
        </select>
        <Icon name="chevron" size={18} className="ds-select-chev" />
      </div>
      {error && (
        <p className="ds-field-msg" id={msgId}>
          <Icon name="alert" size={14} />
          {error}
        </p>
      )}
      {!error && helper && <p className="ds-field-helper" id={msgId}>{helper}</p>}
    </div>
  );
});
