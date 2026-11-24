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

const findings = [];
for (const file of walk(SRC)) {
  const rel = relative(SRC, file);
  if (EXEMPT.some((d) => rel.startsWith(d))) continue;
  const isCss = file.endsWith(".css");
  const isTs = /\.(tsx?|jsx?)$/.test(file);
  if (!isCss && !isTs) continue;

  const rules = isCss ? CSS_RULES : TS_RULES;
  const lines = readFileSync(file, "utf8").split("\n");
  lines.forEach((line, i) => {
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
