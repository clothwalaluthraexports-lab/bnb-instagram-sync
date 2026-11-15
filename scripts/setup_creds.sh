#!/usr/bin/env bash
# Writes the Instagram cookie file and the rclone Drive config from GitHub secrets.
set -euo pipefail
[ -n "${IG_COOKIES:-}" ] || { echo "::error::Missing secret IG_COOKIES"; exit 1; }
[ -n "${RCLONE_TOKEN:-}" ] || { echo "::error::Missing secret RCLONE_TOKEN"; exit 1; }
printf '%s\n' "$IG_COOKIES" > "$RUNNER_TEMP/ig-cookies.txt"
# Accept the token as printed by any rclone version: plain {...} JSON, or the
# newer base64 blob (eyJ...), optionally wrapped as {"token": "..."}.
TOKEN=$(printf '%s' "$RCLONE_TOKEN" | python3 -c '
import sys, json, base64, re
raw = sys.stdin.read()
raw = re.sub(r"(?s).*?--->|<---.*", "", raw).strip()
def parse(text):
    text = text.strip()
    try:
        return json.loads(text)
    except Exception:
        pass
    blob = re.sub(r"\s+", "", text)
    blob += "=" * (-len(blob) % 4)
    for dec in (base64.b64decode, base64.urlsafe_b64decode):
        try:
            return json.loads(dec(blob))
        except Exception:
            pass
    m = re.search(r"\{.*\}", text, re.S)
    return json.loads(m.group(0)) if m else None
t = parse(raw)
for _ in range(3):
    if isinstance(t, dict) and "token" in t and "refresh_token" not in t:
        t = t["token"]
    if isinstance(t, str):
        t = parse(t)
if not (isinstance(t, dict) and t.get("refresh_token")):
    sys.exit(1)
print(json.dumps(t))
' ) || { echo "::error::RCLONE_TOKEN could not be read: paste everything rclone printed between ---> and <---End paste"; exit 1; }
mkdir -p ~/.config/rclone
cat > ~/.config/rclone/rclone.conf <<CONF
[gdrive]
type = drive
scope = drive
token = ${TOKEN}
CONF
