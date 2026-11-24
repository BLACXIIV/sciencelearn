import { ReactNode } from "react";
import { Chip } from "../Chip/Chip";
import "./QuizCard.css";

export interface QuizCardProps {
  /** Category pill (e.g. "Pre-test", "Chapter 3"). */
  tag?: string;
  /** The question. */
  title: ReactNode;
  /** Answer area — typically a stack of QuizOption. */
  children: ReactNode;
  /** Footer row — hint, progress, nav buttons. */
  footer?: ReactNode;
}

/**
 * QuizCard — navy question panel (radius 32, navy-deep edge) with a pastel
 * category chip, white question text, and stacked options. Mirrors the
 * landing "quiz" demo and the mobile DarkPanel quiz shell.
 */
export function QuizCard({ tag, title, children, footer }: QuizCardProps) {
  return (
    <div className="ds-quiz-card">
      {tag && <Chip variant="pastel" pastelColor="mint" className="ds-quiz-tag">{tag}</Chip>}
      <div className="ds-quiz-title">{title}</div>
      <div className="ds-quiz-options">{children}</div>
      {footer && <div className="ds-quiz-footer">{footer}</div>}
    </div>
  );
}
