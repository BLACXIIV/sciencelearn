import "./Divider.css";

export interface DividerProps {
  /** Optional centered label ("or", section titles). */
  label?: string;
  /** Vertical gap around the rule. Default 16. */
  spacing?: number;
}

/**
 * Divider — 1px `--ds-line` rule, optionally with a centered muted caption.
 */
export function Divider({ label, spacing = 16 }: DividerProps) {
  if (label) {
    return (
      <div className="ds-divider-labeled" role="separator" style={{ margin: `${spacing}px 0` }}>
        <span className="ds-divider-line" />
        <span className="ds-divider-text">{label}</span>
        <span className="ds-divider-line" />
      </div>
    );
  }
  return <hr className="ds-divider" style={{ margin: `${spacing}px 0` }} />;
}
