import { useRef } from "react";
import { Icon } from "../../icons/Icon";
import "./CodeInput.css";

export interface CodeInputProps {
  /** Lexend label above the cells (e.g. "Class code"). */
  label?: string;
  value: string;
  onChange: (value: string) => void;
  /** Error message — cells get the coral border + message below. */
  error?: string | null;
  /** Number of cells. Default 6 (class codes). */
  length?: number;
  disabled?: boolean;
  autoFocus?: boolean;
}

const CODE_CHARS = /[^a-zA-Z0-9]/g;

/**
 * CodeInput — row of chunky cells for a short code (class join codes).
 * A single hidden input handles typing and paste; each cell is styled
 * like a mini card (radius 14, line border, blue edge on the active cell).
 */
export function CodeInput({ label, value, onChange, error, length = 6, disabled, autoFocus }: CodeInputProps) {
  const inputRef = useRef<HTMLInputElement>(null);
  const chars = value.padEnd(length).slice(0, length).split("");
  const activeIdx = Math.min(value.length, length - 1);

  return (
    <div className={`ds-field ds-code${error ? " err" : ""}`}>
      {label && <label className="ds-label" htmlFor="ds-code-hidden">{label}</label>}
      <div
        className="ds-code-cells"
        role="group"
        aria-label={label ?? "Code input"}
        onClick={() => inputRef.current?.focus()}
      >
        <input
          id="ds-code-hidden"
          ref={inputRef}
          className="ds-code-hidden"
          value={value}
          disabled={disabled}
          autoFocus={autoFocus}
          inputMode="text"
          autoComplete="one-time-code"
          maxLength={length}
          aria-invalid={error ? true : undefined}
          onChange={(e) => {
            const v = e.target.value.replace(CODE_CHARS, "").toUpperCase().slice(0, length);
            onChange(v);
          }}
        />
        {chars.map((c, i) => (
          <span
            key={i}
            className={`ds-code-cell${c.trim() ? " filled" : ""}${i === activeIdx ? " active" : ""}`}
            aria-hidden="true"
          >
            {c.trim() || "\u00A0"}
          </span>
        ))}
      </div>
      {error && (
        <p className="ds-field-msg">
          <Icon name="alert" size={14} />
          {error}
        </p>
      )}
    </div>
  );
}
