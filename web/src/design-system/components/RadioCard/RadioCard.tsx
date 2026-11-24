import { ReactNode } from "react";
import "./RadioCard.css";

export interface RadioCardProps {
  /** Whether this tile is selected. Controlled by RadioGroup or the caller. */
  selected: boolean;
  onSelect: () => void;
  disabled?: boolean;
  /** Tile content — icon + label, arbitrary children, or a preset like OptionTile. */
  children: ReactNode;
  /** Accessible name when content is not self-describing. */
  ariaLabel?: string;
  className?: string;
}

/**
 * RadioCard — a single selectable card tile: white, line border, radius 14,
 * 4px card edge. Selected = pastel-mint fill, 2px navy border, navy edge.
 * Focus = pastel-blue halo. Compose inside RadioGroup for single-choice sets.
 */
export function RadioCard({ selected, onSelect, disabled, children, ariaLabel, className = "" }: RadioCardProps) {
  return (
    <button
      type="button"
      role="radio"
      aria-checked={selected}
      aria-label={ariaLabel}
      className={`ds-radio-card${selected ? " on" : ""} ${className}`.trim()}
      disabled={disabled}
      onClick={onSelect}
    >
      {children}
    </button>
  );
}
