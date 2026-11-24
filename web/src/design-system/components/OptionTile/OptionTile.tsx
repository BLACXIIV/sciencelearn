import { Icon, type IconName } from "../../icons/Icon";
import "./OptionTile.css";

export interface OptionTileProps {
  /** Registry icon shown left of the label (line icon — never emoji). */
  icon?: IconName;
  label: string;
  /** Selected = pastel fill, 2px navy border, navy edge. */
  selected?: boolean;
  /** Pastel fill when selected. Default "mint" (role picker uses mint/yellow). */
  tone?: "mint" | "yellow";
  disabled?: boolean;
  onClick?: () => void;
  /** Accessible pressed state semantics. */
  pressed?: boolean;
}

/**
 * OptionTile — the 52px selectable tile used by the sign-up role picker
 * (icon + label, mint when chosen). Use RadioCard/RadioGroup when you need
 * radiogroup semantics; OptionTile is the visual tile for standalone toggles.
 */
export function OptionTile({ icon, label, selected, tone = "mint", disabled, onClick, pressed }: OptionTileProps) {
  return (
    <button
      type="button"
      className={`ds-option-tile${selected ? ` on tone-${tone}` : ""}`}
      disabled={disabled}
      onClick={onClick}
      aria-pressed={pressed ?? selected}
    >
      {icon && <Icon name={icon} size={20} />}
      <span className="ds-option-tile-label">{label}</span>
    </button>
  );
}
