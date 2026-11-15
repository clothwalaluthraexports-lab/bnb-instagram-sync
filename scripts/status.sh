#!/usr/bin/env bash
# Writes status.txt to the Drive folder so progress and errors can be checked remotely.
set -uo pipefail
W="$RUNNER_TEMP/work"
FLAG=""
[ -f "$W/drive_error" ] && FLAG="DRIVE_UPLOAD_FAILED: $(head -c 200 "$W/drive_error") - check the RCLONE_TOKEN secret"
grep -qE "401 Unauthorized|login_required|LoginRequired" "$W/gdl.log" 2>/dev/null && FLAG="${FLAG:-LOGIN_EXPIRED: export a fresh ig-cookies.txt and update the IG_COOKIES secret}"
grep -qiE "429 Too Many|rate.?limit" "$W/gdl.log" 2>/dev/null && FLAG="${FLAG:-RATE_LIMITED: Instagram is slowing requests, next run retries automatically}"
{
  echo "time_utc: $(date -u +%FT%TZ)"
  echo "job: $1"
  echo "flag: ${FLAG:-OK}"
  echo "--- per source this run ---"
  cat "$W/summary.txt" 2>/dev/null
  echo "--- last log lines ---"
  tail -n 15 "$W/gdl.log" 2>/dev/null
} > "$RUNNER_TEMP/status.txt"
cat "$RUNNER_TEMP/status.txt"
rclone copyto "$RUNNER_TEMP/status.txt" "gdrive:Reference Downloads/_system/status.txt" || echo "::error::Could not write status.txt to Drive - RCLONE_TOKEN is probably wrong"
