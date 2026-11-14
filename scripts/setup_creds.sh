#!/usr/bin/env bash
# Writes the Instagram cookie file and the rclone Drive config from GitHub secrets.
set -euo pipefail
[ -n "${IG_COOKIES:-}" ] || { echo "Missing secret IG_COOKIES"; exit 1; }
[ -n "${RCLONE_TOKEN:-}" ] || { echo "Missing secret RCLONE_TOKEN"; exit 1; }
[ -n "${DRIVE_ROOT:-}" ] || { echo "Missing secret DRIVE_FOLDER_ID"; exit 1; }
printf '%s\n' "$IG_COOKIES" > "$RUNNER_TEMP/ig-cookies.txt"
mkdir -p ~/.config/rclone
cat > ~/.config/rclone/rclone.conf <<CONF
[gdrive]
type = drive
scope = drive
token = ${RCLONE_TOKEN}
root_folder_id = ${DRIVE_ROOT}
CONF
