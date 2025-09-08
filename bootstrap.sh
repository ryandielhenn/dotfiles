#!/usr/bin/env bash
set -euo pipefail

# ==================================================
# Cross-platform bootstrap (Linux/Pop!_OS + macOS)
# Sets up: zsh + Oh My Zsh, Neovim, nvm/Node LTS, vim-plug, GNU stow
# Idempotent, safe to re-run. Use DRY_RUN=1 to preview.
# ==================================================

# -------- Config knobs --------
DRY_RUN="${DRY_RUN:-0}"                         # set to 1 for dry-run
INSTALL_OMZ="${INSTALL_OMZ:-1}"                 # 0 to skip Oh My Zsh
NODE_MAJOR="${NODE_MAJOR:-20}"                  # nvm Node LTS to install
STOW_PKGS_DEFAULT=("zsh" "nvim" "git")          # repo subdirs to stow
NVIM_REQUIRE_REGEX='NVIM v0\.(10|11|12)'        # acceptable nvim versions

# -------- Helpers --------
log(){ printf "\033[1;32m==>\033[0m %s\n" "$*"; }
warn(){ printf "\033[1;33mWARN\033[0m %s\n" "$*"; }
err(){ printf "\033[1;31mERR \033[0m %s\n" "$*" >&2; }
doit(){ if [ "$DRY_RUN" = "1" ]; then echo "DRY: $*"; else eval "$@"; fi; }
exists(){ command -v "$1" >/dev/null 2>&1; }

# -------- Detect platform --------
OS="$(uname -s)"
ARCH="$(uname -m)"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

log "Bootstrapping on $OS ($ARCH) from $REPO_DIR"

# -------- Install base tools (git, curl, stow, fzf, ripgrep, unzip) --------
install_base_linux() {
  doit "sudo apt update -y"
  doit "sudo apt install -y git curl stow fzf ripgrep unzip ca-certificates build-essential"
  # Nice-to-have diagnostics (skip failure)
  doit "sudo apt install -y inxi mesa-utils || true"
}

install_base_macos() {
  if ! exists brew; then
    log "Installing Homebrew"
    # Non-interactive Homebrew install
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Ensure brew on PATH for Apple Silicon and Intel
    if [ -d /opt/homebrew/bin ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
      if [ -n "${ZDOTDIR:-}" ] && [ -f "$ZDOTDIR/.zshrc" ]; then
        grep -q 'eval "\$\(\/opt\/homebrew\/bin\/brew shellenv\)"' "$ZDOTDIR/.zshrc" || \
          echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$ZDOTDIR/.zshrc"
      else
        grep -q 'eval "\$\(\/opt\/homebrew\/bin\/brew shellenv\)"' "$HOME/.zprofile" 2>/dev/null || \
          echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
      fi
    fi
  fi
  doit "brew update"
  doit "brew install git stow fzf ripgrep unzip"
}

case "$OS" in
  Linux)  install_base_linux ;;
  Darwin) install_base_macos ;;
  *) err "Unsupported OS: $OS"; exit 1 ;;
esac

# -------- zsh + login shell --------
if ! exists zsh; then
  log "Installing zsh"
  case "$OS" in
    Linux)  doit "sudo apt install -y zsh" ;;
    Darwin) doit "brew install zsh" ;;
  esac
fi

# ensure zsh is the login shell
DEFAULT_SHELL="$(getent passwd "$USER" 2>/dev/null | cut -d: -f7 || true)"
ZSH_PATH="$(command -v zsh || true)"
if [ -z "$DEFAULT_SHELL" ] && [ "$OS" = "Darwin" ]; then
  # macOS fallback using dscl
  DEFAULT_SHELL="$(dscl . -read /Users/$USER UserShell 2>/dev/null | awk '{print $2}' || true)"
fi
if [ -n "$ZSH_PATH" ] && [ "$DEFAULT_SHELL" != "$ZSH_PATH" ]; then
  log "Setting login shell to $ZSH_PATH"
  case "$OS" in
    Linux)  doit "chsh -s \"$ZSH_PATH\" \"$USER\" || true" ;;
    Darwin) doit "sudo chsh -s \"$ZSH_PATH\" \"$USER\" || true" ;;
  esac
fi

# -------- Oh My Zsh (optional) + popular plugins --------
if [ "$INSTALL_OMZ" = "1" ]; then
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log "Installing Oh My Zsh (non-interactive, keep existing .zshrc if present)"
    doit "RUNZSH=no KEEP_ZSHRC=yes sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
  else
    log "Oh My Zsh already installed"
  fi
  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  if [ -d "$HOME/.oh-my-zsh" ]; then
    [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] || \
      doit "git clone https://github.com/zsh-users/zsh-autosuggestions \"$ZSH_CUSTOM/plugins/zsh-autosuggestions\""
    [ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] || \
      doit "git clone https://github.com/zsh-users/zsh-syntax-highlighting \"$ZSH_CUSTOM/plugins/zsh-syntax-highlighting\""
  fi
else
  warn "Skipping Oh My Zsh (INSTALL_OMZ=0)"
fi

# -------- Neovim installation --------
install_nvim_linux() {
  mkdir -p "$HOME/bin"
  if ! exists nvim || ! nvim --version | grep -qE "$NVIM_REQUIRE_REGEX"; then
    log "Installing Neovim AppImage to ~/bin"
    doit "curl -L https://github.com/neovim/neovim/releases/latest/download/nvim.appimage -o \"$HOME/bin/nvim.appimage\""
    doit "chmod +x \"$HOME/bin/nvim.appimage\""
    doit "ln -sf \"$HOME/bin/nvim.appimage\" \"$HOME/bin/nvim\""
    # ensure ~/bin on PATH in zsh
    if [ -f "$HOME/.zshrc" ] && ! grep -q 'export PATH="$HOME/bin:$PATH"' "$HOME/.zshrc"; then
      doit "echo 'export PATH=\"\$HOME/bin:\$PATH\"' >> \"$HOME/.zshrc\""
    fi
  else
    log "Neovim is recent: $(nvim --version | head -n1)"
  fi
}

install_nvim_macos() {
  if ! exists nvim || ! nvim --version | grep -qE "$NVIM_REQUIRE_REGEX"; then
    log "Installing Neovim via Homebrew"
    doit "brew install neovim"
  else
    log "Neovim is recent: $(nvim --version | head -n1)"
  fi
}

case "$OS" in
  Linux)  install_nvim_linux ;;
  Darwin) install_nvim_macos ;;
esac

# -------- Node via nvm (for CoC and dev tooling) --------
if [ ! -d "$HOME/.nvm" ]; then
  log "Installing nvm"
  doit "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash"
fi
# shellcheck disable=SC1090
export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
if ! exists node || ! node -v | grep -qE '^v(1[6-9]|2[0-9])'; then
  log "Installing Node LTS v${NODE_MAJOR} via nvm"
  doit "nvm install ${NODE_MAJOR}"
  doit "nvm alias default ${NODE_MAJOR}"
fi

# -------- vim-plug in Neovim path --------
PLUG="$HOME/.local/share/nvim/site/autoload/plug.vim"
if [ ! -f "$PLUG" ]; then
  log "Installing vim-plug for Neovim"
  doit "curl -fLo \"$PLUG\" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
fi

# -------- Stow dotfiles --------
log "Stowing dotfiles packages (if present)"
for pkg in "${STOW_PKGS_DEFAULT[@]}"; do
  if [ -d "$REPO_DIR/$pkg" ]; then
    log "stow -v -R $pkg"
    doit "stow -v -R $pkg"
  else
    log "Skipping $pkg (not found in repo)"
  fi
done

# -------- Headless Neovim plugin install/update --------
if exists nvim && { [ -f "$HOME/.config/nvim/init.vim" ] || [ -f "$HOME/.config/nvim/init.lua" ]; }; then
  log "Running PlugInstall / TSUpdate / CocUpdate headlessly"
  doit "nvim +'PlugInstall | TSUpdate | CocUpdate | qa' || true"
fi

# -------- Final notes --------
log "Default shell recorded: $(getent passwd \"$USER\" 2>/dev/null | cut -d: -f7 || echo '(macOS: see dscl)')"
log "To start zsh now in this terminal: exec zsh"
log "Done ✅"
