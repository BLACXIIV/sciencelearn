import "./ProgressBar.css";

export type ProgressBarSize = "lg" | "sm";
export type ProgressBarTone = "blue" | "mint" | "sun" | "success";

export interface ProgressBarProps {
  /** 0–100. */
  value: number;
  /** lg = 14px (primary), sm = 10px (compact rows). */
  size?: ProgressBarSize;
  /** Fill color. Default blue; use success for post-test/complete. */
  tone?: ProgressBarTone;
  /** Accessible label (e.g. "Lesson progress"). */
  label?: string;
}

/**
 * ProgressBar — track + fill, radius 99. Sizes: lg 14px / sm 10px only.
 * Track is `--ds-track`; fill carries a subtle 3px edge of its own shade.
 */
export function ProgressBar({ value, size = "lg", tone = "blue", label }: ProgressBarProps) {
  const pct = Math.max(0, Math.min(100, value));
  return (
    <div
      className={`ds-progress ds-progress-${size}`}
      role="progressbar"
      aria-valuenow={pct}
      aria-valuemin={0}
      aria-valuemax={100}
      aria-label={label}
    >
      <div className={`ds-progress-fill ds-progress-fill-${tone}`} style={{ width: `${pct}%` }} />
    </div>
  );
}
