#!/usr/bin/env bash
set -euo pipefail

WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/wallpapers/walls}"
INTERVAL="${INTERVAL:-10}"
TRANSITION_TYPE="${TRANSITION_TYPE:-simple}"
TOOL="feh"

build_queue() {
  mapfile -d '' QUEUE < <(find "$WALLPAPER_DIR" -type f -iregex '.*\.\(jpe\?g\|png\|webp\)$' -print0 | shuf -z)
  [[ ${#QUEUE[@]} -gt 0 ]] || { echo "No images found in $WALLPAPER_DIR"; exit 1; }
}

build_queue
echo "Starting wallpaper rotation with ${#QUEUE[@]} images (${INTERVAL}s interval)"

while true; do
  for IMG in "${QUEUE[@]}"; do
    IMG_PATH="$(printf '%s' "$IMG")"
    feh --no-fehbg --bg-fill "$IMG_PATH"
    sleep "$INTERVAL"
  done
  build_queue
done
