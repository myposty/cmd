#!/usr/bin/env node
// gen-prompts.mjs — genera un prompt por cada tema, copiando la ESTRUCTURA del
// prompt indigo (separadores redondos, bloques left/right) y recomputando los
// COLORES de cada segmento para ese tema.
//
// Que garantiza (en CUALQUIER tema, oscuro o claro como catppuccin-latte):
//   1. ACCENTOS COHERENTES: cada segmento usa un color real del ANSI del tema,
//      con acentos distintos entre segmentos adyacentes (las "lineas" ╭╰╮╯ ya
//      no se confunden con el fondo del OS, ni el tiempo de ejecucion con los
//      segmentos de lenguajes).
//   2. TEXTO LEGIBLE: cada segmento elige su foreground segun el brillo de SU
//      fondo (fondo claro => texto oscuro, fondo oscuro => texto claro). El
//      segmento git, que cambia de color segun el estado, ajusta SUS variantes
//      para que todas lean con el mismo texto.
//
// Uso:  node gen-prompts.mjs   ->  prompts/<tema>.omp.json (uno por tema)

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Plantilla = el prompt indigo que funciona (con separadores redondos).
const templatePath = path.join(__dirname, "indigo-mate.omp.json");
const template = JSON.parse(fs.readFileSync(templatePath, "utf8"));

// --- Lectura de temas desde themes.lua ---------------------------------------
const themesLua = fs.readFileSync(path.join(__dirname, "themes.lua"), "utf8");
const themes = {};
const blockRe = /\["([^"]+)"\]\s*=\s*\{([\s\S]*?)\n\s*\}/g;
let m;
while ((m = blockRe.exec(themesLua))) {
  const name = m[1], body = m[2];
  const get = (k) => (body.match(new RegExp(`${k}\\s*=\\s*"(#[0-9A-Fa-f]{6})"`)) || [])[1];
  const ansi = [...body.matchAll(/"(#[0-9A-Fa-f]{6})"/g)].map((x) => x[1]);
  themes[name] = { fg: get("foreground"), bg: get("background"), ansi };
}

// --- Utils de color ----------------------------------------------------------
const hex = (r, g, b) => `#${[r, g, b].map((c) => Math.max(0, Math.min(255, Math.round(c))).toString(16).padStart(2, "0")).join("")}`;
const rgb = (h) => [1, 3, 5].map((i) => parseInt(h.slice(i, i + 2), 16));
const lum = (h) => { const [r, g, b] = rgb(h); return (0.299 * r + 0.587 * g + 0.114 * b) / 255; };
const isLight = (h) => lum(h) > 0.55;
const mix = (a, b, t) => { const [r1, g1, b1] = rgb(a), [r2, g2, b2] = rgb(b); return hex(r1 + (r2 - r1) * t, g1 + (g2 - g1) * t, b1 + (b2 - b1) * t); };
const contrast = (a, b) => Math.abs(lum(a) - lum(b));
// Texto que se lee sobre un fondo: tema fg (claro) si el fondo es oscuro, tema
// bg (oscuro) si es claro. Blanco/negro puro de respaldo si el tema no contrasta.
function readFor(bgHex, theme) {
  if (isLight(bgHex)) {
    const d = theme.bg;
    if (d && contrast(d, bgHex) > 0.4) return d;
    return "#111111";
  }
  const l = theme.fg;
  if (l && contrast(l, bgHex) > 0.4) return l;
  return "#ffffff";
}
// Ajusta un fondo para que quede del mismo LADO de brillo que el segmento base
// (git/status cambian de color segun el estado) y que contraste >= minCt con su
// texto. Se mezcla hacia negro/blanco (conservando el matiz lo mejor posible)
// hasta cumplir: oscuro + contraste, o claro + contraste.
function fitSide(color, darkSide, text, minCt) {
  if (darkSide) {
    let cur = color;
    for (let i = 1; i <= 20; i++) { cur = mix(color, "#000000", i / 20); if (!isLight(cur) && contrast(cur, text) >= minCt) break; }
    return cur;
  }
  let cur = color;
  for (let i = 1; i <= 20; i++) { cur = mix(color, "#ffffff", i / 20); if (isLight(cur) && contrast(cur, text) >= minCt) break; }
  return cur;
}

// --- Acratos del prompt a partir del ANSI del tema ---------------------------
// La lista `ansi` de themes.lua empieza en fg,bg,cursor,selection y sigue con
// los 8 ansi (a[4..11]) y los 8 brights (a[12..19]).
function paletteFor(t) {
  const a = t.ansi;
  const a1 = a[5] || "#ff0000", a3 = a[7] || "#ffff00", a5 = a[9] || "#ff00ff",
        b2 = a[14] || a[6] || "#00ff00", b3 = a[15] || a3,
        b4 = a[16] || a[8] || "#0000ff", b6 = a[18] || a[10] || "#00ffff";
  const bg = t.bg, line = isLight(b4) ? mix(b4, "#000000", 0.12) : mix(b4, bg, 0.45);
  return {
    "indigo-dark":    b4,   // OS          -> azul brillante
    "indigo-mid":     b6,   // path        -> cyan brillante
    "indigo-light":   b2,   // git limpio  -> verde brillante
    "violet-muted":   b3,   // git cambios -> amarillo
    "indigo":         a5,   // lenguajes / git ahead+behind -> magenta
    "amber-muted":    a3,   // tiempo      -> amarillo (distinto de magenta)
    "danger":         a1,   // errores     -> rojo
    "indigo-darkest": bg,   // status / fondo del terminal
    "line":           line, // lineas ╰─ / ─╯
  };
}

// Token base de cada segmento + variantes (estado del git / error del status).
const SEG = {
  os:            { bg: "indigo-dark" },
  root:          { bg: "danger" },      // admin/root -> rojo (destaca)
  path:          { bg: "indigo-mid" },
  node:          { bg: "indigo" },
  go:            { bg: "indigo" },
  python:        { bg: "indigo" },
  executiontime: { bg: "amber-muted" },
  battery:       { bg: "indigo" },      // bateria
  time:          { bg: "indigo-light" },
  git:           { bg: "indigo-light", variants: { "violet-muted": "dirty", danger: "danger", indigo: "ahead" } },
  status:        { bg: "indigo-darkest", variants: { danger: "error" } },
};

function buildPrompt(t) {
  const prompt = JSON.parse(JSON.stringify(template));
  const pal = paletteFor(t);

  for (const block of prompt.blocks) {
    if (!block.segments) continue;
    for (const seg of block.segments) {
      if (seg.type === "text") { seg.foreground = pal.line; continue; } // lineas
      const conf = SEG[seg.type];
      if (!conf) continue;

      const base = pal[conf.bg];
      const text = readFor(base, t);
      seg.foreground = text;

      // Git / status: sus variantes deben leer con EL MISMO texto que el estado
      // comun. Ajustamos (con contraste garantizado y mismo lado de brillo que
      // el fondo base) colores PRIVADOS dedicados, sin distorsionar los acentos
      // que comparten otros segmentos.
      if (conf.variants) {
        const darkSide = !isLight(base);
        seg.background_templates = (seg.background_templates || []).map((tmpl) => {
          return tmpl.replace(/p:([\w-]+)/g, (_all, tok) => {
            const key = conf.variants[tok];
            if (!key) return `p:${tok}`;
            const priv = "seg-" + seg.type + "-" + key;
            pal[priv] = fitSide(pal[tok], darkSide, text, 0.58);
            return `p:${priv}`;
          });
        });
      }
    }
  }
  prompt.palette = pal;
  return prompt;
}

// --- Guardado ----------------------------------------------------------------
const outDir = path.join(__dirname, "prompts");
fs.mkdirSync(outDir, { recursive: true });
let n = 0;
for (const [name, t] of Object.entries(themes)) {
  if (!t.bg || !t.fg) continue;
  fs.writeFileSync(path.join(outDir, `${name}.omp.json`), JSON.stringify(buildPrompt(t), null, 2));
  n++;
}
console.log(`Generados ${n} prompts (mismo estilo indigo, colores por tema)`);
