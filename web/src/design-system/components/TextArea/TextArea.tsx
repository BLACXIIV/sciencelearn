import { TextareaHTMLAttributes, forwardRef, useId } from "react";
import { Icon } from "../../icons/Icon";
import "../TextField/TextField.css";

export interface TextAreaProps
  extends Omit<TextareaHTMLAttributes<HTMLTextAreaElement>, "id"> {
  /** Lexend label rendered above the textarea. */
  label: string;
  /** Error message — shows the error border, icon and text. */
  error?: string | null;
  /** Muted helper line under the textarea (hidden when `error` is set). */
  helper?: string;
  id?: string;
}

/**
 * Multi-line text input — same `.ds-field` chrome as TextField
 * (radius 14, blue focus ring, error state), 96px minimum height.
 */
export const TextArea = forwardRef<HTMLTextAreaElement, TextAreaProps>(function TextArea(
  { label, error, helper, id, className = "", ...rest },
  ref,
) {
  const uid = useId();
  const inputId = id ?? uid;
  const msgId = `${inputId}-msg`;
  return (
    <div className={`ds-field${error ? " err" : ""} ${className}`.trim()}>
      <label className="ds-label" htmlFor={inputId}>{label}</label>
      <textarea
        id={inputId}
        ref={ref}
        aria-invalid={error ? true : undefined}
        aria-describedby={error || helper ? msgId : undefined}
        {...rest}
      />
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
