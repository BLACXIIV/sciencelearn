import { useState } from "react";
import "./Avatar.css";

export interface AvatarProps {
  /** Display name — initials are derived from it. */
  name: string;
  /** Optional image URL. Falls back to initials on error or absence. */
  src?: string;
  /** Diameter. Default 40. */
  size?: number;
  /** Initials tile fill. Rotates through the pastel set. */
  pastelColor?: "blue" | "yellow" | "purple" | "mint";
}

/**
 * Avatar — circular image or pastel initials tile with a line border.
 * Initials are up to two letters from `name`.
 */
export function Avatar({ name, src, size = 40, pastelColor = "blue" }: AvatarProps) {
  const [broken, setBroken] = useState(false);
  const initials = name.trim().split(/\s+/).slice(0, 2).map((w) => w[0]).join("").toUpperCase();

  return (
    <span
      className={`ds-avatar ds-avatar-${pastelColor}`}
      style={{ width: size, height: size, fontSize: Math.round(size * 0.38) }}
      role="img"
      aria-label={name}
    >
      {src && !broken ? (
        <img src={src} alt="" onError={() => setBroken(true)} />
      ) : (
        initials || "?"
      )}
    </span>
  );
}
