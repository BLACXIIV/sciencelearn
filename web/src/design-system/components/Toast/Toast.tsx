import { useEffect } from "react";
import { createPortal } from "react-dom";
import { Icon } from "../../icons/Icon";
import { IconButton } from "../IconButton/IconButton";
import "./Toast.css";

export type ToastTone = "info" | "success" | "error";

export interface ToastProps {
  open: boolean;
  /** Message — keep to one line where possible. */
  message: string;
  tone?: ToastTone;
  onClose: () => void;
  /** Auto-dismiss delay in ms. Default 4000; set 0 to disable. */
  duration?: number;
}

const toneIcon: Record<ToastTone, "info" | "done" | "alert"> = {
  info: "info",
  success: "done",
  error: "alert",
};

/**
 * Toast — bottom-center notification card: white, radius 22, 5px card edge,
 * leading status icon, close button, auto-dismiss. One at a time by
 * convention (queue in the caller if needed).
 */
export function Toast({ open, message, tone = "info", onClose, duration = 4000 }: ToastProps) {
  useEffect(() => {
    if (!open || duration <= 0) return;
    const t = setTimeout(onClose, duration);
    return () => clearTimeout(t);
  }, [open, duration, onClose]);

  if (!open) return null;
  return createPortal(
    <div className={`ds-toast ds-toast-${tone}`} role="status" aria-live="polite">
      <Icon name={toneIcon[tone]} size={20} className="ds-toast-icon" />
      <span className="ds-toast-msg">{message}</span>
      <IconButton icon="close" label="Dismiss" onClick={onClose} className="ds-toast-x" />
    </div>,
    document.body,
  );
}
