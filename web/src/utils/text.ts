/** Text pasted from Word/docx often carries Symbol-font glyphs smuggled as
 *  private-use characters (e.g. U+F0AE = Symbol right-arrow) that no web font
 *  can render — they show as tofu boxes. cleanText repairs the common cases,
 *  drops zero-width junk, and folds NBSP -> space. Subscript digits are real
 *  Unicode and are kept (grading folds them at compare time, not here).
 *  Idempotent — safe to run on already-clean text. */
const SYMBOL_PUA: Record<number, string> = {
  0xf0ac: "\u2190", 0xf0ad: "\u2191", 0xf0ae: "\u2192",
  0xf0af: "\u2193", 0xf0e0: "\u2192", 0xf0db: "\u21D4",
  0xf0b7: "\u2022", 0xf0b1: "\u00B1", 0xf0b4: "\u00D7",
  0xf0b8: "\u00F7", 0xf0a3: "\u2264", 0xf0b3: "\u2265",
};

/** Character-level cleaning safe on every keystroke — fixes glyphs without
 *  trimming or collapsing spaces (which would fight the user mid-edit). */
export function cleanChars(s: string): string {
  return s
    .replace(/[\uE000-\uF8FF]/g,
      (ch) => SYMBOL_PUA[ch.charCodeAt(0)] ?? "")
    .replace(/[\u21D2\u27F6\u27F9\u21E8\u2794\u279E\u279F\u27A1]/g, "\u2192")
    .replace(/\s*[-=]{1,2}>\s*/g, " \u2192 ")  // ascii arrows: -> --> =>
    .replace(/\s*<[-=]{1,2}\s*/g, " \u2190 ")  // <- <-- <=
    .replace(/[\u200B-\u200D\uFEFF]/g, "")     // zero-width + BOM
    .replace(/\u00A0/g, " ")                    // NBSP
    .normalize("NFC");                           // canonical only — keeps ₂ →
}

const SUBSCRIPTS = "\u2080\u2081\u2082\u2083\u2084\u2085\u2086\u2087\u2088\u2089";

/** Digits right after a letter or ')' are formula subscripts in this domain:
 *  '2H2 + O2 -> 2H2O' stores as '2H\u2082 + O\u2082 \u2192 2H\u2082O'.
 *  'Activity 2' / 'item 3' are untouched (a space breaks the match). Element
 *  symbols always start with a capital (H, Fe, Cl, OH groups) so the match
 *  requires '[A-Z][a-z]?' — lowercase words like 'test2' stay untouched. */
function chemSub(s: string): string {
  return s.replace(/([A-Z][a-z]?|\)|\])(\d+)/g,
    (_m, pre: string, d: string) =>
      pre + [...d].map((c) => SUBSCRIPTS[+c]).join(""));
}

export function cleanText(s: string): string {
  return chemSub(cleanChars(s).replace(/[ \t]{2,}/g, " ").trim());
}

/** cleanText applied to every string inside a JSON-ish structure (answer keys,
 *  choice lists). Object keys are ids — left untouched. */
export function cleanDeep<T>(v: T): T {
  if (typeof v === "string") return cleanText(v) as T;
  if (Array.isArray(v)) return v.map(cleanDeep) as T;
  if (v != null && typeof v === "object")
    return Object.fromEntries(
      Object.entries(v).map(([k, x]) => [k, cleanDeep(x)])) as T;
  return v;
}
