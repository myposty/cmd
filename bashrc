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
