import type { StatItem } from "../utils/stats";

/** Config-driven stat grid — new cards appear by adding StatItems, not markup. */
export default function StatCards({ stats }: { stats: StatItem[] }) {
  return (
    <section className="stats">
      {stats.map((s) => (
        <div key={s.label} className="card stat"><span>{s.label}</span><strong>{s.value}</strong></div>
      ))}
    </section>
  );
}
