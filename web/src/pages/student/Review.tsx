import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { E, type EmojiName } from "../../components/icons";
import { fetchFlashcards, fetchFormulas, fetchKeyTerms } from "../../services/learning";

type Kind = "flashcards" | "formulas" | "terms";

const SECTIONS: { kind: Kind; label: string; emoji: EmojiName }[] = [
  { kind: "flashcards", label: "Flashcards", emoji: "flashcards" },
  { kind: "formulas", label: "Formula Guide", emoji: "formulas" },
  { kind: "terms", label: "Key Terms", emoji: "keyTerms" },
];

interface Row { head: string; sub: string }

async function fetchSection(kind: Kind): Promise<Row[]> {
  if (kind === "flashcards")
    return (await fetchFlashcards()).map((r) => ({ head: r.front, sub: r.back }));
  if (kind === "formulas")
    return (await fetchFormulas()).map((r) => ({ head: r.title, sub: r.expression }));
  return (await fetchKeyTerms()).map((r) => ({ head: r.term, sub: r.definition }));
}

export default function StudentReview() {
  const [kind, setKind] = useState<Kind | null>(null);
  const list = useQuery({ queryKey: ["review", kind], queryFn: () => fetchSection(kind!), enabled: !!kind });

  return (
    <>
      <div className="tiles narrow">
        {SECTIONS.map((s) => (
          <button key={s.kind} className={`tile ${kind === s.kind ? "active" : ""}`}
            onClick={() => setKind(s.kind)}>
            <E name={s.emoji} size={44} />
            {s.label}
          </button>
        ))}
      </div>

      {kind === null && <p className="empty">Pick a section above to start reviewing.</p>}
      {list.isLoading && kind && <p className="empty">Loading…</p>}
      {list.error && <p className="err">{String(list.error)}</p>}
      {list.data?.length === 0 && <div className="card"><p className="empty">Nothing here yet, check back soon.</p></div>}
      {list.data?.map((r, i) => (
        <div key={i} className="card">
          <strong>{r.head}</strong>
          <p>{r.sub}</p>
        </div>
      ))}
    </>
  );
}
