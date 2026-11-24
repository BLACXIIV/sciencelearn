import "./QuizNav.css";

export interface QuizNavProps {
  /** Total number of questions. */
  count: number;
  /** Index of the question being shown (0-based). */
  current: number;
  /** Per-index answered flags — unanswered dots render hollow. */
  answered: boolean[];
  /** Jump to a question index. */
  onSelect: (index: number) => void;
}

/**
 * QuizNav — numbered dots for jumping between quiz questions.
 * States: current (navy), answered (mint), unanswered (hollow).
 */
export function QuizNav({ count, current, answered, onSelect }: QuizNavProps) {
  return (
    <nav className="ds-quiznav" aria-label="Questions">
      {Array.from({ length: count }, (_, i) => {
        const state = i === current ? "current" : answered[i] ? "answered" : "unanswered";
        return (
          <button
            key={i}
            type="button"
            className="ds-quiznav-dot"
            data-state={state}
            aria-label={`Question ${i + 1}${state === "unanswered" ? " — unanswered" : state === "answered" ? " — answered" : " — current"}`}
            aria-current={i === current ? "true" : undefined}
            onClick={() => onSelect(i)}
          >
            {i + 1}
          </button>
        );
      })}
    </nav>
  );
}
