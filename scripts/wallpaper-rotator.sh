#!/usr/bin/env bash
set -euo pipefail

WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/wallpapers/walls}"
INTERVAL="${INTERVAL:-10}"
TRANSITION_TYPE="${TRANSITION_TYPE:-simple}"

command -v swww >/dev/null 2>&1 || { echo "Missing swww"; exit 1; }

# Ensure daemon is running
swww query >/dev/null 2>&1 || { swww init; sleep 0.2; }

build_queue() {
  mapfile -d '' QUEUE < <(find "$WALLPAPER_DIR" -type f -iregex '.*\.\(jpe\?g\|png\|webp\)$' -print0 | shuf -z)
  [[ ${#QUEUE[@]} -gt 0 ]] || { echo "No images found."; exit 1; }
}

build_queue

while true; do
  for IMG in "${QUEUE[@]}"; do
    IMG_PATH="$(printf '%s' "$IMG")"
    swww img "$IMG_PATH" --transition-type "$TRANSITION_TYPE"
    sleep "$INTERVAL"
  done
  build_queue
done

