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
user.font           = default(user.font, "CaskaydiaCove Nerd Font")
user.font_size      = default(user.font_size, 12.0)
user.line_height    = default(user.line_height, 1.1)
user.font_ligatures = default(user.font_ligatures, false)
user.window_buttons        = default(user.window_buttons, true)
user.tabs_at_bottom        = default(user.tabs_at_bottom, true)
user.hide_tabs_when_single = default(user.hide_tabs_when_single, true)
user.padding          = default(user.padding, 10)
user.confirm_close    = default(user.confirm_close, true)
user.scrollback_lines = default(user.scrollback_lines, 10000)
user.windows_shell    = default(user.windows_shell, "C:/Program Files/Git/bin/bash.exe")

-- --- Shell (solo Windows; Mac/Linux usan el del sistema) --------------------
if wezterm.target_triple:find("windows") and user.windows_shell then
  config.default_prog = { user.windows_shell, "-l" }
end

-- --- Fuente -----------------------------------------------------------------
-- Ligaduras: si font_ligatures=false, se desactivan con harfbuzz features.
local harfbuzz = user.font_ligatures and {} or { "calt=0", "clig=0", "liga=0" }
config.font = wezterm.font_with_fallback({ user.font, "Cascadia Mono" }, { harfbuzz_features = harfbuzz })
config.font_size = user.font_size
config.line_height = user.line_height
config.scrollback_lines = user.scrollback_lines

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
-- window_background_opacity: transparencia simple, funciona en TODA version.
config.window_background_opacity = user.opacity
-- win32_system_backdrop (Acrylic/Mica) = blur REAL del escritorio, pero SOLO
-- en builds de WezTerm posteriores a 2024-03. En versiones viejas se ignora en
-- silencio (por eso "no se ve el blur"). Se activa solo si el usuario lo pide y
-- deja de aplicarse con "Disable".
if user.win_backdrop and user.win_backdrop ~= "Disable" then
  config.win32_system_backdrop = user.win_backdrop
end
config.macos_window_background_blur = user.mac_blur

-- --- Ventana ----------------------------------------------------------------
config.window_decorations = user.window_buttons and "TITLE | RESIZE" or "RESIZE"
config.window_padding = { left = user.padding, right = user.padding, top = user.padding, bottom = user.padding }
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

-- ============================================================================
--  PANEL DE CONTROL EN VIVO — cambiar opacidad/blur/tema con el teclado,
--  sin abrir ningun archivo. Los cambios son de la sesion; para dejarlos
--  permanentes, editas config.lua.
-- ============================================================================
local act = wezterm.action

-- Sube/baja la opacidad de la ventana activa en pasos de 0.05.
local function adjust_opacity(delta)
  return wezterm.action_callback(function(window, _)
    local ov = window:get_config_overrides() or {}
    local cur = ov.window_background_opacity or user.opacity
    local nv = cur + delta
    if nv > 1.0 then nv = 1.0 elseif nv < 0.30 then nv = 0.30 end
    ov.window_background_opacity = nv
    window:set_config_overrides(ov)
    window:toast_notification("WezTerm", string.format("Opacidad: %.0f%%", nv * 100), nil, 1500)
  end)
end

-- Activa/desactiva el blur (Acrylic) de la ventana activa.
local function toggle_blur()
  return wezterm.action_callback(function(window, _)
    local ov = window:get_config_overrides() or {}
    if ov.win32_system_backdrop == "Disable" then
      ov.win32_system_backdrop = "Acrylic"; ov.macos_window_background_blur = 20
      window:toast_notification("WezTerm", "Blur: ON", nil, 1500)
    else
      ov.win32_system_backdrop = "Disable"; ov.macos_window_background_blur = 0
      window:toast_notification("WezTerm", "Blur: OFF", nil, 1500)
    end
    window:set_config_overrides(ov)
  end)
end

-- Menu para elegir tema en vivo (Ctrl+Shift+P).
local function theme_picker()
  return wezterm.action_callback(function(window, pane)
    local choices = {}
    for name, _ in pairs(themes) do table.insert(choices, { label = name }) end
    table.sort(choices, function(a, b) return a.label < b.label end)
    window:perform_action(act.InputSelector({
      title = "Elegi un tema",
      choices = choices,
      action = wezterm.action_callback(function(win, _, _, label)
        if not label then return end
        local th = themes[label]
        local ov = win:get_config_overrides() or {}
        ov.colors = {
          foreground = th.foreground, background = th.background,
          cursor_bg = th.cursor, cursor_border = th.cursor, cursor_fg = th.background,
          selection_bg = th.selection, selection_fg = th.foreground,
          ansi = th.ansi, brights = th.brights,
        }
        win:set_config_overrides(ov)
        win:toast_notification("WezTerm", "Tema: " .. label, nil, 1500)
      end),
    }), pane)
  end)
end

config.keys = {
  -- Paneles (tmux-lite)
  { key = "d", mods = "CTRL|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "e", mods = "CTRL|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
  { key = "LeftArrow",  mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Left") },
  { key = "RightArrow", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Right") },
  { key = "UpArrow",    mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Up") },
  { key = "DownArrow",  mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Down") },
  { key = "w", mods = "CTRL|SHIFT", action = act.CloseCurrentPane({ confirm = true }) },
  { key = "t", mods = "CTRL|SHIFT", action = act.SpawnTab("CurrentPaneDomain") },
  { key = "r", mods = "CTRL|SHIFT", action = act.ReloadConfiguration },

  -- PANEL DE CONTROL EN VIVO (Alt+Shift no choca con el zoom de fuente):
  { key = "UpArrow",   mods = "ALT|SHIFT", action = adjust_opacity(0.05) },   -- mas opaco
  { key = "DownArrow", mods = "ALT|SHIFT", action = adjust_opacity(-0.05) },  -- mas transparente
  { key = "b", mods = "CTRL|SHIFT", action = toggle_blur() },                 -- blur on/off
  { key = "p", mods = "CTRL|SHIFT", action = theme_picker() },                -- menu de temas
  -- Resetear el zoom de fuente a lo que dice config.lua (por si se agrando).
  { key = "0", mods = "CTRL|SHIFT", action = act.ResetFontSize },
}

return config
