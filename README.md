# bnb-instagram-sync

Scheduled GitHub Actions job that downloads new images and videos from the
sources listed in `sources.txt` (Instagram profiles, Pinterest boards and
searches) and saves each source to its own folder in the fabricshoot Google
Drive, under `Reference Downloads/`. No computer needs to stay on.

## Adding a source
Add a line to `sources.txt`, e.g.

    instagram | someusername
    pinterest | https://www.pinterest.com/name/board-name/
    pinterest | https://www.pinterest.com/search/pins/?q=ikat%20print | | 300

Pinterest searches are endless, so they are capped at 300 new pins per run
unless a different limit is given.

## Secrets (Settings -> Secrets and variables -> Actions)
- `IG_COOKIES` - text of an exported Instagram `cookies.txt` (fabricshoot login).
- `RCLONE_TOKEN` - the full `{...}` JSON line from `rclone authorize "drive"`
  signed in as fabricshoot (must include `refresh_token`).

## Status
`Reference Downloads/_system/status.txt` in Drive shows the last run.
`flag: LOGIN_EXPIRED` means the Instagram cookies need re-exporting;
`DRIVE_UPLOAD_FAILED` means `RCLONE_TOKEN` is wrong. Everything else retries.
