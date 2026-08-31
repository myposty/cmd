# =============================================================================
#  .zshrc — Mac / Linux (shell nativo: zsh). Mismo stack que el .bashrc de
#  Windows: oh-my-posh + atuin + zoxide + eza, con carga cacheada.
# =============================================================================

# --- PROMPT (oh-my-posh). Cache generado por install.sh. --------------------
[ -s ~/.cache/sh-init/omp.zsh ] || oh-my-posh init zsh --config "$HOME/.config/oh-my-posh/indigo-mate.omp.json" > ~/.cache/sh-init/omp.zsh 2>/dev/null
source ~/.cache/sh-init/omp.zsh 2>/dev/null

# --- Historial grande, sin duplicados. --------------------------------------
export HISTSIZE=50000 SAVEHIST=50000
setopt hist_ignore_all_dups hist_ignore_space share_history

# --- zoxide (lazy): se carga la primera vez que usas `z` o `zi`. -------------
z()  { unfunction z zi; source ~/.cache/sh-init/zoxide.zsh 2>/dev/null; z "$@"; }
zi() { unfunction z zi; source ~/.cache/sh-init/zoxide.zsh 2>/dev/null; zi "$@"; }

# --- atuin: FLECHA ARRIBA y Ctrl+R abren el buscador de historial. ----------
source ~/.cache/sh-init/atuin.zsh 2>/dev/null

# --- Auto-listar al entrar a una carpeta (eza si esta, si no ls). ------------
chpwd() { eza --icons --group-directories-first -a 2>/dev/null || ls -A --color=auto; }
