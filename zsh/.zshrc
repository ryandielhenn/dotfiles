# ---------- Oh My Zsh ----------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)
source "$ZSH/oh-my-zsh.sh"

# Optional personal aliases (only if present)
[ -r "$HOME/.zsh_aliases" ] && source "$HOME/.zsh_aliases"

# ---------- Basics ----------
export EDITOR="nvim"
export VISUAL="$EDITOR"
export PAGER="less"

# Prefer UTF-8 (uncomment if you want these globally)
# export LANG="en_US.UTF-8"
# export LC_ALL="en_US.UTF-8"

# ---------- History (safer & better) ----------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt HIST_IGNORE_ALL_DUPS      # drop older dupes
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY               # don't execute right away when recalled
setopt INC_APPEND_HISTORY        # write as you go
setopt SHARE_HISTORY             # share across sessions

# ---------- Quality-of-life ----------
setopt AUTO_CD                   # `cd` by just typing the dir
setopt CORRECT                   # mild command correction (turn off if annoying)
setopt NO_BEEP

# ---------- jenv (guarded) ----------
if command -v jenv >/dev/null 2>&1; then
  export PATH="$HOME/.jenv/bin:$PATH"
  eval "$(jenv init -)"
fi

# ---------- fzf (with ripgrep fallback) ----------
if command -v rg >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='rg --files --no-ignore-vcs --hidden'
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
