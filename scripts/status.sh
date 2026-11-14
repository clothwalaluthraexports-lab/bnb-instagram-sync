#!/usr/bin/env bash
# Writes status.txt to the Drive folder so progress and errors can be checked remotely.
set -uo pipefail
W="$RUNNER_TEMP/work"
CODE=$(cat "$W/exit_code" 2>/dev/null || echo "none")
NEW=$(cat "$W/new_count" 2>/dev/null || echo 0)
ERR=""
grep -q "401" "$W/gdl.log" 2>/dev/null && ERR="LOGIN_EXPIRED: export a fresh ig-cookies.txt and update the IG_COOKIES secret"
grep -qi "429\|rate limit\|Too Many" "$W/gdl.log" 2>/dev/null && ERR="${ERR:-RATE_LIMITED: Instagram is slowing requests, next run retries automatically}"
[ "$CODE" = "0" ] && ERR="${ERR:-ALL_POSTS_DONE}"
{
  echo "time_utc: $(date -u +%FT%TZ)"
  echo "job: $1"
  echo "gallery_dl_exit: $CODE  (124 = stopped at 40 min, normal)"
  echo "new_images_this_run: $NEW"
  echo "flag: ${ERR:-OK}"
  echo "--- last log lines ---"
  tail -n 15 "$W/gdl.log" 2>/dev/null
} > "$RUNNER_TEMP/status.txt"
cat "$RUNNER_TEMP/status.txt"
rclone copyto "$RUNNER_TEMP/status.txt" gdrive:status.txt || true
