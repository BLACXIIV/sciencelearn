import { ReactNode } from "react";
import "./Chip.css";

export type ChipVariant = "white" | "pastel" | "navy" | "mint";
export type ChipPastel = "blue" | "yellow" | "purple" | "mint";

export interface ChipProps {
  /** white (default) | pastel | navy | mint */
  variant?: ChipVariant;
  /** Pastel fill when variant="pastel". */
  pastelColor?: ChipPastel;
  children: ReactNode;
  className?: string;
}

/**
 * Chip — small pill label (radius 99) for tags and quiz-type markers.
 * White variant carries the 3px card edge like the landing type pills.
 */
export function Chip({ variant = "white", pastelColor = "blue", children, className = "" }: ChipProps) {
  const cls = [
    "ds-chip",
    `ds-chip-${variant}`,
    variant === "pastel" ? `ds-chip-pastel-${pastelColor}` : "",
    className,
  ].filter(Boolean).join(" ");
  return <span className={cls}>{children}</span>;
}
