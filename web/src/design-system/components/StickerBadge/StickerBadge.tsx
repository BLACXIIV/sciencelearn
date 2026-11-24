import { ReactNode } from "react";
import "./StickerBadge.css";

export interface StickerBadgeProps {
  /** Resting rotation in degrees (audit: −5 / +5). Default −5. */
  rotation?: number;
  children: ReactNode;
  className?: string;
}

/**
 * StickerBadge — the tilted pastel sticker: white fill, radius 12, Lexend
 * 800/13, 4px black@20% edge, slightly rotated. For decorative labels over
 * hero art and auth panels — not for status (use Chip).
 */
export function StickerBadge({ rotation = -5, children, className = "" }: StickerBadgeProps) {
  return (
    <span className={`ds-sticker ${className}`} style={{ rotate: `${rotation}deg` }}>
      {children}
    </span>
  );
}
