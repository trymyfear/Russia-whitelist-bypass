#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Whitelist Bypass — Russian Relay Deployment Script
# Run this script directly on the Russian Relay VPS (with sudo / as root).
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=== [1/6] Installing Xray-core for Russian Relay ==="
bash "$SCRIPT_DIR/install-xray-core.sh" relay

XRAY_BIN="/opt/whitelist-bypass/relay/bin/xray"
CONFIG_DIR="/opt/whitelist-bypass/relay/config"
CONFIG_FILE="$CONFIG_DIR/config.json"
SERVICE_FILE="/etc/systemd/system/whitelist-bypass-relay.service"
DEVICE_HELPER="/usr/local/sbin/wlb-device"

mkdir -p "$CONFIG_DIR"

echo "=== [2/6] Configuring Firewall (UFW) ==="
bash "$SCRIPT_DIR/configure-relay-firewall.sh"

echo "=== [3/6] Checking Foreign VPS Connection Settings ==="
FOREIGN_IP="${FOREIGN_IP:-}"
FOREIGN_REALITY_PUBLIC_KEY="${FOREIGN_REALITY_PUBLIC_KEY:-}"
FOREIGN_SHORT_ID="${FOREIGN_SHORT_ID:-}"
HOP_UUID="${HOP_UUID:-}"
FOREIGN_SNI="${FOREIGN_SNI:-www.yahoo.com}"

if [[ -z "$FOREIGN_IP" || -z "$FOREIGN_REALITY_PUBLIC_KEY" || -z "$FOREIGN_SHORT_ID" || -z "$HOP_UUID" ]]; then
  echo "Error: The following environment variables are required to link with Foreign VPS:" >&2
  echo "  FOREIGN_IP, FOREIGN_REALITY_PUBLIC_KEY, FOREIGN_SHORT_ID, HOP_UUID" >&2
  echo "Please set them before running deploy-relay.sh." >&2
  exit 1
fi

RELAY_TARGET="${RELAY_TARGET:-ya.ru:443}"
RELAY_SNI="${RELAY_SNI:-ya.ru}"
CLIENT_PRIMARY_UUID="${CLIENT_PRIMARY_UUID:-$(python3 -c 'import uuid; print(uuid.uuid4())' 2>/dev/null || uuidgen | tr '[:upper:]' '[:lower:]')}"

if [[ -z "${RELAY_REALITY_PRIVATE_KEY:-}" || -z "${RELAY_REALITY_PUBLIC_KEY:-}" ]]; then
  echo "Generating new Xray REALITY keypair for Russian Relay..."
  keys_output="$("$XRAY_BIN" x25519)"
  RELAY_REALITY_PRIVATE_KEY="$(echo "$keys_output" | grep -i 'PrivateKey:' | awk '{print $2}' || echo "$keys_output" | grep -i 'Private key:' | awk '{print $3}')"
  RELAY_REALITY_PUBLIC_KEY="$(echo "$keys_output" | grep -i 'Password:' | awk '{print $2}' || echo "$keys_output" | grep -i 'Public key:' | awk '{print $3}')"
fi

RELAY_SHORT_ID="${RELAY_SHORT_ID:-$(openssl rand -hex 8)}"

echo "=== [4/6] Generating config.json from template ==="
TEMPLATE_FILE="$REPO_ROOT/config/templates/relay.json.tmpl"
if [[ ! -f "$TEMPLATE_FILE" ]]; then
  TEMPLATE_FILE="$SCRIPT_DIR/../config/templates/relay.json.tmpl"
fi

sed \
  -e "s|__CLIENT_UUID__|$CLIENT_PRIMARY_UUID|g" \
  -e "s|__RELAY_TARGET__|$RELAY_TARGET|g" \
  -e "s|__RELAY_SNI__|$RELAY_SNI|g" \
  -e "s|__RELAY_PRIVATE_KEY__|$RELAY_REALITY_PRIVATE_KEY|g" \
  -e "s|__RELAY_SHORT_ID__|$RELAY_SHORT_ID|g" \
  -e "s|__FOREIGN_IP__|$FOREIGN_IP|g" \
  -e "s|__HOP_UUID__|$HOP_UUID|g" \
  -e "s|__FOREIGN_SNI__|$FOREIGN_SNI|g" \
  -e "s|__FOREIGN_PUBLIC_KEY__|$FOREIGN_REALITY_PUBLIC_KEY|g" \
  -e "s|__FOREIGN_SHORT_ID__|$FOREIGN_SHORT_ID|g" \
  "$TEMPLATE_FILE" > "$CONFIG_FILE"

chown -R root:whitelist-bypass "/opt/whitelist-bypass/relay"
chmod 0640 "$CONFIG_FILE"

echo "Validating Xray configuration..."
"$XRAY_BIN" run -test -config "$CONFIG_FILE"

echo "=== [5/6] Installing device management helper & systemd service ==="
install -o root -g root -m 0755 "$SCRIPT_DIR/wlb-device" "$DEVICE_HELPER"
cp "$REPO_ROOT/systemd/whitelist-bypass-relay.service" "$SERVICE_FILE"

systemctl daemon-reload
systemctl enable whitelist-bypass-relay.service
systemctl restart whitelist-bypass-relay.service
systemctl is-active --quiet whitelist-bypass-relay.service

echo "=== [6/6] Russian Relay Deployment Complete! ==="

# Get public IP if not set
PUBLIC_IP="${RUSSIAN_IP:-$(curl -fsS --max-time 5 https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}')}"
PRIMARY_LINK="vless://${CLIENT_PRIMARY_UUID}@${PUBLIC_IP}:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${RELAY_SNI}&fp=chrome&pbk=${RELAY_REALITY_PUBLIC_KEY}&sid=${RELAY_SHORT_ID}&spx=%2F&type=tcp#Whitelist-Bypass-Primary"

echo ""
echo "=================================================================="
echo "RELAY CONFIGURATION SUMMARY (save for local scripts):"
echo "------------------------------------------------------------------"
echo "RUSSIAN_IP=$PUBLIC_IP"
echo "RELAY_REALITY_PUBLIC_KEY=$RELAY_REALITY_PUBLIC_KEY"
echo "RELAY_SHORT_ID=$RELAY_SHORT_ID"
echo "RELAY_SNI=$RELAY_SNI"
echo ""
echo "PRIMARY CLIENT VLESS LINK:"
echo "$PRIMARY_LINK"
echo "=================================================================="
