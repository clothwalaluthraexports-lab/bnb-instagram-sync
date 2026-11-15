# bnb-instagram-sync

Hourly GitHub Actions job that downloads new images and videos from the Instagram
profiles listed in `profiles.txt` and saves them to the fabricshoot Google Drive folder `BNB`
(`images/`, `bnb-archive.sqlite3`, `status.txt`). No computer needs to stay on.

## Secrets (Settings → Secrets and variables → Actions)
- `IG_COOKIES` – full text of an exported Instagram `cookies.txt` (fabricshoot login).
- `RCLONE_TOKEN` – the JSON token from `rclone authorize "drive"` signed in as fabricshoot.
- `DRIVE_FOLDER_ID` – ID of the Drive folder `BNB` (kept secret so it never appears in public logs).

## Status
`status.txt` in the Drive folder shows the last run. `flag: LOGIN_EXPIRED` means
the Instagram cookies need re-exporting; everything else retries on the next run.

## Adding a profile
Add the username (no @) on a new line in `profiles.txt`. Its posts go to a Drive folder
with the same name inside `BNB`; the 40-minute hourly budget is shared between profiles.
