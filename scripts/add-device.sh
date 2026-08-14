#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(dirname "$script_dir")"

load_env() {
  local env_file="$1"
  if [[ -f "$env_file" ]]; then
    while IFS='=' read -r key val || [[ -n "$key" ]]; do
      [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
      key="$(echo "$key" | xargs)"
      val="$(echo "$val" | xargs | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")"
      if [[ -z "${!key:-}" ]]; then
        export "$key"="$val"
      fi
    done < "$env_file"
  fi
}

load_env "$project_root/config.env"
load_env "$project_root/.env"
load_env "$project_root/artifacts/private/deployment.env"

name="${1:-}"
if [[ -z "$name" ]]; then
  echo "Usage: $0 <device-name>" >&2
  exit 1
fi

if [[ ! "$name" =~ ^[A-Za-z0-9._-]{1,48}$ ]]; then
  echo "Error: Device name must contain only A-Za-z0-9._- (1-48 chars)" >&2
  exit 1
fi

relay_host="${RUSSIAN_IP:-}"
relay_user="${RUSSIAN_LOGIN:-whitelist}"
relay_port="${RUSSIAN_PORT:-443}"
relay_public_key="${RELAY_REALITY_PUBLIC_KEY:-}"
relay_short_id="${RELAY_SHORT_ID:-}"
relay_sni="${RELAY_SNI:-ya.ru}"

if [[ -z "$relay_host" ]]; then
  echo "Error: RUSSIAN_IP is not set. Specify it in config.env or export RUSSIAN_IP." >&2
  exit 1
fi

if [[ -z "$relay_public_key" || -z "$relay_short_id" ]]; then
  echo "Error: RELAY_REALITY_PUBLIC_KEY or RELAY_SHORT_ID is not set in config.env." >&2
  exit 1
fi

key_path="${SSH_KEY_PATH:-$project_root/.secrets/project_ed25519}"
known_hosts="${KNOWN_HOSTS_PATH:-$project_root/.secrets/known_hosts}"

ssh_opts=("-o" "BatchMode=yes" "-o" "StrictHostKeyChecking=accept-new")
if [[ -f "$key_path" ]]; then
  ssh_opts+=("-i" "$key_path")
fi
if [[ -f "$known_hosts" ]]; then
  ssh_opts+=("-o" "UserKnownHostsFile=$known_hosts")
fi

uuid="$(python3 -c 'import uuid; print(uuid.uuid4())' 2>/dev/null || uuidgen | tr '[:upper:]' '[:lower:]')"

echo "Adding device '$name' on relay $relay_host..."
ssh "${ssh_opts[@]}" "$relay_user@$relay_host" "sudo -n /usr/local/sbin/wlb-device add '$name' '$uuid'"

link="vless://${uuid}@${relay_host}:${relay_port}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${relay_sni}&fp=chrome&pbk=${relay_public_key}&sid=${relay_short_id}&spx=%2F&type=tcp#Whitelist-Bypass-${name}"

out_dir="$project_root/artifacts/private"
mkdir -p "$out_dir"
link_file="$out_dir/$name.txt"
qr_file="$out_dir/$name-qr.png"

printf '%s\n' "$link" > "$link_file"

if python3 "$script_dir/make-qr.py" "$link" "$qr_file" >/dev/null 2>&1; then
  echo "QR Code generated: $qr_file"
fi

echo "========================================================"
echo "Device '$name' added successfully!"
echo "VLESS Link: $link"
echo "Saved to:   $link_file"
echo "========================================================"
