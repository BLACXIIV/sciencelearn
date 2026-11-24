import { useId } from "react";
import "./SegmentedControl.css";

export interface SegmentedControlProps {
  /** 2–4 options (the Log in / Sign up switcher uses 2). */
  options: { value: string; label: string }[];
  value: string;
  onChange: (value: string) => void;
  /** Accessible group label. */
  ariaLabel: string;
}

/**
 * SegmentedControl — white track + navy sliding pill (the Log in / Sign up
 * switcher). Track: radius 16, line border. Pill slides with a 200ms ease and
 * honors reduced motion. Use for the top-level mode switch only.
 */
export function SegmentedControl({ options, value, onChange, ariaLabel }: SegmentedControlProps) {
  const uid = useId();
  const idx = Math.max(0, options.findIndex((o) => o.value === value));
  const w = 100 / options.length;
  return (
    <div className="ds-seg" role="tablist" aria-label={ariaLabel}>
      <span
        className="ds-seg-pill"
        aria-hidden="true"
        style={{ width: `${w}%`, transform: `translateX(${idx * 100}%)` }}
      />
      {options.map((o, i) => (
        <button
          key={o.value}
          id={`${uid}-${i}`}
          type="button"
          role="tab"
          aria-selected={o.value === value}
          className={`ds-seg-opt${o.value === value ? " on" : ""}`}
          onClick={() => onChange(o.value)}
        >
          {o.label}
        </button>
      ))}
    </div>
  );
}
