import { HTMLAttributes, ReactNode } from "react";
import "./Panel.css";

export interface PanelProps extends HTMLAttributes<HTMLDivElement> {
  children: ReactNode;
}

/**
 * Panel — the big navy surface (radius 32, navy-deep edge, white text):
 * quiz cards, hero dark panels, call-to-action bands.
 */
export function Panel({ children, className = "", ...rest }: PanelProps) {
  return (
    <div className={`ds-panel ${className}`} {...rest}>
      {children}
    </div>
  );
}
