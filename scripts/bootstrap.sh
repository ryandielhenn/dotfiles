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
# Back up anything that would block stowing a given package
# --------------------------------------------
# Backup helper
backup_if_real_not_symlink() {
  local p="$1"
  if [[ -e "$p" && ! -L "$p" ]]; then
    local backup="${p}.pre-stow.$(date +%Y%m%d-%H%M%S)"
    log "Backing up $p -> $backup"
    mv "$p" "$backup"
  fi
}

backup_conflicts_for_pkg() {
  local pkg="$1"
  # Ensure parent ~/.config exists (safe no-op if already there)
  mkdir -p "$HOME/.config"

  # Ask stow what it would link; free those targets if they’re not symlinks
  stow -n -v -t "$TARGET" "$pkg" 2>&1 | awk '
    $1 ~ /^(LINK:|RELINK:)/ { print $2 }
  ' | while IFS= read -r target; do
    backup_if_real_not_symlink "$target"
  done
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
  stow|restow)
    # Back up conflicts dynamically
    for pkg in "${PACKAGES[@]}"; do
      backup_conflicts_for_pkg "$pkg"
    done
    log "$([[ "$MODE" == "restow" ]] && echo "Re-stowing" || echo "Stowing") packages: ${PACKAGES[*]}"
    stow $STOW_FLAGS $([[ "$MODE" == "restow" ]] && echo "-R") -t "$TARGET" "${PACKAGES[@]}"
    ;;
  unstow)
    log "Unstowing packages: ${PACKAGES[*]}"
    stow $STOW_FLAGS -D -t "$TARGET" "${PACKAGES[@]}"
    ;;
esac

stow_hypr_if_applicable() {
  if [[ "$(uname -s)" != "Linux" ]] || ! have hyprctl; then
    log "Hyprland not detected; skipping Hypr config."
    return
  fi
  [[ -d "hypr/.config/hypr" ]] || { log "Expected 'hypr/.config/hypr'."; return; }

  # parent only; do NOT mkdir ~/.config/hypr (we want a dir symlink there)
  mkdir -p "$HOME/.config"
  [[ "$MODE" != "unstow" ]] && backup_conflicts_for_pkg hypr

  case "$MODE" in
    stow)   log "Stowing Hyprland → $TARGET"; stow $STOW_FLAGS -t "$TARGET" hypr ;;
    restow) log "Re-stowing Hyprland → $TARGET"; stow $STOW_FLAGS -R -t "$TARGET" hypr ;;
    unstow) log "Unstowing Hyprland ← $TARGET"; stow $STOW_FLAGS -D -t "$TARGET" hypr ;;
  esac
}

stow_waybar_if_applicable() {
  if [[ "$(uname -s)" != "Linux" ]] || ! have waybar; then
    log "Waybar not detected; skipping Waybar config."
    return
  fi
  [[ -d "waybar/.config/waybar" ]] || { log "Expected 'waybar/.config/waybar'."; return; }

  mkdir -p "$HOME/.config"
  [[ "$MODE" != "unstow" ]] && backup_conflicts_for_pkg waybar

  case "$MODE" in
    stow)   log "Stowing Waybar → $TARGET"; stow $STOW_FLAGS -t "$TARGET" waybar ;;
    restow) log "Re-stowing Waybar → $TARGET"; stow $STOW_FLAGS -R -t "$TARGET" waybar ;;
    unstow) log "Unstowing Waybar ← $TARGET"; stow $STOW_FLAGS -D -t "$TARGET" waybar ;;
  esac
}

stow_hypr_if_applicable
stow_waybar_if_applicable

if (( DRY_RUN == 0 )) && [ "$MODE" != "unstow" ]; then
  log ""
  log "Verify symlinks (examples):"
  for f in "$HOME/.zshrc" \
        "$HOME/.gitconfig" \
        "$HOME/.config/nvim" \
        "$HOME/.config/alacritty" \
        "$HOME/.config/hypr" \
        "$HOME/.config/waybar"
    do
    [ -e "$f" ] && ls -l "$f" || true
  done
  log ""
  log "Done."
  log "Tip: run 'zsh' to test immediately.$([ "$DO_CHSH" -eq 1 ] && printf " (Default will apply next login.)")"
fi
