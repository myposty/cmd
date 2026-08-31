#!/usr/bin/env node
// gen-prompts.mjs — genera un .omp.json sobrio por cada tema de themes.lua.
// Cada prompt usa hex derivados de la paleta del tema (fondos oscuros, un acento),
// asi cambia con el tema Y se ve prolijo (sin los ANSI chillones).
//
// Uso:  node gen-prompts.mjs
// Salida: prompts/<tema>.omp.json  (uno por tema)

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const themesLua = fs.readFileSync(path.join(__dirname, "themes.lua"), "utf8");

// Parse simple de themes.lua: extrae nombre + los campos que necesitamos.
const themes = {};
const blockRe = /\["([^"]+)"\]\s*=\s*\{([\s\S]*?)\n\s*\}/g;
let m;
while ((m = blockRe.exec(themesLua))) {
  const name = m[1], body = m[2];
  const get = (k) => (body.match(new RegExp(`${k}\\s*=\\s*"(#[0-9A-Fa-f]{6})"`)) || [])[1];
  const ansi = [...body.matchAll(/"(#[0-9A-Fa-f]{6})"/g)].map((x) => x[1]);
  themes[name] = {
    fg: get("foreground"),
    bg: get("background"),
    cursor: get("cursor"),
    ansi, // lista de todos los hex del bloque (bg, fg, cursor, selection, ansi[], brights[])
  };
}

// Mezcla dos hex (para derivar fondos intermedios).
function mix(a, b, t) {
  const p = (h) => [1, 3, 5].map((i) => parseInt(h.slice(i, i + 2), 16));
  const [r1, g1, b1] = p(a), [r2, g2, b2] = p(b);
  const c = (x, y) => Math.round(x + (y - x) * t).toString(16).padStart(2, "0");
  return `#${c(r1, r2)}${c(g1, g2)}${c(b1, b2)}`;
}
// Luminancia para decidir texto claro u oscuro sobre un fondo.
function lum(h) {
  const [r, g, b] = [1, 3, 5].map((i) => parseInt(h.slice(i, i + 2), 16));
  return (0.299 * r + 0.587 * g + 0.114 * b) / 255;
}
const textOn = (bgHex, light, dark) => (lum(bgHex) > 0.5 ? dark : light);

// Plantilla del prompt (misma estructura, colores parametrizados).
function buildPrompt(t) {
  const bg = t.bg;                         // fondo base del tema
  const dark = mix(bg, "#000000", 0.15);   // un poco mas oscuro que el fondo
  const s1 = mix(bg, t.fg, 0.10);          // segmento 1 (OS)
  const s2 = mix(bg, t.fg, 0.18);          // segmento 2 (path)
  const accent = t.ansi[6] || t.cursor || mix(bg, t.fg, 0.3); // acento (ansi[4]=blue-ish del tema)
  const accent2 = t.cursor || accent;
  const light = t.fg;
  const err = t.ansi[1] || "#9e5c6c";      // rojo del tema para errores
  const P = {
    "s-os": s1, "s-path": s2, "s-accent": accent, "s-accent2": accent2,
    "s-dark": dark, "danger": err,
    "text": light, "text-on-accent": textOn(accent, light, bg),
    "line": accent,
  };
  return {
    $schema: "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
    palette: P,
    blocks: [
      { alignment: "left", type: "prompt", segments: [
        { background: "p:s-os", foreground: "p:text", leading_diamond: "╭─", style: "diamond", template: " {{ if .WSL }}WSL at {{ end }}{{.Icon}} ", type: "os" },
        { background: "p:s-path", foreground: "p:text", powerline_symbol: "", options: { home_icon: "~", style: "full" }, style: "powerline", template: "  {{ .Path }} ", type: "path" },
        { background: "p:s-accent", foreground: "p:text-on-accent",
          background_templates: ["{{ if or (.Working.Changed) (.Staging.Changed) }}p:s-accent2{{ end }}"],
          powerline_symbol: "", options: { branch_icon: " ", fetch_status: true, fetch_upstream_icon: true }, style: "powerline",
          template: " {{ .UpstreamIcon }}{{ .HEAD }}{{if .BranchStatus }} {{ .BranchStatus }}{{ end }}{{ if .Working.Changed }}  {{ .Working.String }}{{ end }}{{ if .Staging.Changed }}  {{ .Staging.String }}{{ end }} ", type: "git" },
      ]},
      { alignment: "right", type: "prompt", segments: [
        { background: "p:s-dark", background_templates: ["{{ if gt .Code 0 }}p:danger{{ end }}"], foreground: "p:text", invert_powerline: true, powerline_symbol: "", options: { always_enabled: true }, style: "powerline", template: " {{ if gt .Code 0 }}{{ reason .Code }}{{ else }}{{ end }} ", type: "status" },
        { background: "p:s-accent", foreground: "p:text-on-accent", invert_powerline: true, style: "diamond", template: " {{ .CurrentDate | date .Format }}  ", trailing_diamond: "─╮", type: "time" },
      ]},
      { alignment: "left", newline: true, type: "prompt", segments: [
        { foreground: "p:line", style: "plain", template: "╰─", type: "text" },
      ]},
      { type: "rprompt", segments: [
        { foreground: "p:line", style: "plain", template: "─╯", type: "text" },
      ]},
    ],
    console_title_template: "{{ .Shell }} in {{ .Folder }}",
    final_space: true,
    version: 4,
  };
}

const outDir = path.join(__dirname, "prompts");
fs.mkdirSync(outDir, { recursive: true });
let n = 0;
for (const [name, t] of Object.entries(themes)) {
  if (!t.bg || !t.fg) continue;
  fs.writeFileSync(path.join(outDir, `${name}.omp.json`), JSON.stringify(buildPrompt(t), null, 2));
  n++;
}
console.log(`Generados ${n} prompts en ${outDir}`);
