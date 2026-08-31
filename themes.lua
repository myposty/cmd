-- themes.lua — paletas disponibles. Cada tema define los mismos campos.
-- Para agregar un tema: copia un bloque, cambia los hex, dale un nombre.
-- El tema activo se elige en config.lua -> M.theme.

return {
  -- Indigo mate: el tema propio, coherente con el prompt de oh-my-posh.
  ["indigo"] = {
    foreground = "#E4E4EF", background = "#1A1A2A",
    cursor = "#6C6C9E", selection = "#3B3B5C",
    ansi    = { "#2E2E4A", "#9E5C6C", "#6C6C9E", "#8A7A5C", "#4B4B7A", "#7A6C9E", "#565676", "#E4E4EF" },
    brights = { "#3B3B5C", "#b57a8a", "#8a8aba", "#a89a72", "#6c6c9e", "#9a8aba", "#7a7a9a", "#ffffff" },
    tab_active = "#4B4B7A", tab_inactive = "#2E2E4A",
  },

  -- Catppuccin Mocha: pastel oscuro, muy popular.
  ["catppuccin"] = {
    foreground = "#CDD6F4", background = "#1E1E2E",
    cursor = "#F5E0DC", selection = "#585B70",
    ansi    = { "#45475A", "#F38BA8", "#A6E3A1", "#F9E2AF", "#89B4FA", "#F5C2E7", "#94E2D5", "#BAC2DE" },
    brights = { "#585B70", "#F38BA8", "#A6E3A1", "#F9E2AF", "#89B4FA", "#F5C2E7", "#94E2D5", "#A6ADC8" },
    tab_active = "#89B4FA", tab_inactive = "#313244",
  },

  -- Dracula: clasico oscuro con violeta y rosa.
  ["dracula"] = {
    foreground = "#F8F8F2", background = "#282A36",
    cursor = "#BD93F9", selection = "#44475A",
    ansi    = { "#21222C", "#FF5555", "#50FA7B", "#F1FA8C", "#BD93F9", "#FF79C6", "#8BE9FD", "#F8F8F2" },
    brights = { "#6272A4", "#FF6E6E", "#69FF94", "#FFFFA5", "#D6ACFF", "#FF92DF", "#A4FFFF", "#FFFFFF" },
    tab_active = "#BD93F9", tab_inactive = "#343746",
  },

  -- Tokyo Night: azul profundo, muy usado en editores.
  ["tokyo-night"] = {
    foreground = "#C0CAF5", background = "#1A1B26",
    cursor = "#7AA2F7", selection = "#33467C",
    ansi    = { "#15161E", "#F7768E", "#9ECE6A", "#E0AF68", "#7AA2F7", "#BB9AF7", "#7DCFFF", "#A9B1D6" },
    brights = { "#414868", "#F7768E", "#9ECE6A", "#E0AF68", "#7AA2F7", "#BB9AF7", "#7DCFFF", "#C0CAF5" },
    tab_active = "#7AA2F7", tab_inactive = "#24283B",
  },

  -- Gruvbox: calido, retro, marron y naranja.
  ["gruvbox"] = {
    foreground = "#EBDBB2", background = "#282828",
    cursor = "#FE8019", selection = "#504945",
    ansi    = { "#282828", "#CC241D", "#98971A", "#D79921", "#458588", "#B16286", "#689D6A", "#A89984" },
    brights = { "#928374", "#FB4934", "#B8BB26", "#FABD2F", "#83A598", "#D3869B", "#8EC07C", "#EBDBB2" },
    tab_active = "#D79921", tab_inactive = "#3C3836",
  },
}
