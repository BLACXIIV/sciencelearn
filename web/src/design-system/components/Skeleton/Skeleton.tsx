import "./Skeleton.css";

export interface SkeletonProps {
  /** Preset shapes: line (text), card, circle. */
  shape?: "line" | "card" | "circle";
  /** Explicit size overrides (px or %). */
  width?: number | string;
  height?: number | string;
  className?: string;
}

/**
 * Skeleton — shimmer placeholder using track-color fills. Compose lines and
 * cards to mirror the layout being loaded. Respects reduced motion.
 */
export function Skeleton({ shape = "line", width, height, className = "" }: SkeletonProps) {
  const style: React.CSSProperties = {};
  if (width !== undefined) style.width = typeof width === "number" ? `${width}px` : width;
  if (height !== undefined) style.height = typeof height === "number" ? `${height}px` : height;
  return <span className={`ds-skel ds-skel-${shape} ${className}`} style={style} aria-hidden="true" />;
}
