-- ============================================================================
--  config.lua — TUS OPCIONES. Este es el UNICO archivo que necesitas tocar.
--  Cambia un valor, guarda, y reabri WezTerm (o Ctrl+Shift+R para recargar).
-- ============================================================================

return {
  -- --- TEMA ------------------------------------------------------------------
  -- Opciones: "indigo" | "catppuccin" | "dracula" | "tokyo-night" | "gruvbox"
  theme = "indigo",

  -- --- FONDO (blur / transparencia) ------------------------------------------
  -- opacity: 1.0 = solido | 0.7 = bien translucido. Recomendado 0.8-0.9.
  opacity = 0.82,
  -- Efecto de fondo en Windows 11: "Acrylic" (blur fuerte) | "Mica" (sutil) | "Disable"
  win_backdrop = "Acrylic",
  -- Blur en macOS: 0 (nada) a 30 (fuerte).
  mac_blur = 20,

  -- --- FUENTE ----------------------------------------------------------------
  font = "CaskaydiaCove Nerd Font",
  font_size = 12.0,
  line_height = 1.1,

  -- --- VENTANA ---------------------------------------------------------------
  -- Botones de la barra de titulo. true = con minimizar/maximizar/cerrar.
  window_buttons = true,
  -- Barra de pestanas abajo (true) o arriba (false).
  tabs_at_bottom = true,
  -- Ocultar la barra de pestanas cuando hay una sola. true = mas limpio.
  hide_tabs_when_single = true,

  -- --- COMPORTAMIENTO --------------------------------------------------------
  -- Preguntar al cerrar solo si hay un proceso corriendo (true), o nunca (false).
  confirm_close = true,

  -- --- SHELL (Windows) -------------------------------------------------------
  -- Ruta al shell. En Windows apunta a Git Bash; en Mac/Linux dejalo en nil
  -- para que use el shell por defecto del sistema.
  windows_shell = "C:/Program Files/Git/bin/bash.exe",
}
