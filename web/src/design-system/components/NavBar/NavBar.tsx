import { ReactNode } from "react";
import { Icon, type IconName } from "../../icons/Icon";
import "./NavBar.css";

export interface NavItem {
  key: string;
  label: string;
  icon: IconName;
  /** Trailing chip — a Badge (NEW pill, count) or nothing. */
  badge?: ReactNode;
}

export interface NavSection {
  /** Group caption ("TEACH", "CLASS", "ADMIN") — omitted for a flat list. */
  label?: string;
  items: NavItem[];
}

export interface NavBarProps {
  /** Brand block (logo + wordmark). */
  brand: ReactNode;
  /** Flat item list — use `sections` for grouped labels. */
  items?: NavItem[];
  /** Grouped nav sections with optional group captions. */
  sections?: NavSection[];
  /** Context card between brand and nav (class switcher). */
  context?: ReactNode;
  /** Active item key. */
  active?: string;
  onSelect?: (key: string) => void;
  /** Footer block — profile, account, sign-out. */
  footer?: ReactNode;
}

/**
 * NavBar — the navy sidebar rail: brand on top, optional context card
 * (class switcher), grouped chunky nav items (radius 14, white edge when
 * active), footer pinned bottom. On ≤1024px it collapses to an icon rail;
 * on ≤760px it becomes a top bar — pair with IslandNavBar on the mobile app.
 */
export function NavBar({ brand, items, sections, context, active, onSelect, footer }: NavBarProps) {
  const groups: NavSection[] = sections ?? [{ items: items ?? [] }];
  return (
    <nav className="ds-nav" aria-label="Main navigation">
      <div className="ds-nav-brand">{brand}</div>
      {context && <div className="ds-nav-context">{context}</div>}
      <div className="ds-nav-groups">
        {groups.map((g, gi) => (
          <div className="ds-nav-sec" key={g.label ?? gi}>
            {g.label && <div className="ds-nav-sec-label">{g.label}</div>}
            <ul className="ds-nav-list">
              {g.items.map((it) => (
                <li key={it.key}>
                  <button
                    type="button"
                    className={`ds-nav-item${active === it.key ? " on" : ""}`}
                    onClick={() => onSelect?.(it.key)}
                    aria-current={active === it.key ? "page" : undefined}
                  >
                    <Icon name={it.icon} size={22} />
                    <span className="ds-nav-label">{it.label}</span>
                    {it.badge && <span className="ds-nav-badge">{it.badge}</span>}
                  </button>
                </li>
              ))}
            </ul>
          </div>
        ))}
      </div>
      {footer && <div className="ds-nav-footer">{footer}</div>}
    </nav>
  );
}
