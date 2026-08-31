-- ~/.wezterm.lua — configuracion de WezTerm (Lua).
-- Referencia de estilo: Gentleman.Dots. Adaptado a Windows + Git Bash + tema indigo.

local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- ============================================================================
--  Shell por defecto: Git Bash (login shell, para que lea ~/.bash_profile).
-- ============================================================================
config.default_prog = { "C:/Program Files/Git/bin/bash.exe", "-l" }

-- ============================================================================
--  Fuente: la Nerd Font que ya instalamos (iconos del prompt).
-- ============================================================================
config.font = wezterm.font_with_fallback({
  "CaskaydiaCove Nerd Font",
  "Cascadia Mono",
})
config.font_size = 12.0
config.line_height = 1.1

-- ============================================================================
--  Tema indigo mate (coherente con el prompt de oh-my-posh).
--  Colores propios en vez de un esquema prehecho, para que combine.
-- ============================================================================
config.colors = {
  foreground = "#E4E4EF",
  background = "#1A1A2A",
  cursor_bg = "#6C6C9E",
  cursor_border = "#6C6C9E",
  cursor_fg = "#1A1A2A",
  selection_bg = "#3B3B5C",
  selection_fg = "#E4E4EF",
  ansi = {
    "#2E2E4A", "#9E5C6C", "#6C6C9E", "#8A7A5C",
    "#4B4B7A", "#7A6C9E", "#565676", "#E4E4EF",
  },
  brights = {
    "#3B3B5C", "#b57a8a", "#8a8aba", "#a89a72",
    "#6c6c9e", "#9a8aba", "#7a7a9a", "#ffffff",
  },
  tab_bar = {
    background = "#1A1A2A",
    active_tab = { bg_color = "#4B4B7A", fg_color = "#E4E4EF" },
    inactive_tab = { bg_color = "#2E2E4A", fg_color = "#8a8aba" },
    inactive_tab_hover = { bg_color = "#3B3B5C", fg_color = "#E4E4EF" },
    new_tab = { bg_color = "#2E2E4A", fg_color = "#8a8aba" },
  },
}

-- ============================================================================
--  Ventana: look limpio, sutil, sin barra de titulo pesada.
-- ============================================================================
config.window_background_opacity = 0.98
-- TITLE | RESIZE = barra de titulo con botones (minimizar/maximizar/cerrar) + bordes.
config.window_decorations = "TITLE | RESIZE"
config.window_padding = { left = 10, right = 10, top = 8, bottom = 8 }
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = true

-- ============================================================================
--  Rendimiento.
-- ============================================================================
config.max_fps = 120
config.animation_fps = 60
config.front_end = "WebGpu"

-- ============================================================================
--  Atajos utiles (estilo tmux-lite, sin instalar tmux).
-- ============================================================================
local act = wezterm.action
config.keys = {
  -- Paneles: dividir vertical / horizontal
  { key = "d", mods = "CTRL|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "e", mods = "CTRL|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
  -- Moverse entre paneles con Ctrl+Shift+flechas
  { key = "LeftArrow",  mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Left") },
  { key = "RightArrow", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Right") },
  { key = "UpArrow",    mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Up") },
  { key = "DownArrow",  mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Down") },
  -- Cerrar panel
  { key = "w", mods = "CTRL|SHIFT", action = act.CloseCurrentPane({ confirm = true }) },
  -- Nueva pestana
  { key = "t", mods = "CTRL|SHIFT", action = act.SpawnTab("CurrentPaneDomain") },
}

return config
