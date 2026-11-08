#!/usr/bin/env bash
# Refresh the Flathub snapshot shipped with the app, so first install / update
# doesn't have to download it on the user's machine:
#   src/assets/db/flathub_database.db  (new apps, home lists)
#   src/assets/icons/                  (missing icons)
#
# Usage: ./syncFlathubApi.sh [--full] [--prune] [--refresh-icons] [--dry-run] [--workers N]
#   --full           also refresh details of every existing app (~7000 requests)
#   --prune          remove apps no longer on Flathub (and their icon)
#   --refresh-icons  re-download all icons
#   --dry-run        only show what would change
#
# Users get the new snapshot on the next version bump (installed_version.json),
# since the asset DB is only re-copied when the app version changes.
set -euo pipefail
cd "$(dirname "$0")/src"
exec python3 update_database_from_api.py "$@"
