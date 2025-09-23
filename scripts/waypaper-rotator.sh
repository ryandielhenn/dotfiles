#!/usr/bin/env bash
set -euo pipefail

# Ensure local bin is available even in minimal environments
export PATH="$HOME/.local/bin:$PATH"

######################################################################
# Program to cycle wallpapers in a given directory and subdirectories.
#
# TODO: Cycling background photos doesn't require waypaper just swww. 
# Transition the script to wallcycle pause | resume | status | start.
# Let waypaper automatically pause the rotator via its post command.
######################################################################

WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/wallpapers/walls}"
INTERVAL="${INTERVAL:-5}"  # seconds

# File types to include (case-insensitive)
IMAGE_REGEX='.*\.\(jpe\?g\|png\|webp\)$'

require() {
  command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1"; exit 1; }
}
require find
require shuf
require waypaper

build_queue() {
  # Build a shuffled, null-delimited list of images into an array
  # -print0 and mapfile -d '' handle spaces/newlines safely
  mapfile -d '' QUEUE < <(
    find "$WALLPAPER_DIR" -type f -iregex "$IMAGE_REGEX" -print0 | shuf -z
  )
  if [[ ${#QUEUE[@]} -eq 0 ]]; then
    echo "No images found in: $WALLPAPER_DIR"
    exit 1
  fi
}

# Initial queue
build_queue

while true; do
  for IMG in "${QUEUE[@]}"; do
    # -z removes the trailing null from mapfile chunks; use printf to be safe
    IMG_PATH="$(printf '%s' "$IMG")"
    waypaper --backend swww --wallpaper "$IMG_PATH" --fill fill
    sleep "$INTERVAL"
  done
  # Rebuild (reshuffle) for the next round
  build_queue
done

