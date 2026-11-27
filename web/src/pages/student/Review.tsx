import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import {
  Card, EmptyState, Flashcard, ListItemCard, OptionTile, type IconName,
} from "../../design-system";
import { fetchFlashcards, fetchFormulas, fetchKeyTerms } from "../../services/learning";
import "./student.css";

type Kind = "flashcards" | "formulas" | "terms";

const SECTIONS: { kind: Kind; label: string; icon: IconName }[] = [
  { kind: "flashcards", label: "Flashcards", icon: "review" },
  { kind: "formulas", label: "Formula guide", icon: "formulas" },
  { kind: "terms", label: "Key terms", icon: "keyTerms" },
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
    <div className="sd-stack">
      <div className="bento bento-fit bento-xs bento-gap-xs">
        {SECTIONS.map((s) => (
          <OptionTile
            key={s.kind}
            icon={s.icon}
            label={s.label}
            selected={kind === s.kind}
            onClick={() => setKind(s.kind)}
          />
        ))}
      </div>

      {kind === null && <p className="sd-dim">Pick a section above to start reviewing.</p>}
      {list.isLoading && kind && <p className="sd-dim">Loading…</p>}
      {list.error && <p className="sd-err">{String(list.error)}</p>}
      {list.data?.length === 0 && (
        <Card>
          <EmptyState icon="inbox" title="Nothing here yet" body="Check back soon." />
        </Card>
      )}
      {list.data?.map((r, i) =>
        kind === "flashcards" ? (
          <Flashcard key={i} front={r.head} back={r.sub} />
        ) : (
          <ListItemCard key={i} title={r.head} subtitle={r.sub} />
        ),
      )}
    </div>
  );
}
