import { Icon, type IconName } from "../../icons/Icon";
import "./Thumbnail.css";

export interface ThumbnailProps {
  /** Image URL. Falls back to the icon tile when absent or broken. */
  src?: string | null;
  /** Fallback tile icon (default science). */
  icon?: IconName;
  /** Square edge in px. Default 64. */
  size?: number;
  alt?: string;
}

/**
 * Thumbnail — 64px rounded image tile (radius 14) with a track-colored
 * icon fallback. Used as the leading slot in ListItemCard lesson rows.
 */
export function Thumbnail({ src, icon = "science", size = 64, alt = "" }: ThumbnailProps) {
  if (src) {
    return <img className="ds-thumb" src={src} alt={alt} loading="lazy" style={{ width: size, height: size }} />;
  }
  return (
    <span className="ds-thumb ds-thumb-ph" style={{ width: size, height: size }}>
      <Icon name={icon} size={Math.round(size * 0.45)} />
    </span>
  );
}
