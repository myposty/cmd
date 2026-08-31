-- ~/.wezterm.lua — LOGICA. No hace falta tocar este archivo.
-- Tus opciones estan en config.lua; los temas en themes.lua.
-- Referencia de estilo: Gentleman.Dots. Adaptado a Windows + Git Bash.

local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- --- Cargar settings del usuario y temas (con fallback si faltan) -----------
local ok_cfg, user = pcall(require, "config")
if not ok_cfg then user = {} end
local ok_thm, themes = pcall(require, "themes")
if not ok_thm then themes = {} end

-- Valores por defecto: si config.lua no define algo, se usa esto.
local function default(v, d) if v == nil then return d else return v end end
user.theme        = default(user.theme, "indigo")
user.opacity      = default(user.opacity, 0.82)
user.win_backdrop = default(user.win_backdrop, "Acrylic")
user.mac_blur     = default(user.mac_blur, 20)
user.font         = default(user.font, "CaskaydiaCove Nerd Font")
user.font_size    = default(user.font_size, 12.0)
user.line_height  = default(user.line_height, 1.1)
user.window_buttons        = default(user.window_buttons, true)
user.tabs_at_bottom        = default(user.tabs_at_bottom, true)
user.hide_tabs_when_single = default(user.hide_tabs_when_single, true)
user.confirm_close = default(user.confirm_close, true)
user.windows_shell = default(user.windows_shell, "C:/Program Files/Git/bin/bash.exe")

-- --- Shell (solo Windows; Mac/Linux usan el del sistema) --------------------
if wezterm.target_triple:find("windows") and user.windows_shell then
  config.default_prog = { user.windows_shell, "-l" }
end

-- --- Fuente -----------------------------------------------------------------
config.font = wezterm.font_with_fallback({ user.font, "Cascadia Mono" })
config.font_size = user.font_size
config.line_height = user.line_height

-- --- Tema (resuelto desde themes.lua; si el nombre no existe, cae a indigo) --
local t = themes[user.theme] or themes["indigo"] or {
  foreground = "#E4E4EF", background = "#1A1A2A", cursor = "#6C6C9E",
  selection = "#3B3B5C", ansi = {}, brights = {}, tab_active = "#4B4B7A", tab_inactive = "#2E2E4A",
}
config.colors = {
  foreground = t.foreground,
  background = t.background,
  cursor_bg = t.cursor, cursor_border = t.cursor, cursor_fg = t.background,
  selection_bg = t.selection, selection_fg = t.foreground,
  ansi = t.ansi, brights = t.brights,
  tab_bar = {
    background = t.background,
    active_tab       = { bg_color = t.tab_active,   fg_color = t.foreground },
    inactive_tab     = { bg_color = t.tab_inactive, fg_color = t.foreground },
    inactive_tab_hover = { bg_color = t.selection,  fg_color = t.foreground },
    new_tab          = { bg_color = t.tab_inactive, fg_color = t.foreground },
  },
}

-- --- Fondo: blur / transparencia --------------------------------------------
config.window_background_opacity = user.opacity
if user.win_backdrop ~= "Disable" then
  config.win32_system_backdrop = user.win_backdrop
end
config.macos_window_background_blur = user.mac_blur

-- --- Ventana ----------------------------------------------------------------
config.window_decorations = user.window_buttons and "TITLE | RESIZE" or "RESIZE"
config.window_padding = { left = 10, right = 10, top = 8, bottom = 8 }
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = user.hide_tabs_when_single
config.tab_bar_at_bottom = user.tabs_at_bottom

-- --- Confirmacion al cerrar -------------------------------------------------
if user.confirm_close then
  config.window_close_confirmation = "AlwaysPrompt"
  config.skip_close_confirmation_for_processes_named = {
    "bash", "sh", "zsh", "fish", "cmd.exe", "pwsh.exe", "powershell.exe",
  }
else
  config.window_close_confirmation = "NeverPrompt"
end

-- --- Rendimiento ------------------------------------------------------------
config.max_fps = 120
config.animation_fps = 60
config.front_end = "WebGpu"

-- --- Atajos (estilo tmux-lite) ----------------------------------------------
local act = wezterm.action
config.keys = {
  { key = "d", mods = "CTRL|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "e", mods = "CTRL|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
  { key = "LeftArrow",  mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Left") },
  { key = "RightArrow", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Right") },
  { key = "UpArrow",    mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Up") },
  { key = "DownArrow",  mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Down") },
  { key = "w", mods = "CTRL|SHIFT", action = act.CloseCurrentPane({ confirm = true }) },
  { key = "t", mods = "CTRL|SHIFT", action = act.SpawnTab("CurrentPaneDomain") },
  -- Recargar la config sin cerrar WezTerm (util al cambiar config.lua).
  { key = "r", mods = "CTRL|SHIFT", action = act.ReloadConfiguration },
}

return config
