-- ~/.wezterm.lua — LOGICA. No hace falta tocar este archivo.
-- Tus opciones estan en config.lua; los temas en themes.lua.
-- Referencia de estilo: Gentleman.Dots. Adaptado a Windows + Git Bash.

local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- config.lua y themes.lua viven en el HOME. Los cargamos con dofile por RUTA
-- ABSOLUTA (no require), porque require depende de package.path y ese difiere
-- segun desde donde se abra WezTerm (Git Bash tiene $HOME, cmd/PowerShell no).
-- dofile con ruta absoluta es determinista en los tres. Si falla, se usa fallback.
local home = (os.getenv("HOME") or os.getenv("USERPROFILE") or "C:\\Users\\Public"):gsub("\\", "/")
local function load_lua(name)
  local ok, result = pcall(dofile, home .. "/" .. name .. ".lua")
  if ok and type(result) == "table" then return result end
  return nil
end
local user = load_lua("config") or {}
local themes = load_lua("themes")  -- nil si no se pudo cargar

-- --- Idioma para los textos de la UI (ej. confirmar cierre) ------------------
-- Windows deja LANG vacio, asi que el idioma se elige en config.lua (language).
-- "auto" intenta detectarlo del entorno; si no puede, usa ingles.
local lang_pref = (user.language or "auto"):lower()
local is_es
if lang_pref == "es" then is_es = true
elseif lang_pref == "en" then is_es = false
else
  local sys_lang = (os.getenv("LANG") or os.getenv("LANGUAGE") or os.getenv("LC_ALL") or ""):lower()
  is_es = sys_lang:find("es") == 1
end
local L = is_es and {
  close_title = "  Cerrar esta ventana?",
  close_yes = "  Si, cerrar",
  close_no = "  No, volver",
} or {
  close_title = "  Close this window?",
  close_yes = "  Yes, close",
  close_no = "  No, go back",
}

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
config.font = wezterm.font_with_fallback({ user.font, "Cascadia Mono" })
config.font_size = user.font_size
config.line_height = user.line_height
config.scrollback_lines = user.scrollback_lines
-- Ligaduras: harfbuzz_features va a nivel config (global), NO dentro de la fuente.
-- Si font_ligatures=false, se apagan con calt/clig/liga = 0.
if not user.font_ligatures then
  config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }
end

-- --- Tema (resuelto desde themes.lua; si falta todo, cae a un indigo COMPLETO) --
-- Fallback con arrays LLENOS (nunca {}), o WezTerm rompe con "Object to array".
local fallback = {
  foreground = "#E4E4EF", background = "#1A1A2A", cursor = "#6C6C9E", selection = "#3B3B5C",
  ansi    = { "#2E2E4A", "#9E5C6C", "#6C6C9E", "#8A7A5C", "#4B4B7A", "#7A6C9E", "#565676", "#E4E4EF" },
  brights = { "#3B3B5C", "#b57a8a", "#8a8aba", "#a89a72", "#6c6c9e", "#9a8aba", "#7a7a9a", "#ffffff" },
  tab_active = "#4B4B7A", tab_inactive = "#2E2E4A",
}
local t = (themes and (themes[user.theme] or themes["indigo"])) or fallback
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

-- --- Confirmacion al cerrar (en el IDIOMA del sistema) ----------------------
-- WezTerm tiene "Really kill this window?" HARDCODEADO en ingles, no se traduce.
-- Solucion: apagamos la confirmacion nativa y mostramos la nuestra, que SI
-- podemos escribir en espanol/ingles segun el idioma detectado arriba.
config.window_close_confirmation = "NeverPrompt"

if user.confirm_close then
  wezterm.on("window-close-requested", function(window, pane)
    -- Si solo hay un shell inactivo, cerrar directo (sin molestar).
    local procs = pane and pane:get_foreground_process_name() or ""
    procs = procs:lower()
    local idle = procs:find("bash") or procs:find("\\sh") or procs:find("zsh")
              or procs:find("cmd.exe") or procs:find("powershell") or procs:find("pwsh")
    if idle then return true end  -- deja cerrar sin preguntar

    -- Hay un proceso corriendo -> preguntamos en el idioma del sistema.
    window:perform_action(wezterm.action.InputSelector({
      title = L.close_title,
      choices = { { id = "yes", label = L.close_yes }, { id = "no", label = L.close_no } },
      action = wezterm.action_callback(function(win, _, id, _)
        if id == "yes" then win:perform_action(wezterm.action.QuitApplication, win:active_pane()) end
      end),
    }), pane)
    return false  -- cancelamos el cierre nativo; decide nuestro dialogo
  end)
end

-- --- Rendimiento ------------------------------------------------------------
config.max_fps = 120
config.animation_fps = 60
config.front_end = "WebGpu"

-- --- Nombre de la terminal --------------------------------------------------
-- Titulo de la ventana y de las pestanas: "fuse-termux" en vez de "bash.exe".
local TERM_NAME = "fuse-termux"
config.window_frame = { font = wezterm.font({ family = user.font or "CaskaydiaCove Nerd Font" }) }
wezterm.on("format-window-title", function() return TERM_NAME end)
wezterm.on("format-tab-title", function(tab)
  -- Muestra el nombre + el numero de pestana si hay mas de una.
  local i = tab.tab_index + 1
  return string.format("  %s %d  ", TERM_NAME, i)
end)

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

-- Aplica un tema a la ventana (usado por el picker y el preview en vivo).
local function apply_theme(win, th)
  local ov = win:get_config_overrides() or {}
  ov.colors = {
    foreground = th.foreground, background = th.background,
    cursor_bg = th.cursor, cursor_border = th.cursor, cursor_fg = th.background,
    selection_bg = th.selection, selection_fg = th.foreground,
    ansi = th.ansi, brights = th.brights,
  }
  win:set_config_overrides(ov)
end

-- Menu de temas CON VISTA PREVIA de la paleta (Ctrl+Shift+P).
-- Cada opcion muestra bloques de color del tema al lado del nombre, asi ves
-- como se ve ANTES de aplicarlo. Enter lo aplica; ESC cancela.
local function theme_picker()
  return wezterm.action_callback(function(window, pane)
    if not themes then return end
    local names = {}
    for name, _ in pairs(themes) do table.insert(names, name) end
    table.sort(names)
    local choices = {}
    for _, name in ipairs(names) do
      local th = themes[name]
      -- Bloques de color: fondo + 6 colores representativos de la paleta.
      local swatch = { { Background = { Color = th.background } }, { Foreground = { Color = th.foreground } }, { Text = " " .. name .. " " } }
      local palette = { th.ansi[2], th.ansi[3], th.ansi[5], th.ansi[6], th.ansi[7], th.cursor }
      for _, c in ipairs(palette) do
        table.insert(swatch, { Background = { Color = c } })
        table.insert(swatch, { Text = "  " })
      end
      table.insert(swatch, "ResetAttributes")
      table.insert(choices, { label = wezterm.format(swatch), id = name })
    end
    window:perform_action(act.InputSelector({
      title = "Elegi un tema  (las barras de color son la paleta de cada uno)",
      choices = choices,
      action = wezterm.action_callback(function(win, _, id, _)
        if not id then return end
        apply_theme(win, themes[id])
        win:toast_notification("WezTerm", "Tema: " .. id, nil, 1500)
      end),
    }), pane)
  end)
end

-- HELPER VISIBLE: un cheatsheet en pantalla con TODOS los atajos.
-- Se abre con Ctrl+Shift+Space. Apretas la tecla que muestra y ejecuta la accion;
-- ESC para salir sin hacer nada. No hay que memorizar nada.
local function help_menu()
  return wezterm.action_callback(function(window, pane)
    window:perform_action(act.InputSelector({
      title = "  Atajos de WezTerm  (ESC para cerrar)",
      choices = {
        { id = "split-h", label = "  Dividir panel  ->  horizontal        (Ctrl+Shift+D)" },
        { id = "split-v", label = "  Dividir panel  ->  vertical          (Ctrl+Shift+E)" },
        { id = "close",   label = "  Cerrar panel actual                  (Ctrl+Shift+W)" },
        { id = "tab",     label = "  Nueva pestana                        (Ctrl+Shift+T)" },
        { id = "op-up",   label = "  Opacidad +  (mas solido)             (F12)" },
        { id = "op-down", label = "  Opacidad -  (mas transparente)       (F11)" },
        { id = "blur",    label = "  Blur ON / OFF                        (Ctrl+Shift+B)" },
        { id = "theme",   label = "  Elegir tema                          (Ctrl+Shift+P)" },
        { id = "zoom0",   label = "  Resetear zoom de fuente              (Ctrl+Shift+0)" },
        { id = "reload",  label = "  Recargar config.lua                  (Ctrl+Shift+R)" },
      },
      action = wezterm.action_callback(function(win, p, id, _)
        if id == "split-h" then win:perform_action(act.SplitHorizontal({ domain = "CurrentPaneDomain" }), p)
        elseif id == "split-v" then win:perform_action(act.SplitVertical({ domain = "CurrentPaneDomain" }), p)
        elseif id == "close" then win:perform_action(act.CloseCurrentPane({ confirm = true }), p)
        elseif id == "tab" then win:perform_action(act.SpawnTab("CurrentPaneDomain"), p)
        elseif id == "op-up" then win:perform_action(adjust_opacity(0.05), p)
        elseif id == "op-down" then win:perform_action(adjust_opacity(-0.05), p)
        elseif id == "blur" then win:perform_action(toggle_blur(), p)
        elseif id == "theme" then win:perform_action(theme_picker(), p)
        elseif id == "zoom0" then win:perform_action(act.ResetFontSize, p)
        elseif id == "reload" then win:perform_action(act.ReloadConfiguration, p)
        end
      end),
    }), pane)
  end)
end

config.keys = {
  -- HELPER: menu con todos los atajos (para no memorizar nada). H = help.
  { key = "h", mods = "CTRL|SHIFT", action = help_menu() },

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

  -- PANEL DE CONTROL EN VIVO (teclas simples, sin combinaciones raras):
  { key = "F12", action = adjust_opacity(0.05) },   -- mas opaco
  { key = "F11", action = adjust_opacity(-0.05) },  -- mas transparente
  { key = "b", mods = "CTRL|SHIFT", action = toggle_blur() },      -- blur on/off
  { key = "p", mods = "CTRL|SHIFT", action = theme_picker() },     -- menu de temas
  { key = "0", mods = "CTRL|SHIFT", action = act.ResetFontSize },  -- resetear zoom
}

return config
