/** ScienceLearn Design System — breakpoints.
 *  Canonical set: 1024 / 760 / 480. CSS mirrors these in @media rules. */
export const breakpoints = {
  /** Desktop → tablet collapse (split screens, grids). */
  lg: 1024,
  /** Tablet → phone collapse (sidebar → top nav). */
  md: 760,
  /** Small phones. */
  sm: 480,
} as const;

export type Breakpoint = keyof typeof breakpoints;

/** Ready-to-use media query strings, e.g. `matchMedia(mq.maxLg)`. */
export const mq = {
  maxLg: "(max-width: 1024px)",
  maxMd: "(max-width: 760px)",
  maxSm: "(max-width: 480px)",
} as const;
