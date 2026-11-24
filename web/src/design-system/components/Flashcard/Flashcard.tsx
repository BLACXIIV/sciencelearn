import { ReactNode, useState } from "react";
import "./Flashcard.css";

export interface FlashcardProps {
  /** Question side — shown first. */
  front: ReactNode;
  /** Answer side — revealed on flip. */
  back: ReactNode;
  className?: string;
}

/**
 * Flashcard — tap/click/Enter/Space flips between front and back.
 * A real <button>, so it is keyboard accessible out of the box.
 * Honors prefers-reduced-motion (swap, no 3D animation).
 */
export function Flashcard({ front, back, className = "" }: FlashcardProps) {
  const [flipped, setFlipped] = useState(false);
  return (
    <button
      type="button"
      className={`ds-flashcard${flipped ? " is-flipped" : ""} ${className}`}
      aria-pressed={flipped}
      aria-label={flipped ? "Flashcard — answer side. Activate to show the question." : "Flashcard — question side. Activate to show the answer."}
      onClick={() => setFlipped((f) => !f)}
    >
      <span className="ds-flashcard-in" aria-hidden="true">
        <span className="ds-flashcard-face ds-flashcard-front">{front}</span>
        <span className="ds-flashcard-face ds-flashcard-back">{back}</span>
      </span>
      {/* Screen-reader-only content for both sides (the 3D faces are aria-hidden). */}
      <span className="ds-flashcard-sr">
        {flipped ? back : front}
      </span>
    </button>
  );
}
