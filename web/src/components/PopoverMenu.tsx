import { useEffect, useLayoutEffect, useRef, useState, type ReactNode } from "react";
import { Icon, IconButton } from "../design-system";

export interface PopoverItem {
  key: string;
  label: string;
  icon?: ReactNode;
  danger?: boolean;
  disabled?: boolean;
  onSelect: () => void;
}

/**
 * "⋯" popover menu — viewport-aware (flips upward when there is no room
 * below), closes on outside pointer-down and Escape. Menu items use the
 * small-control radius + hover fill so they read like the design's chips.
 */
export default function PopoverMenu({ label = "More", items, align = "end", bare = false }: {
  label?: string;
  items: PopoverItem[];
  align?: "start" | "end";
  /** plain 20px "⋯" — no icon tile (the mockup's question-row trigger). */
  bare?: boolean;
}) {
  const [open, setOpen] = useState(false);
  const [flip, setFlip] = useState(false);
  const rootRef = useRef<HTMLDivElement>(null);
  const menuRef = useRef<HTMLDivElement>(null);

  useLayoutEffect(() => {
    if (!open) return;
    const menu = menuRef.current;
    const btn = rootRef.current?.querySelector("button");
    if (!menu || !btn) return;
    const br = btn.getBoundingClientRect();
    const mh = menu.offsetHeight;
    // Room below = viewport bottom minus the button's bottom edge.
    setFlip(window.innerHeight - br.bottom < mh + 12 && br.top > mh + 12);
  }, [open]);

  useEffect(() => {
    if (!open) return;
    const onDown = (e: PointerEvent) => {
      if (!rootRef.current?.contains(e.target as Node)) setOpen(false);
    };
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") { e.stopPropagation(); setOpen(false); }
    };
    document.addEventListener("pointerdown", onDown);
    document.addEventListener("keydown", onKey, true);
    return () => {
      document.removeEventListener("pointerdown", onDown);
      document.removeEventListener("keydown", onKey, true);
    };
  }, [open]);

  return (
    <div ref={rootRef} className={`td-pop${align === "start" ? " td-pop-start" : ""}`}>
      {bare ? (
        <button type="button" className="td-pop-btn" aria-label={label}
          aria-expanded={open} onClick={() => setOpen((o) => !o)}>
          <Icon name="more" size={20} />
        </button>
      ) : (
        <IconButton icon="more" label={label} aria-expanded={open}
          onClick={() => setOpen((o) => !o)} />
      )}
      {open && (
        <div ref={menuRef} role="menu"
          className={`td-pop-menu edge-pop${flip ? " td-pop-up" : ""}`}>
          {items.map((it) => (
            <button key={it.key} type="button" role="menuitem"
              className={`td-pop-item${it.danger ? " td-pop-item-danger" : ""}`}
              disabled={it.disabled}
              onClick={() => { setOpen(false); it.onSelect(); }}>
              {it.icon}
              <span>{it.label}</span>
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
