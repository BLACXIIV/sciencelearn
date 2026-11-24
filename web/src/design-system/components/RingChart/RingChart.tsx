import { ReactNode } from "react";
import "./RingChart.css";

export interface RingSlice {
  /** 0–100 fraction of the ring. */
  value: number;
  /** Series 1–4 → --ds-chart-1..4 (lessons, quizzes, pre-test, post-test). */
  series: 1 | 2 | 3 | 4;
  label?: string;
}

export interface RingChartProps {
  slices: RingSlice[];
  /** Outer diameter in px. Default 84. */
  size?: number;
  /** Stroke width in px. Default 10. */
  thickness?: number;
  /** Center content — typically a big number + caption. */
  children?: ReactNode;
}

/**
 * RingChart — multi-series donut on a `--ds-track` base ring. Series colors
 * come from chart tokens only (chart1..4) so web and mobile rings match.
 */
export function RingChart({ slices, size = 84, thickness = 10, children }: RingChartProps) {
  const r = (size - thickness) / 2;
  const c = 2 * Math.PI * r;
  let offset = 0;
  const total = slices.reduce((s, x) => s + x.value, 0) || 1;

  return (
    <div className="ds-ring" style={{ width: size, height: size }}>
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
        <circle
          cx={size / 2} cy={size / 2} r={r}
          fill="none"
          stroke="var(--ds-track)"
          strokeWidth={thickness}
        />
        {slices.map((s, i) => {
          const len = (s.value / total) * c;
          const el = (
            <circle
              key={i}
              cx={size / 2} cy={size / 2} r={r}
              fill="none"
              stroke={`var(--ds-chart-${s.series})`}
              strokeWidth={thickness}
              strokeLinecap="round"
              strokeDasharray={`${Math.max(0, len - 2)} ${c - len + 2}`}
              strokeDashoffset={-offset}
              transform={`rotate(-90 ${size / 2} ${size / 2})`}
            >
              {s.label && <title>{s.label}</title>}
            </circle>
          );
          offset += len;
          return el;
        })}
      </svg>
      {children && <div className="ds-ring-center">{children}</div>}
    </div>
  );
}
