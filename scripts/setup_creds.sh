#!/usr/bin/env bash
# Writes the Instagram cookie file and the rclone Drive config from GitHub secrets.
set -euo pipefail
[ -n "${IG_COOKIES:-}" ] || { echo "::error::Missing secret IG_COOKIES"; exit 1; }
[ -n "${RCLONE_TOKEN:-}" ] || { echo "::error::Missing secret RCLONE_TOKEN"; exit 1; }
[ -n "${DRIVE_ROOT:-}" ] || { echo "::error::Missing secret DRIVE_FOLDER_ID"; exit 1; }
printf '%s\n' "$IG_COOKIES" > "$RUNNER_TEMP/ig-cookies.txt"
# The token must be the full {"access_token":...,"refresh_token":...} JSON line.
TOKEN=$(printf '%s' "$RCLONE_TOKEN" | tr -d '\r\n' | grep -o '{.*}' || true)
echo "$TOKEN" | python3 -c 'import json,sys; t=json.load(sys.stdin); assert "refresh_token" in t' 2>/dev/null \
  || { echo "::error::RCLONE_TOKEN is not the full {...} JSON from 'rclone authorize drive' (it must include refresh_token)"; exit 1; }
mkdir -p ~/.config/rclone
cat > ~/.config/rclone/rclone.conf <<CONF
[gdrive]
type = drive
scope = drive
token = ${TOKEN}
root_folder_id = ${DRIVE_ROOT}
CONF
