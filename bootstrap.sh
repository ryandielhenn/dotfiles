#!/usr/bin/env bash
set -euo pipefail

# -------- Settings (you can override via env) --------
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
[ -d "$DOTFILES_DIR" ] || DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
LOG_PREFIX="${LOG_PREFIX:-[bootstrap]}"

log() { printf "\033[1;32m%s\033[0m %s\n" "$LOG_PREFIX" "$*"; }
warn() { printf "\033[1;33m%s\033[0m %s\n" "$LOG_PREFIX" "$*"; }
err()  { printf "\033[1;31m%s\033[0m %s\n" "$LOG_PREFIX" "$*"; }

need_sudo() {
  if command -v sudo >/dev/null 2>&1; then
    echo sudo
  else
    echo ""
  fi
}

SUDO="$(need_sudo)"

# ------- Base packages (includes vim + neovim, plus repo helpers) -------
APT_PKGS=(zsh git curl stow vim ca-certificates software-properties-common)

if command -v apt-get >/dev/null 2>&1; then
  log "Installing base packages: ${APT_PKGS[*]}"
  $SUDO apt-get update -y
  $SUDO apt-get install -y "${APT_PKGS[@]}"
else
  warn "apt-get not found; this script expects Debian/Ubuntu/Pop!_OS."
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

# -------- FORCE ~/.zshrc to be a symlink managed by stow --------
TS="$(date +%Y%m%d-%H%M%S)"
if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
  BAK="$HOME/.zshrc.backup-$TS"
  log "Backing up existing ~/.zshrc to $BAK and removing it so stow can link ours"
  cp "$HOME/.zshrc" "$BAK"
  rm -f "$HOME/.zshrc"
fi
if [ -L "$HOME/.zshrc" ]; then
  TARGET="$(readlink -f "$HOME/.zshrc" || true)"
  case "$TARGET" in
    "$DOTFILES_DIR"/*) ;;
    *)
      BAK="$HOME/.zshrc.symlink-replaced-$TS"
      log "Replacing existing symlinked ~/.zshrc (-> $TARGET). Backup at $BAK"
      cp "$HOME/.zshrc" "$BAK" || true
      rm -f "$HOME/.zshrc"
      ;;
  esac
fi

# -------- Stow dotfiles (zsh/ and nvim/ if present) --------
if [ -d "$DOTFILES_DIR" ]; then
  log "Using DOTFILES_DIR=$DOTFILES_DIR"
  cd "$DOTFILES_DIR"

  if [ -d "zsh" ]; then
    log "Stowing zsh/"
    stow -v -R -t "$HOME" zsh
  else
    warn "No zsh/ directory in $DOTFILES_DIR; skipping zsh stow"
  fi

  if [ -d "nvim" ]; then
    log "Stowing nvim/"
    stow -v -R -t "$HOME" nvim
  else
    warn "No nvim/ directory in $DOTFILES_DIR; will fallback to minimal init.vim if needed"
  fi

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

# -------- Always add Neovim PPA & install latest neovim --------
if command -v add-apt-repository >/dev/null 2>&1; then
  if ! grep -Riq "neovim-ppa/unstable" /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null; then
    log "Adding Neovim unstable PPA"
    $SUDO add-apt-repository -y ppa:neovim-ppa/unstable
  else
    log "Neovim PPA already present"
  fi
  log "Installing/Upgrading Neovim"
  $SUDO apt-get update -y
  $SUDO apt-get install -y neovim
else
  warn "add-apt-repository not available; cannot add Neovim PPA"
fi

# -------- vim-plug for Vim & Neovim (idempotent) --------
log "Ensuring vim-plug is installed (Vim/Neovim)"
# Neovim
NVIM_AUTO="$HOME/.local/share/nvim/site/autoload"
mkdir -p "$NVIM_AUTO"
if [ ! -f "$NVIM_AUTO/plug.vim" ]; then
  curl -fLo "$NVIM_AUTO/plug.vim" --create-dirs     https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  log "Installed vim-plug for Neovim"
else
  log "vim-plug already present for Neovim"
fi
# Vim
VIM_AUTO="$HOME/.vim/autoload"
mkdir -p "$VIM_AUTO"
if [ ! -f "$VIM_AUTO/plug.vim" ]; then
  curl -fLo "$VIM_AUTO/plug.vim" --create-dirs     https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  log "Installed vim-plug for Vim"
else
  log "vim-plug already present for Vim"
fi

# Create minimal configs only if not provided by dotfiles
if [ ! -d "$DOTFILES_DIR/nvim" ]; then
  if [ ! -f "$HOME/.config/nvim/init.vim" ] && [ ! -f "$HOME/.config/nvim/init.lua" ]; then
    log "Creating minimal ~/.config/nvim/init.vim (no nvim/ in dotfiles)"
    mkdir -p "$HOME/.config/nvim"
    cat <<'EOF' > "$HOME/.config/nvim/init.vim"
" Minimal bootstrap init.vim (replace with your dotfiles' version)
call plug#begin(stdpath('data') . '/plugged')
Plug 'tpope/vim-surround'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'neoclide/coc.nvim', {'branch': 'release'}
call plug#end()
set number
syntax on
EOF
  fi
fi

if [ ! -f "$HOME/.vimrc" ]; then
  log "Creating minimal ~/.vimrc (no .vimrc found)"
  cat <<'EOF' > "$HOME/.vimrc"
set nocompatible
filetype plugin indent on
syntax on
set number

call plug#begin('~/.vim/plugged')
Plug 'tpope/vim-surround'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'neoclide/coc.nvim', {'branch': 'release'}
call plug#end()
EOF
fi

# Detect Plug presence
plug_present_nvim=0
if [ -f "$HOME/.config/nvim/init.vim" ]; then
  if grep -q "plug#begin" "$HOME/.config/nvim/init.vim"; then
    plug_present_nvim=1
  fi
fi

plug_present_vim=0
if [ -f "$HOME/.vimrc" ]; then
  if grep -q "plug#begin" "$HOME/.vimrc"; then
    plug_present_vim=1
  fi
fi

# Run installers
if command -v nvim >/dev/null 2>&1 && [ "$plug_present_nvim" = "1" ]; then
  log "Running PlugInstall for Neovim (headless)"
  nvim --headless +"PlugInstall --sync" +qa || warn "nvim PlugInstall returned non-zero; check your config"
fi

if command -v vim >/dev/null 2>&1 && [ "$plug_present_vim" = "1" ]; then
  log "Running PlugInstall for Vim (headless)"
  vim +'PlugInstall --sync' +qa || warn "vim PlugInstall returned non-zero; check your .vimrc"
fi

# ----- Install nvm + Node LTS (per-user) -----
if [ ! -d "$HOME/.nvm" ]; then
  log "Installing nvm"
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi

# Ensure nvm loads for interactive and login shells
if ! grep -q 'NVM_DIR=.*\.nvm' "$HOME/.zshrc" 2>/dev/null; then
  cat >> "$HOME/.zshrc" <<'EOF'
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
EOF
fi
if ! grep -q 'NVM_DIR=.*\.nvm' "$HOME/.profile" 2>/dev/null; then
  cat >> "$HOME/.profile" <<'EOF'
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
EOF
fi

# Load nvm now and install Node LTS if missing
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
if ! command -v node >/dev/null 2>&1; then
  log "Installing Node.js LTS via nvm"
  nvm install --lts
  nvm alias default 'lts/*'
fi

log "Done. Open a new terminal or run: exec zsh"
echo
echo "Verification:"
echo "  SHELL set to: $(getent passwd "$USER" | cut -d: -f7)"
echo "  OMZ dir exists: $( [ -d "$HOME/.oh-my-zsh" ] && echo yes || echo no )"
echo "  .zshrc symlink: $( [ -L "$HOME/.zshrc" ] && echo yes || echo no )"
echo "  .zshrc target: $( readlink -f "$HOME/.zshrc" 2>/dev/null || echo 'n/a' )"
echo "  vim-plug (vim):  $( [ -f "$HOME/.vim/autoload/plug.vim" ] && echo yes || echo no )"
echo "  vim-plug (nvim): $( [ -f "$HOME/.local/share/nvim/site/autoload/plug.vim" ] && echo yes || echo no )"
echo "  vim version: $(command -v vim >/dev/null 2>&1 && vim --version | head -n 1 || echo 'not found')"
echo "  nvim version: $(command -v nvim >/dev/null 2>&1 && nvim --version | head -n 1 || echo 'not found')"
echo "  node version: $(command -v node >/dev/null 2>&1 && node -v || echo 'not found')"
