import { ReactNode } from "react";
import { Icon } from "../../icons/Icon";
import "./QuizOption.css";

export type QuizOptionState = "default" | "selected" | "correct" | "wrong" | "disabled";

export interface QuizOptionProps {
  /** A–D letter badge. */
  letter: string;
  children: ReactNode;
  /** Visual state — default | selected | correct | wrong | disabled. */
  state?: QuizOptionState;
  onClick?: () => void;
  /** Accessible label override. */
  ariaLabel?: string;
}

/**
 * QuizOption — the answer row: white, 5px edge, navy letter badge.
 * selected = blue border + pastel-blue fill; correct = mint fill + teal edge;
 * wrong = coral surface; disabled = faded, no edge. Whole row is a button.
 */
export function QuizOption({ letter, children, state = "default", onClick, ariaLabel }: QuizOptionProps) {
  const icon = state === "correct" ? "check" : state === "wrong" ? "close" : null;
  return (
    <button
      type="button"
      className={`ds-quiz-opt ds-quiz-opt-${state}`}
      onClick={onClick}
      disabled={state === "disabled"}
      aria-label={ariaLabel}
      aria-pressed={state === "selected"}
    >
      <span className="ds-quiz-letter">{letter}</span>
      <span className="ds-quiz-text">{children}</span>
      {icon && <Icon name={icon} size={20} className="ds-quiz-mark" />}
    </button>
  );
}
