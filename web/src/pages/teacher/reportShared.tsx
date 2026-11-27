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
