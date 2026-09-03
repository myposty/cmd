# =============================================================================
#  .bashrc — arranque minimo. En Git Bash/Windows CADA proceso cuesta ~50ms,
#  asi que la regla es: la MENOR cantidad de comandos posible al abrir.
#  Nada de `command -v`, `mkdir`, ni regeneracion de caches en el arranque.
# =============================================================================

[ -z "$USER" ] && export USER=$(id -un)
[ -z "$LANG" ] && export LANG=en_US.UTF-8

# Sin splash: la barra "cargando" gastaba ~400ms en forks de `tr` (2 por paso, 4
# pasos) SOLO para dibujarse, y encima ES lo que se ve cargar. La terminal ahora
# arranca directo al prompt. Lo que tarda de verdad (oh-my-posh, atuin) es el piso
# real de esas herramientas, no un adorno.

# --- PROMPT (oh-my-posh) — cambia de tema con recarga REAL -------------------
# oh-my-posh carga su config UNA vez por sesion; cambiar POSH_CONFIG a mitad NO
# lo obliga a releer. La forma que SI funciona es re-ejecutar `oh-my-posh init`
# con el config del tema nuevo: eso reinstala el prompt con esos colores.
# WezTerm, al cambiar el tema, manda "__settheme <nombre>" a esta terminal.
__settheme() {
  local t="${1:-indigo}"
  local f="$HOME/.config/oh-my-posh/prompts/$t.omp.json"
  [ -s "$f" ] || f="$HOME/.config/oh-my-posh/prompts/indigo.omp.json"   # fallback con paleta completa (NO el template)
  echo "$t" > ~/.cache/cmd-theme 2>/dev/null                       # recuerda el tema
  # Reconstruye el prompt Y reescribe el cache (--print, igual que install.sh).
  # Asi la PROXIMA terminal source-a el cache (~50ms) en vez de correr
  # oh-my-posh en vivo (700-2000ms). Sirve para CUALQUIER tema, no solo indigo.
  mkdir -p ~/.cache/sh-init 2>/dev/null
  oh-my-posh init bash --print --config "$(cygpath -w "$f")" > ~/.cache/sh-init/omp.sh 2>/dev/null
  source ~/.cache/sh-init/omp.sh 2>/dev/null                      # RECARGA REAL
}

# Al abrir la terminal: usar el ultimo tema elegido (o indigo). El cache rapido
# sirve para indigo; para otro tema se re-inicializa (una vez, al abrir).
_startup_theme=$(cat ~/.cache/cmd-theme 2>/dev/null | tr -d ' \r\n\t'); : "${_startup_theme:=indigo}"
# Camino rapido para CUALQUIER tema: el cache omp.sh ya corresponde al ultimo
# tema elegido (lo escribe __settheme). Si falta (primer arranque o post-update
# que lo borra), __settheme lo reconstruye una vez y lo deja listo para las demas.
if [ -s ~/.cache/sh-init/omp.sh ]; then
  source ~/.cache/sh-init/omp.sh 2>/dev/null
else
  __settheme "$_startup_theme"
fi

# RAM/CPU/bateria en vivo viven en la barra de WezTerm (ver wezterm.lua). El
# prompt ya no los muestra, asi que aca no se mide nada.

# --- Historial grande, sin duplicados. --------------------------------------
export HISTSIZE=50000 HISTFILESIZE=50000 HISTCONTROL=ignoreboth:erasedups
export HISTIGNORE="__settheme*:__cmd_update*:__cmd_changelog*"   # comandos internos: NO ensucian el historial
shopt -s histappend

# --- zoxide (lazy): se carga la primera vez que usas `z` o `zi`. -------------
z()  { unset -f z zi; source ~/.cache/sh-init/zoxide.sh 2>/dev/null; z "$@"; }
zi() { unset -f z zi; source ~/.cache/sh-init/zoxide.sh 2>/dev/null; zi "$@"; }

# --- atuin: FLECHA ARRIBA y Ctrl+R abren el buscador de historial. ----------
source ~/.cache/sh-init/atuin.sh 2>/dev/null

# --- AUTO-UPDATE (no frena el arranque) -------------------------------------
# Es UPDATE, no install: git pull en donde clonaste + reconstruye los prompts +
# despliega los configs. NO reinstala herramientas, NO pregunta nada, y NO toca
# tu config.lua (tus opciones). --ff-only NO destruye cambios locales: si hay
# divergencia, no actualiza (no se pierde nada).
__cmd_update() {
  local repo; repo=$(cat ~/.config/cmd/repo-path 2>/dev/null)
  [ -d "$repo/.git" ] || return 1
  git -C "$repo" pull -q --ff-only 2>/dev/null || return 1     # no destruye nada
  command -v node >/dev/null 2>&1 && ( cd "$repo" && node gen-prompts.mjs >/dev/null 2>&1 )  # reconstruye
  mkdir -p ~/.config/oh-my-posh/prompts ~/.config/cmd
  cp "$repo"/indigo-mate.omp.json ~/.config/oh-my-posh/ 2>/dev/null
  cp "$repo"/prompts/*.omp.json   ~/.config/oh-my-posh/prompts/ 2>/dev/null
  cp "$repo"/themes.lua  ~/themes.lua    2>/dev/null
  cp "$repo"/wezterm.lua ~/.wezterm.lua  2>/dev/null
  cp "$repo"/bashrc      ~/.bashrc       2>/dev/null
  cp "$repo"/VERSION     ~/.config/cmd/VERSION 2>/dev/null   # ultimo: marca actualizado
  rm -f ~/.cache/sh-init/omp.sh   # regenera el cache del prompt
  return 0
}
# Muestra el changelog de una version (la seccion "## X" de CHANGELOG.md).
__cmd_changelog() {
  local repo; repo=$(cat ~/.config/cmd/repo-path 2>/dev/null)
  local f="$repo/CHANGELOG.md"
  [ -s "$f" ] || return
  printf '\e[38;5;140m     Novedades %s:\e[0m\n' "$1"
  awk -v v="## $1" '$0==v{p=1;next} /^## /{p=0} p' "$f" | sed 's/^/    /'
  printf '\n'
}
if [[ $- == *i* ]] && command -v curl >/dev/null 2>&1; then
  _CMD_VERSION_URL="https://raw.githubusercontent.com/myposty/cmd/main/VERSION"
  _local_ver=$(cat ~/.config/cmd/VERSION 2>/dev/null || echo "0.0.0")
  _ver_cache=~/.cache/cmd-latest-version
  _ver_stamp=~/.cache/cmd-version-checked
  _remote_ver=$(cat "$_ver_cache" 2>/dev/null)
  # Solo ofrece update si la del repo es MAS NUEVA (no si es distinta o menor).
  _newest=$(printf '%s\n%s\n' "$_local_ver" "$_remote_ver" | sort -V 2>/dev/null | tail -1)
  # Hay update -> PREGUNTA. Si aceptas, actualiza A LA VISTA y recarga el prompt
  # al instante (sin reabrir). Respeta tu tema elegido (no toca cmd-theme).
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
          # Changelog de esta version (solo aca, una vez, tras actualizar).
          __cmd_changelog "$_remote_ver"
          # Recarga el prompt con el tema elegido, para ver los cambios YA.
          __settheme "$(cat ~/.cache/cmd-theme 2>/dev/null | tr -d ' \r\n\t')"
        else
          printf '\e[38;5;168m     No se pudo actualizar solo. Proba: cd "%s" \&\& git pull\e[0m\n\n' "$(cat ~/.config/cmd/repo-path 2>/dev/null)"
        fi ;;
    esac
  fi
  # Chequea GitHub una vez por dia, en background.
  if [ ! -f "$_ver_stamp" ] || [ "$(find "$_ver_stamp" -mtime +1 2>/dev/null)" ]; then
    ( curl -fsSL --max-time 3 "$_CMD_VERSION_URL" 2>/dev/null | tr -d '[:space:]' > "$_ver_cache.tmp" \
      && mv "$_ver_cache.tmp" "$_ver_cache" && touch "$_ver_stamp" ) &
    disown 2>/dev/null
  fi
fi

# --- Panel de comandos/atajos ------------------------------------------------
# `help` lo muestra completo cuando quieras. Al abrir la terminal sale una
# version compacta para que sepas que podes hacer.
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
# El panel "Que podes hacer" ya NO sale en cada arranque (era ruido y sumaba al
# tiempo percibido). Queda una linea sola, sin forks: escribi `help` para verlo.
[[ $- == *i* ]] && printf '\e[38;5;245m  escribi \e[38;5;180mhelp\e[38;5;245m para ver comandos y atajos\e[0m\n'

# --- `cd` INTELIGENTE -------------------------------------------------------
# Escribi "cd nombre":
#   - Si "nombre" ES una carpeta exacta        -> entra normal (cd de siempre).
#   - Si NO, busca carpetas que coincidan y abre un menu con FLECHAS + Enter.
#   - Sin argumento -> cd al HOME (como el cd normal).
# Al entrar, lista el contenido. Menu con flechas via fzf.
_cd_roots=( ~/Desktop/proyect ~/Desktop/WORK ~/Desktop/backend-local ~/Desktop )
cd() {
  local target="$1"
  if [ -z "$target" ]; then
    builtin cd ~ && _cd_ls; return
  fi
  # 1) Si es una ruta que existe, entra directo (comportamiento normal).
  if [ -d "$target" ]; then
    builtin cd "$target" && _cd_ls; return
  fi
  # 2) No existe tal cual -> busco carpetas que coincidan por nombre.
  local results
  if command -v fd >/dev/null 2>&1; then
    results=$(fd -t d -i -d 5 "$target" "${_cd_roots[@]}" 2>/dev/null | grep -viE "node_modules|/\.git|/dist|/build|/\.next|vendor")
  else
    results=$(find "${_cd_roots[@]}" -maxdepth 5 -type d -iname "*$target*" 2>/dev/null | grep -viE "node_modules|/\.git|/dist|/build")
  fi
  if [ -z "$results" ]; then
    echo "cd: no existe '$target' ni hay carpetas que coincidan"; return 1
  fi
  # 3) Menu con flechas + Enter (fzf). Query pre-cargada con lo que escribiste,
  #    asi la lista ya viene filtrada. El header es el helper: dice que hacer.
  local choice
  if command -v fzf >/dev/null 2>&1; then
    choice=$(printf '%s\n' "$results" | fzf --height=45% --reverse \
      --query="$target" \
      --prompt="cd> " \
      --header="Escribi para filtrar  ·  Flechas para moverte  ·  Enter entra  ·  ESC cancela" \
      --preview 'eza --icons --color=always {} 2>/dev/null || ls -A {}' --preview-window=right:50%)
  else
    choice=$(printf '%s\n' "$results" | head -1)  # sin fzf, la primera
  fi
  [ -n "$choice" ] && builtin cd "$choice" && _cd_ls
}
# Lista el contenido al entrar (eza si esta, si no ls).
_cd_ls() { eza --icons --group-directories-first -a 2>/dev/null || ls -A --color=auto; }

# --- Ctrl+F: buscador de carpetas EN VIVO -----------------------------------
# Aprieta Ctrl+F y empeza a escribir: la lista se filtra en TIEMPO REAL con cada
# tecla. Flechas para moverte, Enter hace cd a la elegida. ESC cancela.
# Esto es lo que da el "mientras escribo ya me lista" sin apretar Enter dos veces.
_cd_fzf() {
  command -v fzf >/dev/null 2>&1 || return
  local all dir
  # Junta TODAS las carpetas de tus roots una vez; fzf filtra en vivo sobre eso.
  if command -v fd >/dev/null 2>&1; then
    all=$(fd -t d -i -d 5 . "${_cd_roots[@]}" 2>/dev/null | grep -viE "node_modules|/\.git|/dist|/build|/\.next|vendor")
  else
    all=$(find "${_cd_roots[@]}" -maxdepth 5 -type d 2>/dev/null | grep -viE "node_modules|/\.git|/dist|/build")
  fi
  dir=$(printf '%s\n' "$all" | fzf --height=45% --reverse --prompt="carpeta> " \
    --preview 'eza --icons --color=always {} 2>/dev/null || ls -A {}' --preview-window=right:50%)
  if [ -n "$dir" ]; then
    builtin cd "$dir" && _cd_ls
  fi
}
# Enlaza Ctrl+F a la funcion, y redibuja el prompt despues.
bind -x '"\C-f": _cd_fzf' 2>/dev/null
