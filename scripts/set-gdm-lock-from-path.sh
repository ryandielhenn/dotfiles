#!/usr/bin/env bash
# set-gdm-lock-from-path (minimal gresource swap)
set -euo pipefail

THEME_RES="/usr/share/gnome-shell/gnome-shell-theme.gresource"

[[ $EUID -eq 0 ]] || { echo "Run as root (pkexec $0 /abs/image)"; exit 1; }
SRC="${1:-}"; [[ -n "$SRC" && -f "$SRC" && "$SRC" = /* ]] || { echo "Usage: $0 /absolute/image"; exit 2; }

command -v gresource >/dev/null || { echo "gresource not found"; exit 3; }
command -v glib-compile-resources >/dev/null || { echo "glib-compile-resources not found"; exit 3; }

work="$(mktemp -d /tmp/gdm-theme.XXXXXX)"
trap 'rm -rf "$work"' EXIT
cd "$work"

# Extract
while read -r res; do
  mkdir -p ".${res%/*}"
  gresource extract "$THEME_RES" "$res" > ".${res}"
done < <(gresource list "$THEME_RES")

# Replace any background* under /org/gnome/shell/theme
changed=0
while read -r path; do
  install -m 0644 "$SRC" ".$path"
  changed=1
done < <(gresource list "$THEME_RES" | grep -E '^/org/gnome/shell/theme/background')
[[ $changed -eq 1 ]] || { echo "No background* resources found"; exit 4; }

# Rebuild bundle
cat > gnome-shell-theme.gresource.xml <<'XML'
<gresources>
  <gresource prefix="/org/gnome/shell">
XML
( cd ./org/gnome/shell && find . -type f -printf '%P\n' | sed 's/^/    <file>/' | sed 's/$/<\/file>/' ) >> gnome-shell-theme.gresource.xml
cat >> gnome-shell-theme.gresource.xml <<'XML'
  </gresource>
</gresources>
XML

glib-compile-resources gnome-shell-theme.gresource.xml \
  --target=gnome-shell-theme.gresource \
  --sourcedir=./org/gnome/shell

cp -v "$THEME_RES" "${THEME_RES}.bak.$(date +%F-%H%M%S)"
install -m 0644 gnome-shell-theme.gresource "$THEME_RES"

echo "Done. Reboot or: systemctl restart gdm   (logs you out)"
