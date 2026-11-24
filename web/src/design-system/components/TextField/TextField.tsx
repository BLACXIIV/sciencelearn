import { InputHTMLAttributes, ReactNode, forwardRef, useId } from "react";
import { Icon } from "../../icons/Icon";
import "./TextField.css";

export interface TextFieldProps
  extends Omit<InputHTMLAttributes<HTMLInputElement>, "id"> {
  /** Lexend label rendered above the input. */
  label: string;
  /** Error message — shows the error border, icon and text. */
  error?: string | null;
  /** Muted helper line under the input (hidden when `error` is set). */
  helper?: string;
  /** Content injected into the input wrapper's left side (e.g. search icon). */
  leading?: ReactNode;
  /** Content injected into the input wrapper's right side (e.g. eye toggle). */
  trailing?: ReactNode;
  id?: string;
}

/**
 * Labeled text input: label above, 50px tall, radius 14, line border.
 * Focus = 2px blue edge + ring; error = coral border + icon + message.
 * Base for PasswordField / SearchField / CodeInput via the shared `.ds-field`
 * chrome in TextField.css.
 */
export const TextField = forwardRef<HTMLInputElement, TextFieldProps>(function TextField(
  { label, error, helper, leading, trailing, id, className = "", ...rest },
  ref,
) {
  const uid = useId();
  const inputId = id ?? uid;
  const msgId = `${inputId}-msg`;
  return (
    <div className={`ds-field${error ? " err" : ""} ${className}`.trim()}>
      <label className="ds-label" htmlFor={inputId}>{label}</label>
      <div className={`ds-field-wrap${leading ? " has-leading" : ""}${trailing ? " has-trailing" : ""}`}>
        {leading}
        <input
          id={inputId}
          ref={ref}
          aria-invalid={error ? true : undefined}
          aria-describedby={error || helper ? msgId : undefined}
          {...rest}
        />
        {trailing}
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
