import { useState, type CSSProperties } from "react";
import { useQuery } from "@tanstack/react-query";
import { fetchFlashcards, fetchFormulas, fetchKeyTerms } from "../../services/learning";

type Kind = "flashcards" | "formulas" | "terms";

const SECTIONS: { kind: Kind; label: string; color: string; bg: string; glyph: string }[] = [
  { kind: "flashcards", label: "Flashcards", color: "#7c3aed", bg: "#ede9fe", glyph: "🃏" },
  { kind: "formulas", label: "Formula Guide", color: "#0d9488", bg: "#ccfbf1", glyph: "∑" },
  { kind: "terms", label: "Key Terms", color: "#d97706", bg: "#fef3c7", glyph: "💡" },
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
            style={{ "--tile-bg": s.bg } as CSSProperties} onClick={() => setKind(s.kind)}>
            <span className="glyph">{s.glyph}</span>
            {s.label}
          </button>
        ))}
      </div>

      {kind === null && <p className="empty">Pick a section above to start reviewing.</p>}
      {list.isLoading && kind && <p className="empty">Loading…</p>}
      {list.error && <p className="err">{String(list.error)}</p>}
      {list.data?.length === 0 && <div className="card"><p className="empty">Nothing here yet — check back soon.</p></div>}
      {list.data?.map((r, i) => (
        <div key={i} className="card">
          <strong>{r.head}</strong>
          <p>{r.sub}</p>
        </div>
      ))}
    </>
  );
}
