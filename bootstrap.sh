#!/usr/bin/env bash
# Cross-platform bootstrap (Pop!_OS/Ubuntu/Debian + macOS)
# - Installs: git, curl, stow, fzf, ripgrep, unzip, build tools
# - Editors: Neovim + full Vim (vim-gtk3), vim-plug, headless PlugInstall
# - Shell: zsh default (idempotent), optional Oh My Zsh
# - Node: optional nvm + LTS
# - Dotfiles: GNU stow of selected packages
#
# Usage:
#   DRY_RUN=1 ./bootstrap.sh               # preview actions
#   INSTALL_OMZ=0 ./bootstrap.sh           # skip Oh My Zsh
#   NODE_MAJOR=20 ./bootstrap.sh           # choose Node LTS major
#
# Safe to re-run. Exits on error.
set -euo pipefail

export DEBIAN_FRONTEND=${DEBIAN_FRONTEND:-noninteractive}

# --------------- Config knobs ---------------
DRY_RUN="${DRY_RUN:-0}"
INSTALL_OMZ="${INSTALL_OMZ:-1}"
NODE_MAJOR="${NODE_MAJOR:-20}"
STOW_PKGS_DEFAULT=("zsh" "nvim" "git")

# --------------- Utilities ---------------
log()  { printf "\033[1;34m[bootstrap]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[error]\033[0m %s\n" "$*" >&2; }
exists(){ command -v "$1" >/dev/null 2>&1; }

doit() {
  if [ "${DRY_RUN}" = "1" ]; then
    printf "[dry-run] %s\n" "$*"
  else
    eval "$@"
  fi
}

ensure_line() {
  # ensure_line "text" "file"
  local text="$1"; local file="$2"
  [ -f "$file" ] || touch "$file"
  grep -qxF "$text" "$file" || printf "%s\n" "$text" >> "$file"
}

detect_os() {
  local os=""
  if [ "$(uname -s)" = "Darwin" ]; then
    os="macos"
  elif [ -f /etc/os-release ]; then
    . /etc/os-release
    case "${ID_LIKE:-$ID}" in
      *debian*|*ubuntu*|pop) os="debian";;
      *) os="unknown";;
    esac
  else
    os="unknown"
  fi
  echo "$os"
}

REPO_DIR="${REPO_DIR:-$(pwd)}"
OS="$(detect_os)"
ARCH="$(uname -m)"
log "Bootstrapping on OS=${OS} ARCH=${ARCH} from ${REPO_DIR}"

# --------------- Base installs ---------------
install_base_debian() {
  log "Installing base packages (Debian/Ubuntu/Pop)"
  doit "sudo apt update"
  doit "sudo apt install -y --no-install-recommends \
    git curl stow fzf ripgrep unzip ca-certificates build-essential"
  # Optional diagnostics
  doit "sudo apt install -y inxi mesa-utils || true"
}

install_base_macos() {
  log "Installing base packages (macOS)"
  if ! exists brew; then
    log "Installing Homebrew"
    doit '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    # Add brew to PATH for Apple Silicon/Intel
    if [ -d /opt/homebrew/bin ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
      ensure_line 'eval "$(/opt/homebrew/bin/brew shellenv)"' "$HOME/.zprofile"
    elif [ -d /usr/local/bin ]; then
      eval "$(/usr/local/bin/brew shellenv)"
      ensure_line 'eval "$(/usr/local/bin/brew shellenv)"' "$HOME/.zprofile"
    fi
  fi
  doit "brew update"
  doit "brew install git curl stow fzf ripgrep"
}

# --------------- Editors ---------------
install_editors_debian() {
  log "Installing Neovim and full Vim (vim-gtk3)"
  doit "sudo apt install -y --no-install-recommends neovim vim-gtk3"
}

install_editors_macos() {
  log "Installing Neovim and Vim on macOS"
  doit "brew install neovim vim"
}

# --------------- zsh default shell ---------------
setup_zsh_default_shell_debian() {
  log "Ensuring zsh is default shell"
  doit "sudo apt install -y --no-install-recommends zsh"
  local zsh_bin
  zsh_bin="$(command -v zsh)"
  if ! grep -qx "$zsh_bin" /etc/shells; then
    doit "echo '$zsh_bin' | sudo tee -a /etc/shells >/dev/null"
  fi
  local current
  current="$(getent passwd "$USER" | cut -d: -f7 || true)"
  if [ "$current" != "$zsh_bin" ]; then
    doit "chsh -s '$zsh_bin' '$USER' || sudo chsh -s '$zsh_bin' '$USER' || sudo usermod -s '$zsh_bin' '$USER'"
  fi

  # Minimal ~/.zshrc if missing
  if [ ! -f "$HOME/.zshrc" ]; then
    cat > "$HOME/.zshrc" <<'ZRC'
export EDITOR="nvim"
alias vim='nvim'
ZRC
  else
    ensure_line "export EDITOR=\"nvim\"" "$HOME/.zshrc"
    ensure_line "alias vim='nvim'" "$HOME/.zshrc"
  fi

  # Make current session switch to zsh (skip in CI or non-tty)
  if [ -z "${CI:-}" ] && [ -z "${ZSH_VERSION:-}" ] && [ -t 1 ] && [ "${DRY_RUN}" != "1" ]; then
    exec "$zsh_bin" -l
  fi
}

setup_zsh_default_shell_macos() {
  log "Ensuring zsh is default shell (macOS)"
  if ! exists zsh; then
    doit "brew install zsh"
  fi
  local zsh_bin
  zsh_bin="$(command -v zsh)"
  if ! grep -qx "$zsh_bin" /etc/shells; then
    doit "echo '$zsh_bin' | sudo tee -a /etc/shells >/dev/null"
  fi
  # macOS: chsh works for user; login session change requires new terminal
  doit "chsh -s '$zsh_bin' '$USER' || true"

  if [ ! -f "$HOME/.zshrc" ]; then
    cat > "$HOME/.zshrc" <<'ZRC'
export EDITOR="nvim"
alias vim='nvim'
ZRC
  else
    ensure_line "export EDITOR=\"nvim\"" "$HOME/.zshrc"
    ensure_line "alias vim='nvim'" "$HOME/.zshrc"
  fi
}

# --------------- Oh My Zsh (optional) ---------------
install_ohmyzsh() {
  if [ "${INSTALL_OMZ}" = "1" ] && [ ! -d "$HOME/.oh-my-zsh" ]; then
    log "Installing Oh My Zsh (non-interactive)"
    doit "RUNZSH=no CHSH=no sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
  else
    log "Skipping Oh My Zsh (already present or INSTALL_OMZ=0)"
  fi
}

# --------------- vim-plug + headless plugin install ---------------
setup_vimplug_nvim() {
  log "Installing vim-plug for Neovim + running PlugInstall"
  local auto="$HOME/.local/share/nvim/site/autoload/plug.vim"
  if [ ! -f "$auto" ]; then
    doit "curl -fLo '$auto' --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
  fi
  # create minimal init if missing (you can replace with your repo's config)
  if [ ! -f "$HOME/.config/nvim/init.vim" ] && [ ! -f "$HOME/.config/nvim/init.lua" ]; then
    doit "mkdir -p '$HOME/.config/nvim'"
    cat > "$HOME/.config/nvim/init.vim" <<'NVIMRC'
" Minimal starter; replace with your full config or stow it
call plug#begin('~/.local/share/nvim/plugged')
Plug 'tpope/vim-sensible'
" Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
call plug#end()
NVIMRC
  fi
  if exists nvim; then
    # headless install; do not fail script if plugins fail
    doit "nvim +'PlugInstall --sync' +qa || true"
  fi
}

# (Optional) classic Vim support (vim-plug)
setup_vimplug_vim() {
  log "Installing vim-plug for classic Vim (optional)"
  local auto="$HOME/.vim/autoload/plug.vim"
  if [ ! -f "$auto" ]; then
    doit "curl -fLo '$auto' --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
  fi
  if [ ! -f "$HOME/.vimrc" ]; then
    cat > "$HOME/.vimrc" <<'VIMRC'
call plug#begin('~/.vim/plugged')
Plug 'tpope/vim-sensible'
call plug#end()
VIMRC
  fi
  if exists vim; then
    doit "vim +'PlugInstall --sync' +qa || true"
  fi
}

# --------------- nvm + Node LTS ---------------
install_nvm_node() {
  if ! [ -d "$HOME/.nvm" ]; then
    log "Installing nvm"
    doit "curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash"
  else
    log "nvm already present"
  fi
  # shellcheck source=/dev/null
  if [ -f "$HOME/.nvm/nvm.sh" ]; then
    # Ensure nvm loads in zsh
    ensure_line 'export NVM_DIR="$HOME/.nvm"' "$HOME/.zshrc"
    ensure_line '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' "$HOME/.zshrc"
    # load nvm in this script context too
    . "$HOME/.nvm/nvm.sh"
    log "Installing Node LTS v${NODE_MAJOR}"
    doit "nvm install ${NODE_MAJOR} && nvm alias default ${NODE_MAJOR}"
  fi
}

# --------------- GNU stow dotfiles ---------------
run_stow() {
  local pkgs=("$@")
  if [ "${#pkgs[@]}" -eq 0 ]; then
    pkgs=("${STOW_PKGS_DEFAULT[@]}")
  fi
  log "Stowing packages: ${pkgs[*]}"
  for pkg in "${pkgs[@]}"; do
    if [ -d "${REPO_DIR}/${pkg}" ]; then
      doit "stow -d '${REPO_DIR}' -t '$HOME' '${pkg}'"
    else
      log "Skip stow '${pkg}' (not found in ${REPO_DIR})"
    fi
  done
}

# --------------- Main ---------------
case "$OS" in
  debian)
    install_base_debian
    install_editors_debian
    setup_zsh_default_shell_debian
    install_ohmyzsh
    setup_vimplug_nvim
    # Uncomment if you also want classic Vim plugins:
    # setup_vimplug_vim
    install_nvm_node
    run_stow
    ;;
  macos)
    install_base_macos
    install_editors_macos
    setup_zsh_default_shell_macos
    install_ohmyzsh
    setup_vimplug_nvim
    # setup_vimplug_vim
    install_nvm_node
    run_stow
    ;;
  *)
    err "Unsupported OS. Exiting."
    exit 1
    ;;
esac

log "Default shell recorded: $(getent passwd "$USER" 2>/dev/null | cut -d: -f7 || echo '(macOS: check chsh)')"
log "Done ✅"
