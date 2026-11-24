#!/usr/bin/env node
// Design-system gate for the web app.
// Pages and features may not contain raw hex colors, font families,
// border radii or box shadows — those live only in src/design-system/.
// Exits 1 and prints every violation found outside design-system/.

import { readdirSync, readFileSync, statSync } from "node:fs";
import { join, relative, sep } from "node:path";
import { fileURLToPath } from "node:url";

const SRC = join(fileURLToPath(import.meta.url), "..", "..", "src");
const EXEMPT = [
  join("design-system") + sep, // the DS layer owns all styling
  join("pages", "dev") + sep,  // the component gallery — demos --ds-* vars
];

const CSS_RULES = [
  { id: "hex-color", re: /#[0-9a-fA-F]{3,8}\b/, msg: "raw hex color" },
  { id: "box-shadow", re: /\bbox-shadow\s*:/, msg: "box-shadow" },
  {
    id: "border-radius",
    re: /\bborder(-[a-z]+)*-radius\s*:[^;}]*/,
    msg: "raw border radius",
    // 50% is a circle/oval shape, not a scale radius.
    allow: (m) => m[0].includes("var(--ds-") || /:\s*50%/.test(m[0]),
  },
  {
    id: "font-family",
    re: /\bfont-family\s*:[^;}]*/,
    msg: "font-family",
    allow: (m) => m[0].includes("var(--ds-font"),
  },
  {
    id: "font-shorthand",
    re: /^\s*font\s*:[^;}]*/m,
    msg: "font shorthand with a named family",
    allow: (m) => m[0].includes("var(--ds-font"),
  },
];

const TS_RULES = [
  { id: "hex-color", re: /["'`]\s*#[0-9a-fA-F]{3,8}\b/, msg: "raw hex color" },
  {
    id: "style-prop",
    re: /\b(fontFamily|borderRadius|borderTopLeftRadius|borderTopRightRadius|borderBottomLeftRadius|borderBottomRightRadius|boxShadow|WebkitBoxShadow|MozBoxShadow)\s*:/,
    msg: "font/radius/shadow in a style object",
  },
];

function* walk(dir) {
  for (const name of readdirSync(dir)) {
    const p = join(dir, name);
    if (statSync(p).isDirectory()) yield* walk(p);
    else yield p;
  }
}

// ---- Pass 1: collect every --ds-* variable defined inside design-system/. ----
// Any var(--ds-*) reference anywhere that is not in this set is a typo or a
// dead token — it resolves to nothing and silently drops the declaration.
const DS_DIR = join(SRC, "design-system");
const defined = new Set();
for (const file of walk(DS_DIR)) {
  if (!file.endsWith(".css") && !/\.tsx?$/.test(file)) continue;
  const src = readFileSync(file, "utf8");
  for (const m of src.matchAll(/(--ds-[a-zA-Z0-9-]+)\s*:/g)) defined.add(m[1]);
}

const findings = [];
for (const file of walk(SRC)) {
  const rel = relative(SRC, file);
  const isCss = file.endsWith(".css");
  const isTs = /\.(tsx?|jsx?)$/.test(file);
  if (!isCss && !isTs) continue;

  // Pass 2a: undefined --ds-* references — checked everywhere, DS included.
  // var(--ds-x-${...}) interpolations are masked first — dynamic names can't
  // be verified statically.
  const src = readFileSync(file, "utf8")
    .replace(/\/\*[\s\S]*?\*\//g, "")
    .replace(/\/\/[^\n]*/g, "");
  src.split("\n").forEach((line, i) => {
    const clean = line.replace(/var\(--ds-[a-zA-Z0-9-]*\$\{[^)]*\)/g, "");
    for (const m of clean.matchAll(/var\((--ds-[a-zA-Z0-9-]+)/g)) {
      if (!defined.has(m[1])) {
        findings.push(`${rel}:${i + 1}  [unknown-token] var(${m[1]}) is not defined in design-system tokens — ${line.trim()}`);
      }
    }
  });

  if (EXEMPT.some((d) => rel.startsWith(d))) continue;

  // Pass 2b: raw styling rules — pages/features only.
  const rules = isCss ? CSS_RULES : TS_RULES;
  src.split("\n").forEach((line, i) => {
    for (const r of rules) {
      const m = line.match(r.re);
      if (m && !(r.allow && r.allow(m))) {
        findings.push(`${rel}:${i + 1}  [${r.id}] ${r.msg} — ${line.trim()}`);
      }
    }
  });
}

if (findings.length) {
  console.error(`Design-system violations (${findings.length}):\n`);
  findings.forEach((f) => console.error(`  ${f}`));
  console.error(
    "\nPages/features may only use --ds-* tokens and DS components." +
      "\nIf a needed style does not exist, add it to src/design-system/."
  );
  process.exit(1);
}
console.log("Design-system check passed — no raw styling outside design-system/.");
