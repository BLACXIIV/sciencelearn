/** SVG progress ring — shared by student progress and the teacher class chart. */
export default function Ring({ pct, color, size = 64 }: { pct: number; color: string; size?: number }) {
  const r = (size - 12) / 2;
  const circ = 2 * Math.PI * r;
  const half = size / 2;
  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} aria-hidden="true">
      <circle cx={half} cy={half} r={r} fill="none" stroke="#1b2334" strokeWidth="6" />
      <circle
        cx={half} cy={half} r={r} fill="none" stroke={color} strokeWidth="6" strokeLinecap="round"
        strokeDasharray={circ} strokeDashoffset={circ * (1 - Math.min(pct, 100) / 100)}
        transform={`rotate(-90 ${half} ${half})`}
      />
      <text x={half} y={half + 4} textAnchor="middle" className="ring-pct">{Math.round(pct)}%</text>
    </svg>
  );
}
