# Terminal Setup

Cross-platform terminal configuration. Style reference: [Gentleman.Dots](https://github.com/Gentleman-Programming/Gentleman.Dots),
adapted for native shells (no WSL on Windows).

## Stack

| Tool | Role |
|---|---|
| **WezTerm** | Terminal emulator, configured in Lua (`.wezterm.lua`) |
| **oh-my-posh** | Prompt — custom `indigo-mate` theme |
| **atuin** | Searchable history (Up arrow / Ctrl+R) |
| **zoxide** | Smart directory jumping (`z`, `zi`) |
| **eza** | Modern `ls` with icons (auto-lists on `cd`) |
| **CaskaydiaCove Nerd Font** | Glyphs for the prompt |

The WezTerm Lua config and the prompt theme are **identical across all three
OSes**. Only the package manager and the target shell file differ.

## Shell per OS

| OS | Package manager | Shell | Config file |
|---|---|---|---|
| Windows | scoop + winget | Git Bash | `.bashrc` |
| macOS | Homebrew | zsh | `.zshrc` |
| Linux | apt / dnf / pacman | bash | `.bashrc` |

## Install

```bash
bash install.sh
```

The script detects the OS, installs only what is missing (idempotent — safe to
re-run), deploys the configs (backing up any existing file that differs), and
pre-generates the init caches so the first terminal opens fast.

## After install

Open **WezTerm**. It launches with the native shell, the Nerd Font, and the
indigo theme. On Windows, the VS Code terminal uses the same `.bashrc`, so it
looks the same there too.

### Keybindings (WezTerm)

| Keys | Action |
|---|---|
| `Ctrl+Shift+D` | Split pane horizontally |
| `Ctrl+Shift+E` | Split pane vertically |
| `Ctrl+Shift+←/→/↑/↓` | Move between panes |
| `Ctrl+Shift+T` | New tab |
| `Ctrl+Shift+W` | Close pane |

### Directory navigation

- `z <name>` — jump to the most-used directory matching `<name>`
- `zi <name>` — interactive picker among matches
- Up arrow / `Ctrl+R` — search command history (atuin)

## Files

```
install.sh              OS-detecting installer
wezterm.lua          -> ~/.wezterm.lua      (Lua config, all OSes)
indigo-mate.omp.json -> ~/.config/oh-my-posh/indigo-mate.omp.json
bashrc               -> ~/.bashrc           (Windows, Linux)
zshrc                -> ~/.zshrc            (macOS)
```

## Maintenance

Init output is cached in `~/.cache/sh-init/`. After updating a tool, refresh its
cache so the new version's init is picked up:

```bash
rm ~/.cache/sh-init/omp.sh      # or atuin.sh / zoxide.sh (.zsh on macOS)
```

## Notes

- **Windows uses bash, not zsh** — on native Windows, zsh is fragile and adds
  nothing over this stack. zsh is only used on macOS, where it is native.
- **oh-my-posh over Starship** — measured 5× faster than Starship on Windows
  (~116ms vs ~620ms per prompt). Gentleman.Dots uses Starship; this doesn't.
- The **Windows** path is tested end to end. The **macOS/Linux** branches follow
  each package manager's standard names but were not run on those platforms —
  verify on first use.
