# =============================================================================
#  .zshrc — macOS (shell nativo: zsh). Mismo stack y features que el .bashrc de
#  Windows/Git Bash: oh-my-posh + atuin + zoxide + eza, medidor RAM/CPU en vivo,
#  cambio de tema en vivo, cd inteligente, Ctrl+F, auto-update.
#
#  Trampas de zsh respecto de bash (ya resueltas abajo): no hace word-splitting
#  (${=var}), precmd en vez de PROMPT_COMMAND, $sysparams[pid] en vez de
#  $BASHPID, zle+bindkey en vez de bind -x, HISTORY_IGNORE, y en macOS no hay
#  /proc -> se mide con ps + vm_stat.
# =============================================================================

[ -z "$USER" ] && export USER=$(id -un)
[ -z "$LANG" ] && export LANG=en_US.UTF-8

# --- Splash DINAMICO: la barra avanza con la carga REAL de cada plugin -------
if [[ -o interactive ]]; then
  _SPLASH_TOTAL=4 _SPLASH_DONE=0
  _splash_start() {
    _P=$'\e[38;5;176m'; _R=$'\e[0m'
    printf '\n  %sabriendo terminalsito Uwu :3 <3%s\n\n' "$_P" "$_R"
  }
  _step() {  # $1 = nombre de lo que acaba de cargar
    _SPLASH_DONE=$((_SPLASH_DONE+1))
    _C=$'\e[38;5;104m'; _D=$'\e[38;5;60m'; _R=$'\e[0m'
    local len=24 f=$(( _SPLASH_DONE*len/_SPLASH_TOTAL ))
    local filled=$(printf '%*s' "$f" '' | tr ' ' '#')
    local empty=$(printf '%*s' "$((len-f))" '' | tr ' ' '-')
    printf '\r  %s[%s%s%s%s]%s %3d%%  %s%-18s%s' \
      "$_C" "$filled" "$_D" "$empty" "$_C" "$_R" "$(( _SPLASH_DONE*100/_SPLASH_TOTAL ))" "$_D" "$1" "$_R"
  }
  _splash_end() { printf '\n'; clear; unfunction _splash_start _step _splash_end; }
  _splash_start
fi
(( $+functions[_step] )) || _step() { : ; }

# --- PROMPT (oh-my-posh) — cambia de tema con recarga REAL -------------------
# Igual que en Windows pero SIN cygpath (en macOS la ruta unix va tal cual) y con
# `init zsh`. WezTerm manda "__settheme <nombre>" al cambiar el tema.
__settheme() {
  local t="${1:-indigo}"
  local f="$HOME/.config/oh-my-posh/prompts/$t.omp.json"
  [ -s "$f" ] || f="$HOME/.config/oh-my-posh/prompts/indigo.omp.json"   # fallback con paleta completa (NO el template)
  echo "$t" > ~/.cache/cmd-theme 2>/dev/null
  eval "$(oh-my-posh init zsh --config "$f")"                       # RECARGA REAL
}
_startup_theme=$(cat ~/.cache/cmd-theme 2>/dev/null | tr -d ' \r\n\t'); : "${_startup_theme:=indigo}"
if [ "$_startup_theme" = "indigo" ] && [ -s ~/.cache/sh-init/omp.zsh ]; then
  source ~/.cache/sh-init/omp.zsh 2>/dev/null
else
  __settheme "$_startup_theme"
fi
_step "prompt"

# --- CPU en el PROMPT (snapshot por comando), SIN daemon --------------------
# Un daemon en background muere al cerrar la pestana y deja el numero congelado.
# En su lugar: el CPU del prompt es el % de uso ENTRE comandos (delta de
# /proc/stat en Linux; instantaneo con ps en macOS, que no tiene /proc). RAM en
# el prompt va nativa (oh-my-posh sysinfo). El medidor EN VIVO vive en la barra
# de WezTerm, que lee /proc por su cuenta cada segundo (ver wezterm.lua).
case "$(uname -m 2>/dev/null)" in
  x86_64|amd64|aarch64|arm64) export POSH_CPU_ICON=$'\U000F0EE0' ;;  # 64-bit (md-cpu_64_bit)
  *)                          export POSH_CPU_ICON=$'\U000F0EDF' ;;  # 32-bit (md-cpu_32_bit)
esac
_posh_cpu() {
  if [ -r /proc/stat ]; then                                  # Linux: delta entre comandos
    local _ r idle total x pf=~/.cache/posh-cpu-prev pidle ptotal dt di
    read -r _ r < /proc/stat; set -- ${=r}; idle=$4; total=0; for x in "$@"; do total=$((total+x)); done
    if [ -f "$pf" ]; then
      read -r pidle ptotal < "$pf" 2>/dev/null
      dt=$((total-${ptotal:-0})); di=$((idle-${pidle:-0}))
      [ "$dt" -gt 0 ] && export POSH_CPU=$(( (100*(dt-di))/dt ))
    fi
    echo "$idle $total" > "$pf" 2>/dev/null
  else                                                        # macOS: instantaneo con ps
    local ncpu; ncpu=$(sysctl -n hw.ncpu 2>/dev/null || echo 1)
    export POSH_CPU="$(ps -A -o %cpu 2>/dev/null | awk -v n="$ncpu" 'NR>1{s+=$1} END{if(n>0)printf "%d",s/n}')"
  fi
}
typeset -ga precmd_functions
(( ${precmd_functions[(I)_posh_cpu]} )) || precmd_functions+=(_posh_cpu)

# --- Historial grande, sin duplicados. --------------------------------------
export HISTSIZE=50000 SAVEHIST=50000 HISTFILE="$HOME/.zsh_history"
setopt hist_ignore_all_dups hist_ignore_space share_history
# comandos internos: NO ensucian el historial (equivalente a HISTIGNORE de bash)
export HISTORY_IGNORE='(__settheme*|__cmd_update*|__cmd_changelog*)'
_step "historial"

# --- zoxide (lazy): se carga la primera vez que usas `z` o `zi`. -------------
z()  { unfunction z zi; source ~/.cache/sh-init/zoxide.zsh 2>/dev/null; z "$@"; }
zi() { unfunction z zi; source ~/.cache/sh-init/zoxide.zsh 2>/dev/null; zi "$@"; }
_step "zoxide"

# --- atuin: FLECHA ARRIBA y Ctrl+R abren el buscador de historial. ----------
source ~/.cache/sh-init/atuin.zsh 2>/dev/null
_step "atuin"
(( $+functions[_splash_end] )) && _splash_end

# --- AUTO-UPDATE (no frena el arranque) -------------------------------------
# Es UPDATE, no install: git pull donde clonaste + reconstruye prompts + despliega.
# NO reinstala herramientas ni toca tu config.lua. --ff-only no destruye nada.
__cmd_update() {
  local repo; repo=$(cat ~/.config/cmd/repo-path 2>/dev/null)
  [ -d "$repo/.git" ] || return 1
  git -C "$repo" pull -q --ff-only 2>/dev/null || return 1
  command -v node >/dev/null 2>&1 && ( cd "$repo" && node gen-prompts.mjs >/dev/null 2>&1 )
  mkdir -p ~/.config/oh-my-posh/prompts ~/.config/cmd
  cp "$repo"/indigo-mate.omp.json ~/.config/oh-my-posh/ 2>/dev/null
  cp "$repo"/prompts/*.omp.json   ~/.config/oh-my-posh/prompts/ 2>/dev/null
  cp "$repo"/themes.lua  ~/themes.lua    2>/dev/null
  cp "$repo"/wezterm.lua ~/.wezterm.lua  2>/dev/null
  cp "$repo"/zshrc       ~/.zshrc        2>/dev/null
  cp "$repo"/VERSION     ~/.config/cmd/VERSION 2>/dev/null
  rm -f ~/.cache/sh-init/omp.zsh   # regenera el cache del prompt
  return 0
}
__cmd_changelog() {
  local repo; repo=$(cat ~/.config/cmd/repo-path 2>/dev/null)
  local f="$repo/CHANGELOG.md"
  [ -s "$f" ] || return
  printf '\e[38;5;140m     Novedades %s:\e[0m\n' "$1"
  awk -v v="## $1" '$0==v{p=1;next} /^## /{p=0} p' "$f" | sed 's/^/    /'
  printf '\n'
}
if [[ -o interactive ]] && command -v curl >/dev/null 2>&1; then
  _CMD_VERSION_URL="https://raw.githubusercontent.com/myposty/cmd/main/VERSION"
  _local_ver=$(cat ~/.config/cmd/VERSION 2>/dev/null || echo "0.0.0")
  _ver_cache=~/.cache/cmd-latest-version
  _ver_stamp=~/.cache/cmd-version-checked
  _remote_ver=$(cat "$_ver_cache" 2>/dev/null)
  # semver sort portable (BSD/mac no tiene `sort -V`): campos numericos por punto.
  _newest=$(printf '%s\n%s\n' "$_local_ver" "$_remote_ver" | sort -t. -k1,1n -k2,2n -k3,3n 2>/dev/null | tail -1)
  if [ -n "$_remote_ver" ] && [ "$_remote_ver" = "$_newest" ] && [ "$_remote_ver" != "$_local_ver" ] && [ -t 0 ]; then
    printf '\e[38;5;176m  ✨ Hay una version nueva de tu terminal: %s -> %s\e[0m\n' "$_local_ver" "$_remote_ver"
    printf '\e[38;5;104m  ¿Actualizar ahora? [S/n] \e[0m'
    read -r _ans
    case "$_ans" in
      n|N|no|NO)
        printf '\e[38;5;60m     ok, mas tarde. (corre __cmd_update cuando quieras)\e[0m\n\n' ;;
      *)
        printf '\e[38;5;60m     Actualizando...\e[0m\n'
        if __cmd_update; then
          printf '\e[38;5;108m     ✓ Actualizado a %s\e[0m\n' "$_remote_ver"
          __cmd_changelog "$_remote_ver"
          __settheme "$(cat ~/.cache/cmd-theme 2>/dev/null | tr -d ' \r\n\t')"
        else
          printf '\e[38;5;168m     No se pudo actualizar solo. Proba: cd "%s" \&\& git pull\e[0m\n\n' "$(cat ~/.config/cmd/repo-path 2>/dev/null)"
        fi ;;
    esac
  fi
  if [ ! -f "$_ver_stamp" ] || [ "$(find "$_ver_stamp" -mtime +1 2>/dev/null)" ]; then
    ( curl -fsSL --max-time 3 "$_CMD_VERSION_URL" 2>/dev/null | tr -d '[:space:]' > "$_ver_cache.tmp" \
      && mv "$_ver_cache.tmp" "$_ver_cache" && touch "$_ver_stamp" ) &!
  fi
fi

# --- Panel de comandos/atajos ------------------------------------------------
help() {
  local C=$'\e[38;5;110m' K=$'\e[38;5;180m' D=$'\e[38;5;245m' R=$'\e[0m'
  printf '\n  %sComandos%s\n' "$C" "$R"
  printf '    %scd <nombre>%s    salta a una carpeta (la busca si no existe)\n' "$K" "$R"
  printf '    %sz <nombre>%s     salto rapido a las carpetas que mas usas\n' "$K" "$R"
  printf '    %shelp%s           muestra este panel\n' "$K" "$R"
  printf '    %s__cmd_update%s   actualiza la terminal a la ultima version\n' "$K" "$R"
  printf '\n  %sAtajos%s\n' "$C" "$R"
  printf '    %sCtrl+F%s         buscador de carpetas (escribi y filtra en vivo)\n' "$K" "$R"
  printf '    %sCtrl+R%s / %s↑%s    busca en tu historial de comandos\n' "$K" "$R" "$K" "$R"
  printf '    %sCtrl+Shift+.%s   cambiar tema  ·  %sCtrl+Shift+,%s vuelve\n' "$K" "$R" "$K" "$R"
  printf '    %sCtrl+Shift+P%s   menu de temas con vista previa\n' "$K" "$R"
  printf '    %sCtrl+Shift+H%s   TODOS los atajos de WezTerm\n' "$K" "$R"
  printf '    %sCtrl+Shift+D/E%s dividir la terminal en paneles\n' "$K" "$R"
  printf '    %sF11 / F12%s      mas / menos transparencia\n' "$K" "$R"
  printf '    %sCtrl+Shift+B%s   activa / desactiva el blur\n' "$K" "$R"
  printf '  %sTip: escribi %shelp%s%s cuando quieras volver a ver esto.%s\n\n' "$D" "$K" "$R" "$D" "$R"
}
if [[ -o interactive ]]; then
  _k=$'\e[38;5;109m'; _a=$'\e[38;5;66m'; _d=$'\e[38;5;245m'; _r=$'\e[0m'
  _row() { printf '   %s%-16s%s %s→%s %s%s%s\n' "$_k" "$1" "$_r" "$_a" "$_r" "$_d" "$2" "$_r"; }
  printf '%s  Que podes hacer:%s\n' "$_a" "$_r"
  _row "cd fuse"      "entra a la carpeta \"fuse\" aunque no sepas donde esta"
  _row "z fuse"       "salto rapido a una carpeta que ya visitaste antes"
  _row "Ctrl+R"       "busca un comando que ya escribiste (tu historial)"
  _row "Ctrl+Shift+." "cambia el tema de colores de la terminal"
  _row "help"         "ver la lista completa de comandos y atajos"
  printf '\n'
fi

# --- `cd` INTELIGENTE -------------------------------------------------------
_cd_roots=( ~/Desktop/proyect ~/Desktop/WORK ~/Desktop/backend-local ~/Desktop ~/projects ~/dev )
_cd_ls() { eza --icons --group-directories-first -a 2>/dev/null || ls -A ${LSCOLOR:+--color=auto}; }
cd() {
  local target="$1"
  if [ -z "$target" ]; then
    builtin cd ~ && _cd_ls; return
  fi
  if [ -d "$target" ]; then
    builtin cd "$target" && _cd_ls; return
  fi
  local results
  if command -v fd >/dev/null 2>&1; then
    results=$(fd -t d -i -d 5 "$target" "${_cd_roots[@]}" 2>/dev/null | grep -viE "node_modules|/\.git|/dist|/build|/\.next|vendor")
  else
    results=$(find "${_cd_roots[@]}" -maxdepth 5 -type d -iname "*$target*" 2>/dev/null | grep -viE "node_modules|/\.git|/dist|/build")
  fi
  if [ -z "$results" ]; then
    echo "cd: no existe '$target' ni hay carpetas que coincidan"; return 1
  fi
  local choice
  if command -v fzf >/dev/null 2>&1; then
    choice=$(printf '%s\n' "$results" | fzf --height=45% --reverse \
      --query="$target" --prompt="cd> " \
      --header="Escribi para filtrar  ·  Flechas para moverte  ·  Enter entra  ·  ESC cancela" \
      --preview 'eza --icons --color=always {} 2>/dev/null || ls -A {}' --preview-window=right:50%)
  else
    choice=$(printf '%s\n' "$results" | head -1)
  fi
  [ -n "$choice" ] && builtin cd "$choice" && _cd_ls
}

# --- Ctrl+F: buscador de carpetas EN VIVO (zle + bindkey) -------------------
_cd_fzf() {
  command -v fzf >/dev/null 2>&1 || return
  local all dir
  if command -v fd >/dev/null 2>&1; then
    all=$(fd -t d -i -d 5 . "${_cd_roots[@]}" 2>/dev/null | grep -viE "node_modules|/\.git|/dist|/build|/\.next|vendor")
  else
    all=$(find "${_cd_roots[@]}" -maxdepth 5 -type d 2>/dev/null | grep -viE "node_modules|/\.git|/dist|/build")
  fi
  dir=$(printf '%s\n' "$all" | fzf --height=45% --reverse --prompt="carpeta> " \
    --preview 'eza --icons --color=always {} 2>/dev/null || ls -A {}' --preview-window=right:50%)
  [ -n "$dir" ] && builtin cd "$dir" && _cd_ls
}
if [[ -o interactive ]]; then
  _cd_fzf_widget() { _cd_fzf; zle reset-prompt 2>/dev/null; }
  zle -N _cd_fzf_widget
  bindkey '^f' _cd_fzf_widget
fi
