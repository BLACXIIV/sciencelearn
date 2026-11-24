import { ReactNode } from "react";
import { RadioCard } from "../RadioCard/RadioCard";
import "./RadioGroup.css";

export interface RadioGroupOption {
  value: string;
  /** Tile content — text, or icon+text composition. */
  content: ReactNode;
  disabled?: boolean;
}

export interface RadioGroupProps {
  /** Fieldset legend — the Lexend label above the tiles. */
  label?: string;
  options: RadioGroupOption[];
  value: string;
  onChange: (value: string) => void;
  /** Grid columns. Default 2 (role-picker style). */
  columns?: 1 | 2 | 3;
  name?: string;
}

/**
 * RadioGroup — labelled set of RadioCards presented as a single-choice
 * radiogroup (e.g. "I am a…" Student/Teacher). Whole tile is the hit area.
 */
export function RadioGroup({ label, options, value, onChange, columns = 2, name }: RadioGroupProps) {
  return (
    <fieldset className="ds-radio-group" role="radiogroup" aria-label={label}>
      {label && <legend className="ds-label">{label}</legend>}
      <div className={`ds-radio-grid ds-radio-grid-${columns}`}>
        {options.map((o) => (
          <RadioCard
            key={o.value}
            selected={value === o.value}
            onSelect={() => !o.disabled && onChange(o.value)}
            disabled={o.disabled}
            ariaLabel={name ? `${name}: ${o.value}` : undefined}
          >
            {o.content}
          </RadioCard>
        ))}
      </div>
    </fieldset>
  );
}
