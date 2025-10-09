# ---------- Basics ----------
export EDITOR="nvim"
export VISUAL="$EDITOR"
export PAGER="less"

# Tell tools like neofetch which terminal you're using
if [[ -n "$ALACRITTY_WINDOW_ID" ]]; then
  export TERM_PROGRAM=alacritty
fi

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

# ---------- Oh My Zsh ----------
[ -r "$HOME/.zsh_aliases" ] && source "$HOME/.zsh_aliases"
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)

if grep -qi microsoft /proc/version 2>/dev/null; then
  [[ -f "$HOME/.zshrc-wsl" ]] && source "$HOME/.zshrc-wsl"
fi

source "$ZSH/oh-my-zsh.sh"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# ---------- Go toolchain (cross-platform safe) ----------
# 1) If the official tarball install exists (common on Linux), add it.
if [ -d /usr/local/go/bin ]; then
  case ":$PATH:" in
    *":/usr/local/go/bin:"*) ;;
    *) export PATH="/usr/local/go/bin:$PATH" ;;
  esac
fi

# 2) If 'go' is available, ensure GOPATH/bin is on PATH (for gopls, etc.).
if command -v go >/dev/null 2>&1; then
  GOPATH_DIR="$(go env GOPATH 2>/dev/null)"
  [ -n "$GOPATH_DIR" ] || GOPATH_DIR="$HOME/go"
  if [ -d "$GOPATH_DIR/bin" ]; then
    case ":$PATH:" in
      *":$GOPATH_DIR/bin:"*) ;;
      *) export PATH="$GOPATH_DIR/bin:$PATH" ;;
    esac
  fi
fi
# ---------- end Go toolchain ----------

# ---------------------------------------------------------
# Wofi Toggle Function
# - Launches Wofi with custom config + style if not running
# - If Wofi is already running, kills it (toggle behavior)
# - Install 
#
# TODO update bootstrap.sh
# - cd ~.config
# - clone repo at https://github.com/quantumfate/wofi
# ---------------------------------------------------------
# --- wofi paths (edit these once) ---
WOFI_CONF="$HOME/.config/wofi/config/config"
WOFI_STYLE="$HOME/.config/wofi/src/everforest/style.css"

# Helper to always call wofi with the same styling
wofi_cmd() {
  wofi --conf "$WOFI_CONF" --style "$WOFI_STYLE" "$@"
}

wofi-toggle() {
  # Only run on Linux + Wayland and if wofi exists
  [[ "$OSTYPE" == "linux-gnu"* ]] || return 0
  [[ -n "$WAYLAND_DISPLAY" ]] || return 0
  command -v wofi >/dev/null 2>&1 || return 0

  if ! pidof wofi >/dev/null 2>&1; then
    # Same style as dmenu prompts
    wofi_cmd
  else
    pkill -x wofi
  fi
}

[ -d "$HOME/.local/bin" ] && export PATH="$PATH:$HOME/.local/bin"
[ -d "$HOME/.spicetify" ] && export PATH="$PATH:$HOME/.spicetify"
