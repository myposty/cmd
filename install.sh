#!/usr/bin/env bash
# =============================================================================
#  install.sh — setup de terminal multi-OS.
#  Referencia de estilo: Gentleman.Dots, adaptado (sin WSL en Windows).
#
#  Shell por OS (shell NATIVO de cada plataforma):
#    - Windows  ->  Git Bash    (.bashrc)
#    - macOS    ->  zsh         (.zshrc)
#    - Linux    ->  bash        (.bashrc)
#
#  Stack (identico en los 3): WezTerm (Lua) + oh-my-posh + atuin + zoxide + eza
#  + CaskaydiaCove Nerd Font. La config Lua y el tema del prompt son iguales
#  en las 3 plataformas; solo cambia el gestor de paquetes y el archivo de shell.
#
#  Idempotente: corrélo las veces que quieras, instala solo lo que falta.
#  Uso:  bash install.sh
# =============================================================================
set -uo pipefail

DOTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
say()  { printf '\033[38;5;104m==>\033[0m %s\n' "$1"; }
ok()   { printf '\033[38;5;108m  ok\033[0m %s\n' "$1"; }
skip() { printf '\033[38;5;244m  --\033[0m %s (ya estaba)\n' "$1"; }
err()  { printf '\033[38;5;168m  !!\033[0m %s\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

# ============================================================================
#  1. Detectar OS y elegir gestor de paquetes + shell target.
# ============================================================================
OS="unknown"; PKG=""; SHELL_RC=""; OMP_SHELL="bash"
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) OS="windows"; SHELL_RC="$HOME/.bashrc"; OMP_SHELL="bash" ;;
  Darwin)               OS="macos";   SHELL_RC="$HOME/.zshrc";  OMP_SHELL="zsh"  ;;
  Linux)                OS="linux";   SHELL_RC="$HOME/.bashrc"; OMP_SHELL="bash" ;;
esac

# Gestor de paquetes segun OS.
if   [ "$OS" = "windows" ]; then PKG="scoop"
elif [ "$OS" = "macos" ];   then PKG="brew"
elif [ "$OS" = "linux" ];   then
  if   have apt;    then PKG="apt"
  elif have dnf;    then PKG="dnf"
  elif have pacman; then PKG="pacman"
  fi
fi

say "OS detectado: $OS | gestor: ${PKG:-ninguno} | shell: $SHELL_RC"
[ "$OS" = "unknown" ] && { err "OS no soportado."; exit 1; }
[ -z "$PKG" ]         && { err "No encontre un gestor de paquetes. Instala scoop/brew/apt/dnf/pacman."; exit 1; }

# ============================================================================
#  2. Asegurar el gestor de paquetes.
# ============================================================================
case "$PKG" in
  scoop)
    # Chequeamos la CARPETA, no solo el comando: scoop puede estar instalado en
    # disco pero fuera del PATH de esta sesion. Reinstalarlo falla ("~/scoop
    # exists and is not empty"). Solo instalamos si NO existe la carpeta.
    if ! have scoop && [ ! -d "$HOME/scoop/shims" ]; then
      say "Instalando scoop..."
      powershell.exe -NoProfile -Command "iwr -useb get.scoop.sh | iex" || { err "scoop fallo"; exit 1; }
    else
      skip "scoop"
    fi
    # Aseguramos que sus shims esten en el PATH de ESTA sesion (recien instalado
    # o ya existente), o todos los `scoop install` fallan.
    export PATH="$HOME/scoop/shims:$PATH"
    hash -r 2>/dev/null
    if ! have scoop; then err "scoop no aparece en el PATH; abri una terminal nueva y reintenta"; exit 1; fi
    scoop bucket list 2>/dev/null | grep -q "^extras"     || scoop bucket add extras     >/dev/null 2>&1
    scoop bucket list 2>/dev/null | grep -q "^nerd-fonts" || scoop bucket add nerd-fonts >/dev/null 2>&1 ;;
  brew)
    have brew || { say "Instalando Homebrew..."; /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; } ;;
  apt) sudo apt-get update -y >/dev/null 2>&1 ;;
esac

# ============================================================================
#  3. Instalar herramientas. Cada gestor con su nombre de paquete.
# ============================================================================
# pkg_install <comando> <nombre-en-cada-gestor...>  (scoop|brew|apt|dnf|pacman)
pkg_install() {
  local cmd=$1 sc=$2 br=$3 ap=$4 dn=$5 pa=$6 name
  if have "$cmd"; then skip "$cmd"; return; fi
  case "$PKG" in
    scoop)  name=$sc; scoop install "$name" >/dev/null 2>&1 ;;
    brew)   name=$br; brew install "$name"  >/dev/null 2>&1 ;;
    apt)    name=$ap; sudo apt-get install -y "$name" >/dev/null 2>&1 ;;
    dnf)    name=$dn; sudo dnf install -y "$name"     >/dev/null 2>&1 ;;
    pacman) name=$pa; sudo pacman -S --noconfirm "$name" >/dev/null 2>&1 ;;
  esac
  have "$cmd" && ok "$cmd" || err "$cmd (instalar a mano: paquete '$name')"
}
say "Instalando herramientas..."
#            cmd      scoop    brew     apt         dnf      pacman
pkg_install  atuin    atuin    atuin    atuin       atuin    atuin
pkg_install  zoxide   zoxide   zoxide   zoxide      zoxide   zoxide
pkg_install  eza      eza      eza      eza         eza      eza
pkg_install  fzf      fzf      fzf      fzf         fzf      fzf       # buscador de cd / Ctrl+F
pkg_install  fd       fd       fd       fd-find     fd-find  fd        # busqueda rapida de carpetas
hash -r 2>/dev/null  # refresca para que los shims recien instalados se vean

# WezTerm: en Windows usamos el NIGHTLY (el estable de scoop es viejo y NO tiene
# el blur Acrylic). En Mac/Linux el paquete normal ya es reciente.
if have wezterm; then skip "wezterm"
else
  say "Instalando wezterm..."
  case "$OS" in
    windows) scoop bucket add versions >/dev/null 2>&1; scoop install wezterm-nightly >/dev/null 2>&1 ;;
    macos)   brew install --cask wezterm >/dev/null 2>&1 ;;
    linux)   pkg_install wezterm wezterm wezterm wezterm wezterm wezterm ;;
  esac
  have wezterm && ok "wezterm" || err "wezterm (ver https://wezterm.org)"
fi

# oh-my-posh: en Windows por SCOOP (mismo gestor, PATH ya resuelto). winget es
# mas fragil y su PATH tampoco se refresca en la sesion.
if have oh-my-posh; then skip "oh-my-posh"
else
  say "Instalando oh-my-posh..."
  case "$OS" in
    windows) scoop install oh-my-posh >/dev/null 2>&1; hash -r 2>/dev/null ;;
    macos)   brew install jandedobbeleer/oh-my-posh/oh-my-posh >/dev/null 2>&1 ;;
    linux)   curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin >/dev/null 2>&1; export PATH="$HOME/.local/bin:$PATH" ;;
  esac
  have oh-my-posh && ok "oh-my-posh" || err "oh-my-posh (ver https://ohmyposh.dev)"
fi

# Nerd Font.
say "Nerd Font (CaskaydiaCove)..."
case "$OS" in
  windows) [ -d ~/scoop/apps/CascadiaCode-NF ] && skip "Nerd Font" || scoop install CascadiaCode-NF >/dev/null 2>&1 && ok "Nerd Font" ;;
  macos)   brew list --cask font-caskaydia-cove-nerd-font >/dev/null 2>&1 && skip "Nerd Font" || { brew tap homebrew/cask-fonts >/dev/null 2>&1; brew install --cask font-caskaydia-cove-nerd-font >/dev/null 2>&1 && ok "Nerd Font"; } ;;
  linux)
    if fc-list 2>/dev/null | grep -qi "CaskaydiaCove"; then skip "Nerd Font"
    else
      mkdir -p ~/.local/share/fonts
      curl -fsSL -o /tmp/CascadiaCode.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip >/dev/null 2>&1 \
        && unzip -o /tmp/CascadiaCode.zip -d ~/.local/share/fonts >/dev/null 2>&1 && fc-cache -f >/dev/null 2>&1 && ok "Nerd Font"
    fi ;;
esac

# ============================================================================
#  3b. Git Bash (Windows): el shell que usa todo el setup. Si falta, se instala.
# ============================================================================
GITBASH_EXE="C:/Program Files/Git/bin/bash.exe"
if [ "$OS" = "windows" ]; then
  if [ -f "$GITBASH_EXE" ]; then skip "Git Bash"
  else
    say "Git Bash no esta. Instalando (lo usa todo el setup)..."
    scoop install git >/dev/null 2>&1; hash -r 2>/dev/null
    # scoop instala git en otra ruta; detectamos el bash resultante.
    for c in "$HOME/scoop/apps/git/current/bin/bash.exe" "C:/Program Files/Git/bin/bash.exe"; do
      [ -f "$c" ] && { GITBASH_EXE="$c"; break; }
    done
    [ -f "$GITBASH_EXE" ] && ok "Git Bash" || err "Git Bash (instala Git para Windows: https://git-scm.com/download/win)"
  fi
fi

# ============================================================================
#  3c. Configurar terminales de editores (PREGUNTA cual). Windows: apunta a
#      Git Bash + fuente Nerd Font + colores indigo, para que la terminal
#      integrada se vea igual que WezTerm.
# ============================================================================
configure_editor() {  # $1 = nombre, $2 = ruta del settings.json
  local name=$1 settings=$2
  [ -d "$(dirname "$settings")" ] || return  # el editor no esta instalado
  mkdir -p "$(dirname "$settings")"
  [ -f "$settings" ] || echo '{}' > "$settings"
  # Backup antes de tocar.
  cp "$settings" "$settings.bak.$(date +%Y%m%d%H%M%S)" 2>/dev/null
  # Inyecta las claves con node si esta, o con un merge simple via python.
  if command -v node >/dev/null 2>&1; then
    node -e '
      const fs=require("fs"), f=process.argv[1], gb=process.argv[2];
      let s={}; try{ s=JSON.parse(fs.readFileSync(f,"utf8")||"{}"); }catch(e){}
      s["terminal.integrated.defaultProfile.windows"]="Git Bash";
      s["terminal.integrated.profiles.windows"]=Object.assign(s["terminal.integrated.profiles.windows"]||{},{ "Git Bash":{ path: gb } });
      s["terminal.integrated.fontFamily"]="CaskaydiaCove NF";
      fs.writeFileSync(f, JSON.stringify(s,null,2));
    ' "$settings" "$GITBASH_EXE" 2>/dev/null && ok "$name configurado" || err "$name (no pude editar el settings)"
  else
    err "$name: necesito node para editar el settings.json de forma segura"
  fi
}

if [ "$OS" = "windows" ] && [ -t 0 ]; then
  echo
  printf '\033[38;5;104m==>\033[0m Configuro la terminal integrada de tus editores con Git Bash?\n'
  printf '    [1] VS Code   [2] Cursor   [3] Ambos   [N] ninguno : '
  read -r ed
  case "$ed" in
    1) configure_editor "VS Code" "$APPDATA/Code/User/settings.json" ;;
    2) configure_editor "Cursor"  "$APPDATA/Cursor/User/settings.json" ;;
    3) configure_editor "VS Code" "$APPDATA/Code/User/settings.json"
       configure_editor "Cursor"  "$APPDATA/Cursor/User/settings.json" ;;
    *) echo "   No toco los editores." ;;
  esac
fi

# ============================================================================
#  3d. Acceso rapido a WezTerm (PREGUNTA).
#  NOTA: WezTerm NO puede ser el "terminal predeterminado" de Windows. Esa lista
#  (Config > Terminal) es exclusiva de apps que implementan la API de delegacion
#  de consola de Windows, y WezTerm no la implementa (confirmado en su doc).
#  Lo que SI sirve: un acceso directo en el escritorio para abrirlo de una.
# ============================================================================
if [ "$OS" = "windows" ] && [ -t 0 ]; then
  echo
  printf '\033[38;5;104m==>\033[0m Creo un acceso directo a WezTerm en el escritorio? [s/N] '
  read -r sc
  case "$sc" in
    s|S|y|Y)
      wt=""
      for p in "$HOME/scoop/apps/wezterm-nightly/current/wezterm-gui.exe" \
               "$HOME/scoop/apps/wezterm/current/wezterm-gui.exe"; do
        [ -f "$p" ] && { wt="$p"; break; }
      done
      if [ -n "$wt" ]; then
        wt_win=$(cygpath -w "$wt" 2>/dev/null || echo "$wt")
        desktop=$(cygpath -w "$HOME/Desktop" 2>/dev/null || echo "$HOME/Desktop")
        powershell.exe -NoProfile -Command "
          \$s = (New-Object -ComObject WScript.Shell).CreateShortcut('$desktop\\fuse-termux.lnk');
          \$s.TargetPath = '$wt_win'; \$s.Arguments = 'start';
          \$s.WorkingDirectory = '$(cygpath -w "$HOME")'; \$s.Save()
        " >/dev/null 2>&1 && ok "Acceso directo 'fuse-termux' en el escritorio" \
          || err "No pude crear el acceso directo"
      else
        err "No encontre wezterm-gui"
      fi ;;
    *) echo "   Sin acceso directo. Abrilo con: wezterm-gui" ;;
  esac
elif [ "$OS" = "linux" ] && [ -t 0 ]; then
  # En Linux el concepto SI existe (x-terminal-emulator en Debian/Ubuntu).
  echo
  printf '\033[38;5;104m==>\033[0m Pongo WezTerm como x-terminal-emulator por defecto? [s/N] '
  read -r def
  case "$def" in
    s|S|y|Y)
      if command -v update-alternatives >/dev/null 2>&1 && command -v wezterm >/dev/null 2>&1; then
        sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator "$(command -v wezterm)" 50 >/dev/null 2>&1 \
          && sudo update-alternatives --set x-terminal-emulator "$(command -v wezterm)" >/dev/null 2>&1 \
          && ok "WezTerm como x-terminal-emulator por defecto" \
          || echo "   Configuralo en Settings > Default Applications."
      else
        echo "   Configuralo en Settings > Default Applications."
      fi ;;
    *) echo "   Dejo tu terminal por defecto como esta." ;;
  esac
fi

# ============================================================================
#  4. Desplegar configuraciones (con backup si ya existian y difieren).
# ============================================================================
deploy() {  # $1 = archivo en dots, $2 = destino
  local src="$DOTS/$1" dst="$2"
  [ -f "$src" ] || { err "falta $src"; return; }
  mkdir -p "$(dirname "$dst")"
  if [ -f "$dst" ] && ! cmp -s "$src" "$dst"; then cp "$dst" "$dst.bak.$(date +%Y%m%d%H%M%S)"; fi
  cp "$src" "$dst" && ok "$dst"
}
say "Desplegando configuraciones..."
deploy indigo-mate.omp.json "$HOME/.config/oh-my-posh/indigo-mate.omp.json"
# Prompts por tema (uno por cada tema de WezTerm) para que el prompt siga al tema.
mkdir -p "$HOME/.config/oh-my-posh/prompts"
for p in "$DOTS/prompts/"*.omp.json; do
  [ -f "$p" ] && cp "$p" "$HOME/.config/oh-my-posh/prompts/"
done
ok "prompts por tema"
echo "indigo" > ~/.cache/cmd-theme 2>/dev/null  # tema inicial
deploy VERSION "$HOME/.config/cmd/VERSION"  # version instalada (para el aviso de update)
# Refresca el aviso: al instalar, la version local pasa a ser la actual, asi el
# banner de "hay version nueva" desaparece hasta que el repo suba otra.
rm -f ~/.cache/cmd-latest-version ~/.cache/cmd-version-checked 2>/dev/null
# WezTerm: la logica (wezterm.lua) + tus opciones (config.lua) + los temas (themes.lua).
# Los tres van al HOME porque .wezterm.lua hace require("config") y require("themes").
deploy wezterm.lua "$HOME/.wezterm.lua"
deploy themes.lua  "$HOME/themes.lua"
# config.lua NO se pisa si ya existe (son TUS opciones); solo se crea la 1ra vez.
if [ ! -f "$HOME/config.lua" ]; then deploy config.lua "$HOME/config.lua"
else skip "config.lua (tus opciones, no se pisan)"; fi

# Shell rc: el correcto para el OS.
if [ "$OS" = "macos" ]; then deploy zshrc "$SHELL_RC"; else deploy bashrc "$SHELL_RC"; fi

# Windows: USER/LANG en .bash_profile (Git Bash no los exporta).
if [ "$OS" = "windows" ] && ! grep -q 'export USER=' ~/.bash_profile 2>/dev/null; then
  { echo '[ -z "$USER" ] && export USER=$(id -un)'; echo '[ -z "$LANG" ] && export LANG=en_US.UTF-8'; } >> ~/.bash_profile
  ok "~/.bash_profile (USER/LANG)"
fi

# ============================================================================
#  5. Pre-generar caches de init (arranque rapido en la 1ra terminal).
# ============================================================================
say "Regenerando caches de init (limpia los viejos primero)..."
mkdir -p ~/.cache/sh-init
ext="sh"; [ "$OMP_SHELL" = "zsh" ] && ext="zsh"
rm -f ~/.cache/sh-init/omp.$ext ~/.cache/sh-init/atuin.$ext ~/.cache/sh-init/zoxide.$ext 2>/dev/null
have oh-my-posh && oh-my-posh init "$OMP_SHELL" $([ "$OMP_SHELL" = bash ] && echo --print) --config ~/.config/oh-my-posh/indigo-mate.omp.json > ~/.cache/sh-init/omp.$ext    2>/dev/null && ok "cache omp"
have atuin      && atuin init  "$OMP_SHELL" > ~/.cache/sh-init/atuin.$ext  2>/dev/null && ok "cache atuin"
have zoxide     && zoxide init "$OMP_SHELL" > ~/.cache/sh-init/zoxide.$ext 2>/dev/null && ok "cache zoxide"

# ============================================================================
#  5b. Sembrar zoxide con las carpetas de proyecto (para que `z` y el cd/Ctrl+F
#      encuentren algo desde la 1ra terminal, sin esperar a que navegues).
# ============================================================================
if have zoxide; then
  say "Sembrando zoxide con tus carpetas de proyecto..."
  seed_roots=( ~/Desktop ~/Documents ~/Projects ~/proyect ~/dev ~/code )
  seeded=0
  finder="find"
  have fd && finder="fd"
  for root in "${seed_roots[@]}"; do
    [ -d "$root" ] || continue
    if [ "$finder" = "fd" ]; then
      while IFS= read -r dir; do zoxide add "$dir" 2>/dev/null && seeded=$((seeded+1)); done \
        < <(fd -t d -d 4 . "$root" 2>/dev/null | grep -viE "node_modules|/\.git|/dist|/build|/\.next|vendor")
    else
      while IFS= read -r dir; do zoxide add "$dir" 2>/dev/null && seeded=$((seeded+1)); done \
        < <(find "$root" -maxdepth 4 -type d 2>/dev/null | grep -viE "node_modules|/\.git|/dist|/build")
    fi
  done
  ok "zoxide sembrado ($seeded carpetas)"
fi

# ============================================================================
#  6. Cierre.
# ============================================================================
echo
say "Listo en $OS."
echo "   WezTerm arranca con el shell nativo, la Nerd Font y el tema indigo."
echo "   Los caches se regeneraron; no hay que limpiar nada a mano."
echo

# Ubica el wezterm-gui: nightly (Windows) o el que este en el PATH.
_wt_gui=""
for p in "$HOME/scoop/apps/wezterm-nightly/current/wezterm-gui.exe" \
         "$HOME/scoop/apps/wezterm/current/wezterm-gui.exe"; do
  [ -f "$p" ] && { _wt_gui="$p"; break; }
done
[ -z "$_wt_gui" ] && command -v wezterm-gui >/dev/null 2>&1 && _wt_gui="wezterm-gui"

if [ "$OS" = "windows" ]; then
  say "IMPORTANTE en Windows:"
  echo "   Las herramientas se instalaron via scoop. Si abris PowerShell o CMD y"
  echo "   'wezterm' no se reconoce, es porque el PATH se refresca en una terminal"
  echo "   NUEVA. Cerra esta y abri otra, o abri WezTerm directo (abajo)."
  echo
fi

# Preguntar si abrir WezTerm (solo si lo encontramos y hay TTY interactiva).
if [ -n "$_wt_gui" ] && [ -t 0 ]; then
  printf '\033[38;5;104m==>\033[0m Abro WezTerm ahora? [s/N] '
  read -r ans
  case "$ans" in
    s|S|y|Y) "$_wt_gui" start >/dev/null 2>&1 & ok "WezTerm lanzado." ;;
    *) echo "   Cuando quieras, abrilo con: $_wt_gui" ;;
  esac
elif [ -z "$_wt_gui" ]; then
  err "No encontre wezterm-gui. Instalalo a mano: scoop install wezterm-nightly"
fi
