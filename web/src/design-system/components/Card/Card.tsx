import { HTMLAttributes, ReactNode } from "react";
import "./Card.css";

export type CardVariant = "white" | "pastel" | "navy" | "trivia" | "flat";
export type CardPastel = "blue" | "yellow" | "purple" | "mint";

export interface CardProps extends HTMLAttributes<HTMLDivElement> {
  /** white (default) | pastel | navy | trivia | flat */
  variant?: CardVariant;
  /** Required when variant="pastel": which pastel fill. */
  pastelColor?: CardPastel;
  /** ±1.2° tilt that flattens on hover/focus (landing mission cards). */
  tilt?: boolean;
  children: ReactNode;
}

/**
 * Card — the chunky content card. Variants:
 * - white:  white fill, 6px card edge (default)
 * - pastel: pastel fill + matching edge, use `pastelColor`
 * - navy:   navy fill, navy-deep edge — white text
 * - trivia: white fill, 5px card edge, −1.2° resting tilt ("Did you know?")
 * - flat:   white fill, 1px line border, no edge
 */
export function Card({ variant = "white", pastelColor = "blue", tilt, children, className = "", ...rest }: CardProps) {
  const cls = [
    "ds-card",
    `ds-card-${variant}`,
    variant === "pastel" ? `ds-card-pastel-${pastelColor}` : "",
    tilt ? "ds-card-tilt" : "",
    className,
  ].filter(Boolean).join(" ");
  return <div className={cls} {...rest}>{children}</div>;
}
