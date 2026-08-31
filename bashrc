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
  # 3) Menu con flechas + Enter (fzf). Una sola coincidencia -> entra directo.
  local choice
  if command -v fzf >/dev/null 2>&1; then
    choice=$(printf '%s\n' "$results" | fzf --height=40% --reverse --prompt="cd> " \
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
