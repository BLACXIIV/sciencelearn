import { ProgressBar, RingChart } from "../../design-system";

export const toneFor = (kind: string) =>
  kind === "pre_test" ? "blue" : kind === "post_test" ? "teal" : "sun";

export const csvCell = (v: unknown) => {
  const raw = `${v ?? ""}`;
  // Neutralize formula injection — cells starting with = + - @ execute as
  // spreadsheet formulas in Excel/Sheets, so prefix with an apostrophe.
  const s = /^[=+\-@]/.test(raw) ? `'${raw}` : raw;
  return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
};

export const pct = (v: number | null | undefined) =>
  v == null ? "—" : `${Math.round(v)}%`;

/** Two-column pre/post chart: blue + teal columns, labels above, track baseline. */
export function PrePostChart({ pre, post }: { pre: number | null; post: number | null }) {
  const W = 260, H = 196, base = 158, maxH = 118, bw = 56;
  const cols = [
    { label: "Pre-test", v: pre, fill: "var(--ds-blue)", x: W / 2 - bw - 24 },
    { label: "Post-test", v: post, fill: "var(--ds-teal)", x: W / 2 + 24 },
  ];
  return (
    <svg
      viewBox={`0 0 ${W} ${H}`}
      className="sr-ppchart"
      role="img"
      aria-label={`Pre-test ${pre ?? "—"}%, post-test ${post ?? "—"}%`}
    >
      {cols.map((c) => {
        const h = c.v == null ? 0 : Math.max(8, (c.v / 100) * maxH);
        return (
          <g key={c.label}>
            {c.v == null ? (
              <rect x={c.x} y={base - maxH} width={bw} height={maxH} rx={14}
                fill="none" stroke="var(--ds-track)" strokeWidth={2}
                strokeDasharray="6 6" />
            ) : (
              <rect x={c.x} y={base - h} width={bw} height={h} rx={14} fill={c.fill} />
            )}
            <text x={c.x + bw / 2} y={base - h - 10} textAnchor="middle"
              className="sr-pp-val">
              {c.v == null ? "—" : `${c.v}%`}
            </text>
            <text x={c.x + bw / 2} y={base + 22} textAnchor="middle"
              className="sr-pp-lab">
              {c.label}
            </text>
          </g>
        );
      })}
      <line x1={W / 2 - bw - 48} y1={base + 0.5} x2={W / 2 + bw + 48} y2={base + 0.5}
        stroke="var(--ds-track)" strokeWidth={2} strokeLinecap="round" />
    </svg>
  );
}

export function ReportRing({ label, value, series }: { label: string; value: number | null; series: 1 | 2 | 4 }) {
  return (
    <div className="sr-ring">
      <RingChart size={96} thickness={12}
        slices={value == null ? [] : [{ value, series }]}>
        <span className="sr-ring-val">{value == null ? "—" : `${Math.round(value)}%`}</span>
      </RingChart>
      <span className="sr-ring-lab">{label}</span>
    </div>
  );
}

/** One assessment-style score row: name, bar (or dashed empty track) and a
 *  right-aligned value. Reused by the per-student and class reports. */
export function ScoreRow({
  title, kind, score, released = true, emptyLabel = "Not taken", caption,
}: {
  title: string;
  kind: string;
  score: number | null;
  released?: boolean;
  emptyLabel?: string;
  caption?: string;
}) {
  return (
    <div className="sr-score">
      <span className="sr-score-name">
        {title}
        {caption && <span className="sr-score-sub">{caption}</span>}
      </span>
      {score == null ? (
        <>
          <span className="sr-score-dash" aria-hidden="true" />
          <span className="sr-score-val ds-caption">{emptyLabel}</span>
        </>
      ) : (
        <>
          <ProgressBar size="lg" tone={toneFor(kind)} value={score} label={title} />
          <span className="sr-score-val">{Math.round(score)}%</span>
        </>
      )}
      {!released && score != null && (
        <span className="sr-unreleased">Not released</span>
      )}
    </div>
  );
}
