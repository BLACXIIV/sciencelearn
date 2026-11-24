import { ReactNode, useEffect } from "react";
import { createPortal } from "react-dom";
import { IconButton } from "../IconButton/IconButton";
import "./Modal.css";

export interface ModalProps {
  open: boolean;
  onClose: () => void;
  /** Lexend title. */
  title: string;
  /** Body content. */
  children?: ReactNode;
  /** Footer actions — typically Button(s). Renders right-aligned. */
  actions?: ReactNode;
  /** Accessible label override. */
  ariaLabel?: string;
}

/**
 * Modal — centered dialog: white card, radius 22, 6px card edge, dim
 * backdrop. Esc / backdrop click close. Use for confirms and small forms;
 * for mobile-style flow containers prefer BottomSheet.
 */
export function Modal({ open, onClose, title, children, actions, ariaLabel }: ModalProps) {
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
    <div className="ds-modal-backdrop" onClick={onClose}>
      <div
        className="ds-modal"
        role="dialog"
        aria-modal="true"
        aria-label={ariaLabel ?? title}
        onClick={(e) => e.stopPropagation()}
      >
        <div className="ds-modal-head">
          <h3 className="ds-h3">{title}</h3>
          <IconButton icon="close" label="Close dialog" onClick={onClose} />
        </div>
        {children && <div className="ds-modal-body ds-body-sm">{children}</div>}
        {actions && <div className="ds-modal-actions">{actions}</div>}
      </div>
    </div>,
    document.body,
  );
}
