#!/usr/bin/env bash
# One hourly run: pull the shared download archive from Drive, fetch new posts
# for up to ~40 minutes, push new images and the archive back to Drive.
set -uo pipefail
WORK="$RUNNER_TEMP/work"; mkdir -p "$WORK/images"; cd "$WORK"
rclone copy gdrive:bnb-archive.sqlite3 . 2>/dev/null || echo "No archive yet - starting fresh"
START=$(date +%s)
timeout 40m gallery-dl \
  --cookies "$RUNNER_TEMP/ig-cookies.txt" \
  --download-archive bnb-archive.sqlite3 \
  -o videos=false \
  --sleep 3-6 --sleep-request 4-9 \
  -D images \
  "$PROFILE" > gdl.log 2>&1
CODE=$?
echo "$CODE" > exit_code
NEW=$(find images -type f -name '*.jpg' | wc -l)
echo "$NEW" > new_count
echo "gallery-dl exit $CODE, new images $NEW, seconds $(( $(date +%s) - START ))"
tail -n 20 gdl.log
rclone copy images gdrive:images --transfers 8 --ignore-existing
[ -f bnb-archive.sqlite3 ] && rclone copyto bnb-archive.sqlite3 gdrive:bnb-archive.sqlite3
exit 0
