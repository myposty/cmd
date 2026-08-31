#!/usr/bin/env node
// gen-prompts.mjs — genera un prompt por cada tema, copiando el prompt INDIGO
// (que ya se ve bien: separadores redondos, estructura completa) y cambiando
// SOLO los 11 colores de la paleta por los derivados de cada tema.
// La estructura de segmentos NO se toca — solo el bloque "palette".
//
// Uso:  node gen-prompts.mjs   ->  prompts/<tema>.omp.json (uno por tema)

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Plantilla = el prompt indigo que funciona (con separadores redondos).
const templatePath = path.join(__dirname, "indigo-mate.omp.json");
const template = JSON.parse(fs.readFileSync(templatePath, "utf8"));

// Paleta de cada tema desde themes.lua.
const themesLua = fs.readFileSync(path.join(__dirname, "themes.lua"), "utf8");
const themes = {};
const blockRe = /\["([^"]+)"\]\s*=\s*\{([\s\S]*?)\n\s*\}/g;
let m;
while ((m = blockRe.exec(themesLua))) {
  const name = m[1], body = m[2];
  const get = (k) => (body.match(new RegExp(`${k}\\s*=\\s*"(#[0-9A-Fa-f]{6})"`)) || [])[1];
  const ansi = [...body.matchAll(/"(#[0-9A-Fa-f]{6})"/g)].map((x) => x[1]);
  themes[name] = { fg: get("foreground"), bg: get("background"), cursor: get("cursor"), ansi };
}

function mix(a, b, t) {
  const p = (h) => [1, 3, 5].map((i) => parseInt(h.slice(i, i + 2), 16));
  const [r1, g1, b1] = p(a), [r2, g2, b2] = p(b);
  const c = (x, y) => Math.round(x + (y - x) * t).toString(16).padStart(2, "0");
  return `#${c(r1, r2)}${c(g1, g2)}${c(b1, b2)}`;
}

// Deriva los 11 colores (mismos NOMBRES que el indigo) desde la paleta del tema.
// Orden de themes.lua: [fg, bg, cursor, selection, ansi0..7, bright0..7, ...]
// ANSI base = indices 4..11 (0=black 1=red 2=green 3=yellow 4=blue 5=magenta 6=cyan 7=white)
function paletteFor(t) {
  const a = t.ansi, bg = t.bg, fg = t.fg;
  const blue = a[8], green = a[6], yellow = a[7], red = a[5], magenta = a[9];
  return {
    "indigo-darkest": mix(bg, "#000000", 0.1),
    "indigo-dark":    mix(bg, fg, 0.10),
    "indigo-mid":     blue || mix(bg, fg, 0.20),   // path -> azul del tema
    "indigo":         mix(bg, fg, 0.14),
    "indigo-light":   green || mix(bg, fg, 0.25),  // git limpio -> verde del tema
    "violet-muted":   yellow || magenta,            // git con cambios -> amarillo
    "amber-muted":    mix(bg, fg, 0.14),
    "danger":         red,                          // error -> rojo del tema
    "text-light":     fg,
    "text-dark":      bg,
    "line":           blue || mix(bg, fg, 0.3),
  };
}

const outDir = path.join(__dirname, "prompts");
fs.mkdirSync(outDir, { recursive: true });
let n = 0;
for (const [name, t] of Object.entries(themes)) {
  if (!t.bg || !t.fg || !t.ansi[8]) continue;
  const prompt = JSON.parse(JSON.stringify(template)); // clon de la plantilla
  prompt.palette = paletteFor(t);                      // SOLO cambia la paleta
  fs.writeFileSync(path.join(outDir, `${name}.omp.json`), JSON.stringify(prompt, null, 2));
  n++;
}
console.log(`Generados ${n} prompts (mismo estilo indigo, colores por tema)`);
