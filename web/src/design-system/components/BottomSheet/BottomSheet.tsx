import { ReactNode, useEffect } from "react";
import { createPortal } from "react-dom";
import "./BottomSheet.css";

export interface BottomSheetProps {
  open: boolean;
  onClose: () => void;
  /** Sheet content — forms, option lists, confirmations. */
  children: ReactNode;
  /** Accessible label for the sheet. */
  ariaLabel?: string;
}

/**
 * BottomSheet — white sheet pinned to the viewport bottom, top corners
 * rounded 32px, decorative drag handle, dim backdrop. Esc and backdrop
 * click close it. Mirrors the mobile auth sheet.
 */
export function BottomSheet({ open, onClose, children, ariaLabel = "Bottom sheet" }: BottomSheetProps) {
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && onClose();
    document.addEventListener("keydown", onKey);
    document.body.style.overflow = "hidden";
    return () => {
      document.removeEventListener("keydown", onKey);
      document.body.style.overflow = "";
    };
  }, [open, onClose]);

  if (!open) return null;
  return createPortal(
    <div className="ds-sheet-backdrop" onClick={onClose}>
      <div
        className="ds-sheet"
        role="dialog"
        aria-modal="true"
        aria-label={ariaLabel}
        onClick={(e) => e.stopPropagation()}
      >
        <div className="ds-sheet-handle" aria-hidden="true" />
        <div className="ds-sheet-body">{children}</div>
      </div>
    </div>,
    document.body,
  );
}
