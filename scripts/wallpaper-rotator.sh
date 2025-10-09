#!/usr/bin/env bash
set -euo pipefail

WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/wallpapers/walls}"
INTERVAL="${INTERVAL:-10}"
TRANSITION_TYPE="${TRANSITION_TYPE:-simple}"

# Detect display server and wallpaper tool
detect_wallpaper_tool() {
  if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    # Wayland - use swww
    if command -v swww >/dev/null 2>&1; then
      echo "swww"
      return 0
    fi
    echo "Error: Running on Wayland but swww not found" >&2
    exit 1
  else
    # X11 - try feh first, then xwallpaper
    if command -v feh >/dev/null 2>&1; then
      echo "feh"
      return 0
    elif command -v xwallpaper >/dev/null 2>&1; then
      echo "xwallpaper"
      return 0
    else
      echo "Error: No wallpaper tool found (need feh or xwallpaper for X11)" >&2
      exit 1
    fi
  fi
}

TOOL=$(detect_wallpaper_tool)
echo "Using wallpaper tool: $TOOL"

# Initialize if needed
if [[ "$TOOL" == "swww" ]]; then
  swww query >/dev/null 2>&1 || { swww init; sleep 0.2; }
fi

# Set wallpaper based on tool
set_wallpaper() {
  local img="$1"
  case "$TOOL" in
    swww)
      swww img "$img" --transition-type "$TRANSITION_TYPE"
      ;;
    feh)
      feh --no-fehbg --bg-fill "$img"
      ;;
    xwallpaper)
      xwallpaper --zoom "$img"
      ;;
  esac
}

build_queue() {
  mapfile -d '' QUEUE < <(find "$WALLPAPER_DIR" -type f -iregex '.*\.\(jpe\?g\|png\|webp\)$' -print0 | shuf -z)
  [[ ${#QUEUE[@]} -gt 0 ]] || { echo "No images found in $WALLPAPER_DIR"; exit 1; }
}

build_queue
echo "Starting wallpaper rotation with ${#QUEUE[@]} images (${INTERVAL}s interval)"

while true; do
  for IMG in "${QUEUE[@]}"; do
    IMG_PATH="$(printf '%s' "$IMG")"
    set_wallpaper "$IMG_PATH"
    sleep "$INTERVAL"
  done
  build_queue  # Rebuild queue for variety
done
