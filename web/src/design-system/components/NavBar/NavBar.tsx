import { ReactNode } from "react";
import { Icon, type IconName } from "../../icons/Icon";
import "./NavBar.css";

export interface NavItem {
  key: string;
  label: string;
  icon: IconName;
}

export interface NavBarProps {
  /** Brand block (logo + wordmark). */
  brand: ReactNode;
  items: NavItem[];
  /** Active item key. */
  active?: string;
  onSelect?: (key: string) => void;
  /** Footer block — profile, sign-out. */
  footer?: ReactNode;
}

/**
 * NavBar — the navy sidebar rail: brand on top, chunky nav items (radius 16,
 * blue edge when active), footer pinned bottom. On ≤1024px it collapses to
 * an icon rail; on ≤760px it becomes a top bar — pair with IslandNavBar on
 * the mobile app.
 */
export function NavBar({ brand, items, active, onSelect, footer }: NavBarProps) {
  return (
    <nav className="ds-nav" aria-label="Main navigation">
      <div className="ds-nav-brand">{brand}</div>
      <ul className="ds-nav-list">
        {items.map((it) => (
          <li key={it.key}>
            <button
              type="button"
              className={`ds-nav-item${active === it.key ? " on" : ""}`}
              onClick={() => onSelect?.(it.key)}
              aria-current={active === it.key ? "page" : undefined}
            >
              <Icon name={it.icon} size={20} />
              <span className="ds-nav-label">{it.label}</span>
            </button>
          </li>
        ))}
      </ul>
      {footer && <div className="ds-nav-footer">{footer}</div>}
    </nav>
  );
}
