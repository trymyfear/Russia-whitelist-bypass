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

relay_host="${RUSSIAN_IP:-}"
relay_user="${RUSSIAN_LOGIN:-whitelist}"

if [[ -z "$relay_host" ]]; then
  echo "Error: RUSSIAN_IP is not set. Specify it in config.env or export RUSSIAN_IP." >&2
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

echo "Removing device '$name' on relay $relay_host..."
ssh "${ssh_opts[@]}" "$relay_user@$relay_host" "sudo -n /usr/local/sbin/wlb-device remove '$name'"

echo "Device '$name' removed successfully."
