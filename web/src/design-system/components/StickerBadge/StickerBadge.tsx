import { ReactNode } from "react";
import type { CardPastel } from "../Card/Card";
import "./StickerBadge.css";

export interface StickerBadgeProps {
  /** Resting rotation in degrees (audit: −5 / +5). Default −5. */
  rotation?: number;
  /** Pastel fill; the default sticker is white. */
  pastel?: CardPastel;
  children: ReactNode;
  className?: string;
}

/**
 * StickerBadge — the tilted pastel sticker: white (or pastel) fill, radius
 * 12, Lexend 800/13, 4px black@20% edge, slightly rotated. For decorative
 * labels over hero art and auth panels — not for status (use Chip).
 */
export function StickerBadge({ rotation = -5, pastel, children, className = "" }: StickerBadgeProps) {
  return (
    <span
      className={`ds-sticker${pastel ? ` ds-sticker--${pastel}` : ""} ${className}`}
      style={{ rotate: `${rotation}deg` }}
    >
      {children}
    </span>
  );
}
