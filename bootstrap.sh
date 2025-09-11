#!/usr/bin/env bash
set -euo pipefail

# --------------------------------------------
# Config
# --------------------------------------------
PACKAGES=("zsh" "nvim" "git")   # stow these subfolders
TARGET="$HOME"                  # where to symlink to
DRY_RUN=0                       # set via --dry-run
NO_OMZ=0                        # set via --no-ohmyzsh
DO_CHSH=0                       # set via --chsh

# --------------------------------------------
# Helpers
# --------------------------------------------
log() { printf "%s\n" "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --dry-run       Show what would happen without making changes
  --no-ohmyzsh    Skip installing Oh My Zsh
  --chsh          Change default shell to zsh if not already
  --packages ...  Space-separated list of stow packages (default: ${PACKAGES[*]})
  --unstow        Remove symlinks for the selected packages
  --restow        Re-link (stow -R) selected packages
  -h, --help      Show this help

Examples:
  $(basename "$0")
  $(basename "$0") --dry-run
  $(basename "$0") --packages "zsh git"
  $(basename "$0") --unstow --packages "nvim"
  $(basename "$0") --chsh
EOF
}

# --------------------------------------------
# Parse args
# --------------------------------------------
MODE="stow"
while (($#)); do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --no-ohmyzsh) NO_OMZ=1 ;;
    --chsh) DO_CHSH=1 ;;
    --packages)
      shift
      if (( $# == 0 )); then log "Missing value for --packages"; exit 1; fi
      # shellcheck disable=SC2206
      PACKAGES=($1)
      ;;
    --unstow) MODE="unstow" ;;
    --restow) MODE="restow" ;;
    -h|--help) usage; exit 0 ;;
    *) log "Unknown option: $1"; usage; exit 1 ;;
  esac
  shift || true
done

# --------------------------------------------
# Ensure we are in repo root
# --------------------------------------------
cd "$(dirname "$0")"

# --------------------------------------------
# Install prerequisites
# --------------------------------------------
install_stow() {
  if have stow; then return; fi
  log "GNU Stow not found; attempting to install..."

  case "$(uname -s)" in
    Darwin)
      if ! have brew; then
        log "Homebrew not found; installing..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      fi
      brew install stow
      ;;
    Linux)
      if have apt; then
        sudo apt update && sudo apt install -y stow
      elif have dnf; then
        sudo dnf install -y stow
      elif have pacman; then
        sudo pacman -S --noconfirm stow
      else
        log "Please install GNU Stow with your package manager."
        exit 1
      fi
      ;;
    *)
      log "Unsupported OS for automatic stow install. Install it manually."
      exit 1
      ;;
  esac
}

install_zsh_if_missing() {
  if have zsh; then return; fi
  log "zsh not found; attempting to install..."

  case "$(uname -s)" in
    Darwin)
      if ! have brew; then
        log "Homebrew not found; installing..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      fi
      brew install zsh
      ;;
    Linux)
      if have apt; then
        sudo apt update && sudo apt install -y zsh
      elif have dnf; then
        sudo dnf install -y zsh
      elif have pacman; then
        sudo pacman -S --noconfirm zsh
      else
        log "Please install zsh with your package manager."
        exit 1
      fi
      ;;
    *)
      log "Unsupported OS; install zsh manually."
      exit 1
      ;;
  esac
}

install_oh_my_zsh() {
  if (( NO_OMZ == 1 )); then return; fi
  if [ -d "$HOME/.oh-my-zsh" ]; then
    log "Oh My Zsh already present; skipping."
    return
  fi
  if ! have zsh; then
    log "zsh not found (should have been installed). Skipping OMZ."
    return
  fi
  if ! have curl; then
    if have apt; then sudo apt install -y curl; fi
    if have dnf; then sudo dnf install -y curl; fi
    if have pacman; then sudo pacman -S --noconfirm curl; fi
  fi
  log "Installing Oh My Zsh..."
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

maybe_chsh() {
  if (( DO_CHSH != 1 )); then return; fi
  if ! have zsh; then
    log "zsh not installed; cannot change default shell."
    return
  fi
  current="$(basename "${SHELL:-}")"
  if [[ "$current" == "zsh" ]]; then
    log "Default shell already zsh."
    return
  fi
  log "Changing default shell to zsh..."
  if chsh -s "$(command -v zsh)"; then
    log "Default shell changed to zsh. Log out/in to apply."
  else
    log "Could not change shell (permission or PAM policy). Try manually: chsh -s "\$(command -v zsh)""
  fi
}

# --------------------------------------------
# Do work
# --------------------------------------------
install_stow
install_zsh_if_missing
install_oh_my_zsh
maybe_chsh

STOW_FLAGS=""
if (( DRY_RUN == 1 )); then
  STOW_FLAGS="-n -v"
fi

case "$MODE" in
  stow)
    log "Stowing packages: ${PACKAGES[*]}"
    stow $STOW_FLAGS -t "$TARGET" "${PACKAGES[@]}"
    ;;
  restow)
    log "Re-stowing packages: ${PACKAGES[*]}"
    stow $STOW_FLAGS -R -t "$TARGET" "${PACKAGES[@]}"
    ;;
  unstow)
    log "Unstowing packages: ${PACKAGES[*]}"
    stow $STOW_FLAGS -D -t "$TARGET" "${PACKAGES[@]}"
    ;;
esac

if (( DRY_RUN == 0 )) && [ "$MODE" != "unstow" ]; then
  log ""
  log "Verify symlinks (examples):"
  for f in "$HOME/.zshrc" "$HOME/.gitconfig" "$HOME/.config/nvim/init.vim"; do
    [ -e "$f" ] && ls -l "$f" || true
  done
  log ""
  log "Done."
  log "Tip: run 'zsh' to test immediately.$([ "$DO_CHSH" -eq 1 ] && printf " (Default will apply next login.)")"
fi
