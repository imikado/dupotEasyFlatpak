#!/usr/bin/env bash
# Generate the application screenshots (export/screenshots/*.png) by driving the real UI.
#
# Usage: ./generate_screenshots.sh [-o DIR] [-t dark|light|system] [-l LANG] [-d MS] [SCENE...]
#   -o DIR   output directory          (default: export/screenshots)
#   -t THEME force theme               (default: dark)
#   -l LANG  locale, e.g. fr_FR.UTF-8  (only used when the app language setting is "System")
#   -d MS    settle delay per scene    (default: 2500)
#   SCENE    only these scenes, e.g. Screenshot_home Screenshot_settings
#
# Scenes needing data are skipped with a message: Updates (no update available),
# downgrade/overrides (Steam not installed), import/export (nothing installed).
# Nothing is installed or modified: dialogs are shown with no-op callbacks.
set -euo pipefail
cd "$(dirname "$0")"

OUT="export/screenshots"
THEME="dark"
DELAY="2500"
while getopts "o:t:l:d:h" opt; do
  case "$opt" in
    o) OUT="$OPTARG" ;;
    t) THEME="$OPTARG" ;;
    l) export LANGUAGE="$OPTARG" LANG="$OPTARG" LC_ALL="$OPTARG" ;;
    d) DELAY="$OPTARG" ;;
    *) sed -n '2,13p' "$0"; exit 0 ;;
  esac
done
shift $((OPTIND - 1))

mkdir -p "$OUT"
export EASYFLATPAK_SCREENSHOT_DIR="$(realpath "$OUT")"
export EASYFLATPAK_SCREENSHOT_THEME="$THEME"
export EASYFLATPAK_SCREENSHOT_DELAY="$DELAY"
export EASYFLATPAK_SCREENSHOT_ONLY="$(IFS=,; echo "$*")"

# Use local python if it has GTK4/libadwaita (e.g. inside `nix develop`),
# otherwise run the sources with the runtime of the installed Flatpak.
if python3 -c 'import gi; gi.require_version("Gtk","4.0"); gi.require_version("Adw","1")' 2>/dev/null; then
  exec python3 src/main.py
elif flatpak info org.dupot.easyflatpak >/dev/null 2>&1; then
  exec flatpak run --command=python3 \
    --filesystem="$PWD" --filesystem="$EASYFLATPAK_SCREENSHOT_DIR" \
    --env=EASYFLATPAK_SCREENSHOT_DIR="$EASYFLATPAK_SCREENSHOT_DIR" \
    --env=EASYFLATPAK_SCREENSHOT_THEME="$EASYFLATPAK_SCREENSHOT_THEME" \
    --env=EASYFLATPAK_SCREENSHOT_DELAY="$EASYFLATPAK_SCREENSHOT_DELAY" \
    --env=EASYFLATPAK_SCREENSHOT_ONLY="$EASYFLATPAK_SCREENSHOT_ONLY" \
    ${LANG:+--env=LANG="$LANG" --env=LANGUAGE="${LANGUAGE:-}"} \
    org.dupot.easyflatpak "$PWD/src/main.py"
else
  echo "GTK4/libadwaita not found: run inside 'nix develop' or install org.dupot.easyflatpak" >&2
  exit 1
fi
