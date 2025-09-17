#!/usr/bin/env bash
set -euo pipefail

CFG="$HOME/.config/wallpicker/current_dir"
DEFAULT_DIR="$HOME/Pictures/wallpapers"

# Pick saved dir, fall back if missing/invalid
DIR="$(cat "$CFG" 2>/dev/null || true)"
[[ -n "${DIR:-}" && -d "$DIR" ]] || DIR="$DEFAULT_DIR"

# Ask hellpaper for an image path
IMG="$("$HOME/src/hellpaper/hellpaper" "$DIR")"
[[ -n "$IMG" ]] || exit 0

# Set Hyprland wallpaper
swww img "$IMG" &

# Cache last-picked image
mkdir -p ~/.cache
echo "$IMG" > ~/.cache/hellpaper-last

# Optionally set GDM lockscreen if flag is set
if [[ "${SET_GDM:-0}" == "1" ]]; then
  pkexec /usr/local/bin/set-gdm-lock-from-path "$IMG" || \
    notify-send "Wallpicker" "Failed to update GDM lockscreen (pkexec canceled?)"
fi
