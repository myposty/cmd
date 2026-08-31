# =============================================================================
#  .bashrc — arranque minimo. En Git Bash/Windows CADA proceso cuesta ~50ms,
#  asi que la regla es: la MENOR cantidad de comandos posible al abrir.
#  Nada de `command -v`, `mkdir`, ni regeneracion de caches en el arranque.
# =============================================================================

[ -z "$USER" ] && export USER=$(id -un)
[ -z "$LANG" ] && export LANG=en_US.UTF-8

# --- PROMPT (oh-my-posh): unica cosa que corre al abrir. Cache ya generado. --
# Si el cache no existe (primera vez / borraste el cache), lo regenera esa vez.
[ -s ~/.cache/sh-init/omp.sh ] || oh-my-posh init bash --print --config "$HOME/.config/oh-my-posh/indigo-mate.omp.json" > ~/.cache/sh-init/omp.sh 2>/dev/null
source ~/.cache/sh-init/omp.sh 2>/dev/null

# --- Historial grande, sin duplicados. --------------------------------------
export HISTSIZE=50000 HISTFILESIZE=50000 HISTCONTROL=ignoreboth:erasedups
shopt -s histappend

# --- zoxide (lazy): se carga la primera vez que usas `z` o `zi`. -------------
z()  { unset -f z zi; source ~/.cache/sh-init/zoxide.sh 2>/dev/null; z "$@"; }
zi() { unset -f z zi; source ~/.cache/sh-init/zoxide.sh 2>/dev/null; zi "$@"; }

# --- atuin: FLECHA ARRIBA y Ctrl+R abren el buscador de historial. ----------
# Se carga entero al abrir (necesario para que capture flecha-arriba desde el
# primer comando). atuin regenera su cache con --disable-up-arrow quitado.
source ~/.cache/sh-init/atuin.sh 2>/dev/null

# --- Auto-listar al entrar a una carpeta (eza si esta, si no ls). ------------
cd() { builtin cd "$@" && { eza --icons --group-directories-first -a 2>/dev/null || ls -A --color=auto; }; }

# --- Autocompletado NATIVO mejorado (Tab) -----------------------------------
# Tab lista/completa sin importar mayusculas, muestra menu al primer Tab,
# y marca los directorios. Todo readline nativo, cero dependencias, 0ms.
bind 'set completion-ignore-case on'      2>/dev/null  # da igual mayus/minus
bind 'set show-all-if-ambiguous on'       2>/dev/null  # 1 solo Tab muestra la lista
bind 'set menu-complete-display-prefix on' 2>/dev/null # completa el prefijo comun
bind 'set colored-stats on'               2>/dev/null  # directorios con color
bind 'set mark-directories on'            2>/dev/null  # / al final de carpetas
bind 'set visible-stats on'               2>/dev/null  # marca tipo de archivo
bind 'TAB:menu-complete'                  2>/dev/null  # Tab cicla las opciones
bind '"\e[Z":menu-complete-backward'      2>/dev/null  # Shift+Tab cicla al reves

# --- `d <nombre>`: salta a una carpeta por nombre, estes donde estes --------
# Busca directorios que contengan <nombre> en tus carpetas de proyecto.
# Uno solo -> hace cd directo. Varios -> los lista arriba y elegis por numero.
# Bash + fd nativo (o find). Cero servicios de fondo.
_d_roots=( ~/Desktop/proyect ~/Desktop/WORK ~/Desktop/backend-local ~/Desktop )
d() {
  local q="$1" matches=() dir
  [ -z "$q" ] && { echo "uso: d <nombre-de-carpeta>"; return 1; }
  # fd es rapidisimo; si no esta, cae a find. Ignora ruido.
  if command -v fd >/dev/null 2>&1; then
    while IFS= read -r dir; do matches+=("$dir"); done < <(fd -t d -i -d 5 "$q" "${_d_roots[@]}" 2>/dev/null | grep -viE "node_modules|/\.git|/dist|/build|/\.next|vendor" | head -30)
  else
    while IFS= read -r dir; do matches+=("$dir"); done < <(find "${_d_roots[@]}" -maxdepth 5 -type d -iname "*$q*" 2>/dev/null | grep -viE "node_modules|/\.git|/dist|/build" | head -30)
  fi
  local n=${#matches[@]}
  if   [ "$n" -eq 0 ]; then echo "sin coincidencias para '$q'"; return 1
  elif [ "$n" -eq 1 ]; then cd "${matches[0]}"
  else
    echo "Carpetas con '$q':"
    local i=1; for dir in "${matches[@]}"; do printf "  %2d) %s\n" "$i" "$dir"; i=$((i+1)); done
    printf "Elegi [1-%d]: " "$n"; local sel; read -r sel
    [[ "$sel" =~ ^[0-9]+$ ]] && [ "$sel" -ge 1 ] && [ "$sel" -le "$n" ] && cd "${matches[$((sel-1))]}" || echo "cancelado"
  fi
}
