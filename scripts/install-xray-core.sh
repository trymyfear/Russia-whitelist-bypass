#!/usr/bin/env bash
set -euo pipefail

role="${1:?usage: install-xray-core.sh <foreign|relay>}"
case "$role" in
  foreign|relay) ;;
  *) echo "unsupported role: $role" >&2; exit 2 ;;
esac

base="/opt/whitelist-bypass/$role"
install -d -m 0755 "$base" "$base/bin" "$base/config"

if ! id -u whitelist-bypass >/dev/null 2>&1; then
  useradd --system --home-dir /nonexistent --shell /usr/sbin/nologin whitelist-bypass
fi

release_json="$(curl -fsSL --retry 3 https://api.github.com/repos/XTLS/Xray-core/releases/latest)"
tag="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["tag_name"])' <<<"$release_json")"
archive="$(mktemp)"
trap 'rm -f "$archive"' EXIT
curl -fL --retry 3 -o "$archive" "https://github.com/XTLS/Xray-core/releases/download/$tag/Xray-linux-64.zip"

python3 - "$archive" "$base/bin" <<'PY'
import pathlib
import sys
import zipfile

archive = pathlib.Path(sys.argv[1])
destination = pathlib.Path(sys.argv[2])
with zipfile.ZipFile(archive) as bundle:
    names = set(bundle.namelist())
    for name in ("xray", "geoip.dat", "geosite.dat"):
        if name in names:
            target = destination / name
            target.write_bytes(bundle.read(name))
if not (destination / "xray").is_file():
    raise SystemExit("Xray binary is missing from release archive")
PY

chmod 0755 "$base/bin/xray"
chmod 0644 "$base/bin/geoip.dat" "$base/bin/geosite.dat" 2>/dev/null || true
printf '%s\n' "$tag" >"$base/VERSION"
chmod 0644 "$base/VERSION"

"$base/bin/xray" version | head -n 1

