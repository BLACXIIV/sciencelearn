// Appearance settings — stored in localStorage, applied to <html> data attrs.
// index.html has a matching boot script so there's no flash on load.

export type Mode = "system" | "dark" | "light";
export type Surface = "flat" | "glass" | "neo" | "skeuo";

export interface Accent { id: string; label: string; hex: string; on: string }

export const ACCENTS: Accent[] = [
  { id: "blue",   label: "Blue",   hex: "#4c8dff", on: "#ffffff" },
  { id: "purple", label: "Purple", hex: "#9b7bff", on: "#ffffff" },
  { id: "teal",   label: "Teal",   hex: "#2ed3b7", on: "#06201a" },
  { id: "green",  label: "Green",  hex: "#3ecf8e", on: "#062012" },
  { id: "orange", label: "Orange", hex: "#f5a623", on: "#241300" },
  { id: "pink",   label: "Pink",   hex: "#f0759c", on: "#2b0713" },
];

export const SURFACES: { id: Surface; label: string; hint: string }[] = [
  { id: "flat",  label: "Flat",        hint: "Solid panels" },
  { id: "glass", label: "Glass",       hint: "Frosted, translucent" },
  { id: "neo",   label: "Neumorphic",  hint: "Soft raised" },
  { id: "skeuo", label: "Skeuomorphic",hint: "Depth & sheen" },
];

export interface Prefs { mode: Mode; accent: string; surface: Surface }

const KEY = "sl.appearance";

export function loadPrefs(): Prefs {
  try {
    const p = JSON.parse(localStorage.getItem(KEY) ?? "{}") as Partial<Prefs>;
    return {
      mode: p.mode === "dark" || p.mode === "light" ? p.mode : "system",
      accent: ACCENTS.some((a) => a.id === p.accent) ? p.accent! : "blue",
      surface: (SURFACES.some((s) => s.id === p.surface) ? p.surface : "flat") as Surface,
    };
  } catch {
    return { mode: "system", accent: "blue", surface: "flat" };
  }
}

function resolvedMode(mode: Mode): "dark" | "light" {
  if (mode !== "system") return mode;
  return window.matchMedia("(prefers-color-scheme: light)").matches ? "light" : "dark";
}

export function applyPrefs(p: Prefs) {
  const el = document.documentElement;
  el.dataset.mode = resolvedMode(p.mode);
  el.dataset.surface = p.surface;
  const acc = ACCENTS.find((a) => a.id === p.accent) ?? ACCENTS[0];
  el.style.setProperty("--blue", acc.hex);
  el.style.setProperty("--on-accent", acc.on);
}

export function savePrefs(p: Prefs) {
  localStorage.setItem(KEY, JSON.stringify(p));
  applyPrefs(p);
}

// Follow OS changes while mode is "system".
export function watchSystem(onChange: () => void) {
  const mq = window.matchMedia("(prefers-color-scheme: light)");
  mq.addEventListener("change", onChange);
  return () => mq.removeEventListener("change", onChange);
}
