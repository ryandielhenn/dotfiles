#!/usr/bin/env bash
set -euo pipefail

base="$1"
selection=$(cd "$base" && find . -path ./.git -prune -o -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -print \
    | sed 's|^\./||' | sort \
    | dmenu -c -a "$2" -i -l 40 -fn "$3" -nb "$4" -nf "$5" -sb "$6" -sf "$7")

[ -n "$selection" ] || exit 0
ln -sf "$base/$selection" "$base/pick.jpg"
feh --bg-scale "$base/$selection"
