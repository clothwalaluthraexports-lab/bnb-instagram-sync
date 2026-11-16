#!/usr/bin/env bash
# One scheduled run: download new images and videos from every source in
# sources.txt (Instagram profiles, Pinterest boards/searches), sharing ~40
# minutes between them, and upload each source to its own Drive folder.
set -uo pipefail
REPO="$PWD"
WORK="$RUNNER_TEMP/work"; mkdir -p "$WORK"; cd "$WORK"
: > gdl.log; : > summary.txt
SYS="Reference Downloads/_system"
LEGACY="instagram page post   trending post nov 2026/BNB"
rclone lsjson gdrive: --max-depth 1 >/dev/null || { echo "DRIVE_LOGIN_BROKEN" > drive_error; exit 1; }
# One shared download record, so nothing is downloaded twice.
rclone copy "gdrive:$SYS/archive.sqlite3" . 2>/dev/null
[ -f archive.sqlite3 ] || { rclone copyto "gdrive:$LEGACY/bnb-archive.sqlite3" archive.sqlite3 2>/dev/null || echo "Starting a fresh download record"; }

mapfile -t LINES < <(grep -vE '^\s*(#|$)' "$REPO/sources.txt" | tr -d '\r')
N=${#LINES[@]}; [ "$N" -gt 0 ] || { echo "sources.txt is empty"; exit 1; }
PER=$(( 40 / N )); [ "$PER" -lt 4 ] && PER=4
trim() { sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' <<<"$1"; }

i=0
for LINE in "${LINES[@]}"; do
  IFS='|' read -r PLAT WHAT DEST LIMIT <<<"$LINE"
  PLAT=$(trim "${PLAT,,}"); WHAT=$(trim "$WHAT"); DEST=$(trim "${DEST:-}"); LIMIT=$(trim "${LIMIT:-}")
  case "$PLAT" in
    instagram)
      USER="${WHAT#@}"; USER="${USER%/}"; USER="${USER##*/}"
      URL="https://www.instagram.com/$USER/"
      [ -n "$DEST" ] || DEST="Reference Downloads/Instagram - $USER"
      AUTH=(--cookies "$RUNNER_TEMP/ig-cookies.txt"); NAME="instagram:$USER" ;;
    pinterest)
      URL="$WHAT"
      if [ -z "$DEST" ]; then
        LABEL=$(python3 -c 'import sys,urllib.parse as u; p=u.urlparse(sys.argv[1]); q=u.parse_qs(p.query).get("q"); print(q[0] if q else " ".join(x for x in p.path.split("/") if x))' "$URL")
        DEST="Reference Downloads/Pinterest - ${LABEL//\//-}"
      fi
      AUTH=(); NAME="pinterest:$URL"
      [ -n "$LIMIT" ] || LIMIT=300 ;;
    *) echo "skipped unknown platform: $LINE" | tee -a summary.txt; continue ;;
  esac
  i=$((i+1)); OUT="dl/$i"; mkdir -p "$OUT"
  RANGE=(); [ -n "$LIMIT" ] && RANGE=(--range "1-$LIMIT")
  timeout "${PER}m" gallery-dl "${AUTH[@]}" "${RANGE[@]}" \
    --download-archive archive.sqlite3 \
    --sleep 3-6 --sleep-request 4-9 \
    -D "$OUT" "$URL" >> gdl.log 2>&1
  CODE=$?
  IMG=$(find "$OUT" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.png' \) | wc -l)
  VID=$(find "$OUT" -type f \( -iname '*.mp4' -o -iname '*.webm' \) | wc -l)
  echo "$NAME -> $DEST: exit $CODE, images $IMG, videos $VID  (124 = time share used up, normal)" | tee -a summary.txt
  # A destination written as "id:<Drive folder id>" uploads straight into that
  # exact folder (a name path can resolve to a new look-alike folder instead).
  if [[ "$DEST" == id:* ]]; then TARGET="gdrive,root_folder_id=${DEST#id:}:"; else TARGET="gdrive:$DEST"; fi
  rclone copy "$OUT" "$TARGET" --transfers 8 --ignore-existing || echo "UPLOAD_FAILED $NAME" >> drive_error
  # Record which Drive folder (id) received the files and how many it now holds.
  if [[ "$DEST" == id:* ]]; then FID="${DEST#id:}"; else
  FID=$(rclone lsjson --stat "gdrive:$DEST" 2>/dev/null | python3 -c 'import sys,json; print(json.load(sys.stdin).get("ID","?"))' 2>/dev/null || echo "?"); fi
  CNT=$(rclone lsf "$TARGET" --files-only 2>/dev/null | wc -l)
  echo "  uploaded to Drive folder id $FID, now $CNT files" | tee -a summary.txt
  rclone copyto archive.sqlite3 "gdrive:$SYS/archive.sqlite3" 2>/dev/null
  rm -rf "$OUT"   # free runner disk before the next source
done
[ -f drive_error ] && exit 1
exit 0
