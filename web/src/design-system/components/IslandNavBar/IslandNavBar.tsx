import { Icon } from "../../icons/Icon";
import type { NavItem } from "../NavBar/NavBar";
import "./IslandNavBar.css";

export interface IslandNavBarProps {
  items: NavItem[];
  active?: string;
  onSelect?: (key: string) => void;
}

/**
 * IslandNavBar — floating white pill nav (mobile pattern): radius 32,
 * card edge, line border, blue icon+label when active. Fixed to the
 * viewport bottom with safe-area padding; max 560px wide.
 */
export function IslandNavBar({ items, active, onSelect }: IslandNavBarProps) {
  return (
    <nav className="ds-island" aria-label="Main navigation">
      {items.map((it) => (
        <button
          key={it.key}
          type="button"
          className={`ds-island-item${active === it.key ? " on" : ""}`}
          onClick={() => onSelect?.(it.key)}
          aria-current={active === it.key ? "page" : undefined}
        >
          <Icon name={it.icon} size={22} />
          <span className="ds-island-label">{it.label}</span>
        </button>
      ))}
    </nav>
  );
}
