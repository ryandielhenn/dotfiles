#!/usr/bin/env bash
set -euo pipefail

# --------------------------------------------
# Config
# --------------------------------------------
PACKAGES=("zsh" "nvim" "git")   # stow these subfolders
TARGET="$HOME"                  # where to symlink to
DRY_RUN=0                       # set via --dry-run
NO_OMZ=0                        # set via --no-ohmyzsh

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
  --packages ...  Space-separated list of stow packages (default: ${PACKAGES[*]})
  --unstow        Remove symlinks for the selected packages
  --restow        Re-link (stow -R) selected packages
  -h, --help      Show this help

Examples:
  $(basename "$0")
  $(basename "$0") --dry-run
  $(basename "$0") --packages "zsh git"
  $(basename "$0") --unstow --packages "nvim"
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
    --packages)
      shift
      # allow: --packages "zsh git" or --packages zsh git
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

install_oh_my_zsh() {
  if (( NO_OMZ == 1 )); then return; fi
  if [ -d "$HOME/.oh-my-zsh" ]; then return; fi
  if ! have zsh; then
    log "Zsh not found. Please install zsh first (brew install zsh or apt install zsh)."
    return
  fi
  log "Installing Oh My Zsh..."
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

# --------------------------------------------
# Do work
# --------------------------------------------
install_stow
install_oh_my_zsh

# Flags as a STRING to avoid 'unbound variable' with set -u
STOW_FLAGS=""
if (( DRY_RUN == 1 )); then
  STOW_FLAGS="-n -v"
fi

case "$MODE" in
  stow)
    log "Stowing packages: ${PACKAGES[*]}"
    # shellcheck disable=SC2086
    stow $STOW_FLAGS -t "$TARGET" "${PACKAGES[@]}"
    ;;
  restow)
    log "Re-stowing packages: ${PACKAGES[*]}"
    # shellcheck disable=SC2086
    stow $STOW_FLAGS -R -t "$TARGET" "${PACKAGES[@]}"
    ;;
  unstow)
    log "Unstowing packages: ${PACKAGES[*]}"
    # shellcheck disable=SC2086
    stow $STOW_FLAGS -D -t "$TARGET" "${PACKAGES[@]}"
    ;;
esac

# --------------------------------------------
# Verification hints
# --------------------------------------------
if (( DRY_RUN == 0 )) && [ "$MODE" != "unstow" ]; then
  log ""
  log "Verify symlinks (examples):"
  for f in "$HOME/.zshrc" "$HOME/.gitconfig" "$HOME/.config/nvim/init.vim"; do
    [ -e "$f" ] && ls -l "$f" || true
  done
  log ""
  log "Done. If you updated Zsh config, run: exec zsh"
fi
