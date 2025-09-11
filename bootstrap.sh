#!/usr/bin/env bash
set -euo pipefail

# -------- Settings (you can override via env) --------
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
[ -d "$DOTFILES_DIR" ] || DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
INSTALL_NEOVIM="${INSTALL_NEOVIM:-0}"   # set to 1 to install latest neovim (PPA)
LOG_PREFIX="${LOG_PREFIX:-[bootstrap]}"

log() { printf "\033[1;32m%s\033[0m %s\n" "$LOG_PREFIX" "$*"; }
warn() { printf "\033[1;33m%s\033[0m %s\n" "$LOG_PREFIX" "$*"; }
err() { printf "\033[1;31m%s\033[0m %s\n" "$LOG_PREFIX" "$*"; }

need_sudo() {
  if command -v sudo >/dev/null 2>&1; then
    echo sudo
  else
    echo ""
  fi
}

APT_PKGS=(zsh git curl stow)
SUDO="$(need_sudo)"

# -------- OS/Package setup --------
if command -v apt-get >/dev/null 2>&1; then
  log "Installing packages: ${APT_PKGS[*]}"
  $SUDO apt-get update -y
  $SUDO apt-get install -y "${APT_PKGS[@]}"
else
  warn "apt-get not found; skipping package install (assuming packages exist)"
fi

# -------- Ensure default shell is zsh --------
if ! command -v zsh >/dev/null 2>&1; then
  err "zsh not found even after install attempt."
  exit 1
fi
CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7 || true)"
ZSH_BIN="$(command -v zsh)"
if [ "$CURRENT_SHELL" != "$ZSH_BIN" ]; then
  log "Setting default shell to zsh ($ZSH_BIN)"
  if command -v chsh >/dev/null 2>&1; then
    $SUDO chsh -s "$ZSH_BIN" "$USER" || true
  else
    warn "chsh not available; set your shell to zsh manually later."
  fi
else
  log "Default shell already zsh"
fi

# -------- Install or normalize Oh-My-Zsh --------
if [ -d "$HOME/.ohmyzsh" ] && [ ! -d "$HOME/.oh-my-zsh" ]; then
  log "Renaming ~/.ohmyzsh -> ~/.oh-my-zsh"
  mv "$HOME/.ohmyzsh" "$HOME/.oh-my-zsh"
fi

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  log "Installing Oh My Zsh..."
  export RUNZSH=no
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  log "Oh My Zsh already present"
fi

# -------- Stow dotfiles (zsh) --------
if [ -d "$DOTFILES_DIR" ]; then
  log "Using DOTFILES_DIR=$DOTFILES_DIR"
  cd "$DOTFILES_DIR"
  if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
    log "Adopting existing ~/.zshrc into repo for stow management"
    stow -v -R -t "$HOME" --adopt zsh || true
    git status >/dev/null 2>&1 && warn "Remember to review/commit adopted changes in your dotfiles repo."
  fi

  log "Stowing zsh/"
  stow -v -R -t "$HOME" zsh || {
    warn "stow encountered issues; retrying without --adopt"
    stow -v -R -t "$HOME" zsh
  }
  cd - >/dev/null
else
  warn "DOTFILES_DIR not found ($DOTFILES_DIR). Skipping stow."
fi

# -------- Ensure ~/.zshrc sources OMZ (idempotent) --------
if ! grep -q 'oh-my-zsh\.sh' "$HOME/.zshrc" 2>/dev/null; then
  log "Appending OMZ source block to ~/.zshrc"
  cat <<'EOF' >> "$HOME/.zshrc"

# >>> Oh My Zsh bootstrap >>>
export ZSH="${HOME}/.oh-my-zsh"
if [ -f "$ZSH/oh-my-zsh.sh" ]; then
  ZSH_THEME="${ZSH_THEME:-robbyrussell}"
  plugins=(${plugins:-git})
  source "$ZSH/oh-my-zsh.sh"
fi
# <<< Oh My Zsh bootstrap <<<
EOF
else
  log "~/.zshrc already sources Oh My Zsh"
fi

# -------- Linux-specific cleanup --------
if [ "$(uname -s)" = "Linux" ]; then
  log "Cleaning macOS-specific brew lines and OMZ typos in ~/.zshrc (Linux)"
  sed -i '/\/opt\/homebrew\/bin\/brew/d' "$HOME/.zshrc" 2>/dev/null || true
  sed -i 's|\.ohmyzsh|.oh-my-zsh|g' "$HOME/.zshrc" 2>/dev/null || true
  sed -i 's|ohmyzsh\.sh|oh-my-zsh.sh|g' "$HOME/.zshrc" 2>/dev/null || true
fi

# -------- Add OS-aware Homebrew init block --------
if ! grep -q '>>> Homebrew (OS-aware) >>>' "$HOME/.zshrc" 2>/dev/null; then
  log "Appending OS-aware Homebrew init to ~/.zshrc"
  cat <<'EOF' >> "$HOME/.zshrc"

# >>> Homebrew (OS-aware) >>>
case "$(uname -s)" in
  Darwin)
    [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
    ;;
  Linux)
    [ -x /home/linuxbrew/.linuxbrew/bin/brew ] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    ;;
esac
# <<< Homebrew <<<
EOF
fi

# -------- Optional Neovim --------
if [ "$INSTALL_NEOVIM" = "1" ] && command -v add-apt-repository >/dev/null 2>&1; then
  log "Installing latest Neovim via PPA"
  $SUDO apt-get install -y software-properties-common
  $SUDO add-apt-repository -y ppa:neovim-ppa/unstable
  $SUDO apt-get update -y
  $SUDO apt-get install -y neovim
elif [ "$INSTALL_NEOVIM" = "1" ]; then
  warn "add-apt-repository not found; skipping Neovim PPA install"
fi

log "Done. Open a new terminal or run: exec zsh"
echo
echo "Verification:"
echo "  SHELL set to: $(getent passwd "$USER" | cut -d: -f7)"
echo "  OMZ dir exists: $( [ -d "$HOME/.oh-my-zsh" ] && echo yes || echo no )"
echo "  .zshrc symlink: $( [ -L "$HOME/.zshrc" ] && echo yes || echo no )"
