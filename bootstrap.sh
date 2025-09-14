#!/usr/bin/env bash
set -euo pipefail

# --------------------------------------------
# Config
# --------------------------------------------
PACKAGES=("zsh" "nvim" "git" "alacritty")   # stow these subfolders
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

  # Prevent OMZ from dropping a default ~/.zshrc that would conflict with stow
  log "Installing Oh My Zsh (preserving existing ~/.zshrc if any)..."
  KEEP_ZSHRC=yes RUNZSH=no CHSH=no \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

ensure_shell_listed() {
  # On macOS, Homebrew zsh path might not be in /etc/shells; add it to allow chsh
  local zsh_path
  zsh_path="$(command -v zsh || true)"
  [ -z "$zsh_path" ] && return 0

  if [ -f /etc/shells ] && ! grep -qx "$zsh_path" /etc/shells 2>/dev/null; then
    if [ "$(uname -s)" = "Darwin" ]; then
      log "Adding $zsh_path to /etc/shells so chsh is allowed (macOS)."
      echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null || true
    fi
  fi
}

maybe_chsh() {
  if (( DO_CHSH != 1 )); then return; fi
  if ! have zsh; then
    log "zsh not installed; cannot change default shell."
    return
  fi

  ensure_shell_listed

  local current
  current="$(basename "${SHELL:-}")"
  if [[ "$current" == "zsh" ]]; then
    log "Default shell already zsh."
    return
  fi

  # WSL note
  if grep -qi microsoft /proc/version 2>/dev/null; then
    log "WSL detected: chsh may not affect Windows Terminal profiles."
  fi

  log "Changing default shell to zsh..."
  if chsh -s "$(command -v zsh)"; then
    log "Default shell changed to zsh. Log out/in to apply."
  else
    log "Could not change shell (permission or PAM policy). Try manually: chsh -s \"\$(command -v zsh)\""
  fi
}

# --------------------------------------------
# Prepare for stow (handle conflicts)
# --------------------------------------------
prepare_conflicts() {
  # If OMZ created a real ~/.zshrc, back it up so stow can place a symlink
  if [ -e "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
    local backup="$HOME/.zshrc.pre-stow.$(date +%Y%m%d-%H%M%S)"
    log "Found real ~/.zshrc (not a symlink); backing up to $backup"
    mv "$HOME/.zshrc" "$backup"
  fi
  
  # Ensure ~/.config exists (macOS/Linux)
  mkdir -p "$HOME/.config"

  # If user already has Alacritty files, back up conflicting REAL files so stow can link
  if [ -d "$HOME/.config/alacritty" ] && [ ! -L "$HOME/.config/alacritty" ]; then
    for f in alacritty.toml catppuccin-mocha.toml; do
      if [ -e "$HOME/.config/alacritty/$f" ] && [ ! -L "$HOME/.config/alacritty/$f" ]; then
        local backup="$HOME/.config/alacritty/${f}.pre-stow.$(date +%Y%m%d-%H%M%S)"
        log "Backing up existing ~/.config/alacritty/$f -> $backup"
        mv "$HOME/.config/alacritty/$f" "$backup"
      fi
    done
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
    prepare_conflicts
    log "Stowing packages: ${PACKAGES[*]}"
    stow $STOW_FLAGS -t "$TARGET" "${PACKAGES[@]}"
    ;;
  restow)
    prepare_conflicts
    log "Re-stowing packages: ${PACKAGES[*]}"
    stow $STOW_FLAGS -R -t "$TARGET" "${PACKAGES[@]}"
    ;;
  unstow)
    log "Unstowing packages: ${PACKAGES[*]}"
    stow $STOW_FLAGS -D -t "$TARGET" "${PACKAGES[@]}"
    ;;
esac

stow_hypr_if_applicable() {
  # Only on Linux + Hyprland present
  if [[ "$(uname -s)" != "Linux" ]] || ! have hyprctl; then
    log "Hyprland not detected; skipping Hypr config."
    return
  fi

  # Always stow hypr into ~/.config/hypr
  local hypr_pkg="hypr"
  local hypr_pkg_target="$HOME/.config/hypr"

  mkdir -p "$hypr_pkg_target"

  if [[ "$MODE" != "unstow" ]]; then
    local conf="$hypr_pkg_target/hyprland.conf"
    if [[ -e "$conf" && ! -L "$conf" ]]; then
      local backup="${conf}.pre-stow.$(date +%Y%m%d-%H%M%S)"
      log "Backing up existing $conf -> $backup"
      mv "$conf" "$backup"
    fi
  fi

  case "$MODE" in
    stow)
      log "Stowing Hyprland config → $hypr_pkg_target"
      stow $STOW_FLAGS -t "$hypr_pkg_target" "$hypr_pkg"
      ;;
    restow)
      log "Re-stowing Hyprland config → $hypr_pkg_target"
      stow $STOW_FLAGS -R -t "$hypr_pkg_target" "$hypr_pkg"
      ;;
    unstow)
      log "Unstowing Hyprland config ← $hypr_pkg_target"
      stow $STOW_FLAGS -D -t "$hypr_pkg_target" "$hypr_pkg"
      ;;
  esac
}

stow_hypr_if_applicable

if (( DRY_RUN == 0 )) && [ "$MODE" != "unstow" ]; then
  log ""
  log "Verify symlinks (examples):"
  for f in "$HOME/.zshrc" "$HOME/.gitconfig" "$HOME/.config/nvim/init.vim" "$HOME/.config/alacritty/alacritty.toml" "$HOME/.config/hypr/hyprland.conf"; do
    [ -e "$f" ] && ls -l "$f" || true
  done
  log ""
  log "Done."
  log "Tip: run 'zsh' to test immediately.$([ "$DO_CHSH" -eq 1 ] && printf " (Default will apply next login.)")"
fi
