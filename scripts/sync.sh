#!/usr/bin/env bash
# One hourly run: pull the shared download archive from Drive, fetch new posts
# (images and videos) from every profile in profiles.txt, sharing ~40 minutes
# between them, then push new files and the archive back to Drive.
set -uo pipefail
REPO="$PWD"
WORK="$RUNNER_TEMP/work"; mkdir -p "$WORK"; cd "$WORK"
: > gdl.log; : > summary.txt
rclone lsjson gdrive: --max-depth 1 >/dev/null || { echo "DRIVE_LOGIN_BROKEN" > drive_error; exit 1; }
rclone copy gdrive:bnb-archive.sqlite3 . 2>/dev/null || echo "No archive yet - starting fresh"
mapfile -t PROFILES < <(grep -vE '^\s*(#|$)' "$REPO/profiles.txt" | tr -d ' @\r')
N=${#PROFILES[@]}; [ "$N" -gt 0 ] || { echo "profiles.txt is empty"; exit 1; }
PER=$(( 40 / N )); [ "$PER" -lt 5 ] && PER=5
for USER in "${PROFILES[@]}"; do
  DIR="$USER"; [ "$USER" = "bnbbutixfabric" ] && DIR="images"
  mkdir -p "dl/$DIR"
  timeout "${PER}m" gallery-dl \
    --cookies "$RUNNER_TEMP/ig-cookies.txt" \
    --download-archive bnb-archive.sqlite3 \
    --sleep 3-6 --sleep-request 4-9 \
    -D "dl/$DIR" \
    "https://www.instagram.com/$USER/" >> gdl.log 2>&1
  CODE=$?
  IMG=$(find "dl/$DIR" -type f \( -name '*.jpg' -o -name '*.webp' -o -name '*.png' \) | wc -l)
  VID=$(find "dl/$DIR" -type f -name '*.mp4' | wc -l)
  echo "$USER: exit $CODE, images $IMG, videos $VID  (124 = time share used up, normal)" | tee -a summary.txt
  rclone copy "dl/$DIR" "gdrive:$DIR" --transfers 8 --ignore-existing || echo "UPLOAD_FAILED $USER" >> drive_error
  [ -f bnb-archive.sqlite3 ] && rclone copyto bnb-archive.sqlite3 gdrive:bnb-archive.sqlite3
  rm -rf "dl/$DIR"   # free runner disk before the next profile
done
[ -f drive_error ] && exit 1
exit 0
