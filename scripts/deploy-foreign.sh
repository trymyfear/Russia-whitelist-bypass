#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Whitelist Bypass — Foreign Exit Deployment Script
# Run this script directly on the Foreign VPS (or via SSH as root).
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=== [1/5] Installing Xray-core for Foreign Exit ==="
bash "$SCRIPT_DIR/install-xray-core.sh" foreign

XRAY_BIN="/opt/whitelist-bypass/foreign/bin/xray"
CONFIG_DIR="/opt/whitelist-bypass/foreign/config"
CONFIG_FILE="$CONFIG_DIR/config.json"
SERVICE_FILE="/etc/systemd/system/whitelist-bypass-foreign.service"

mkdir -p "$CONFIG_DIR"

echo "=== [2/5] Configuring REALITY & UUID Credentials ==="
HOP_UUID="${HOP_UUID:-$(python3 -c 'import uuid; print(uuid.uuid4())' 2>/dev/null || uuidgen | tr '[:upper:]' '[:lower:]')}"
FOREIGN_TARGET="${FOREIGN_TARGET:-www.yahoo.com:443}"
FOREIGN_SNI="${FOREIGN_SNI:-www.yahoo.com}"

if [[ -z "${FOREIGN_REALITY_PRIVATE_KEY:-}" || -z "${FOREIGN_REALITY_PUBLIC_KEY:-}" ]]; then
  echo "Generating new Xray REALITY keypair for Foreign host..."
  keys_output="$("$XRAY_BIN" x25519)"
  FOREIGN_REALITY_PRIVATE_KEY="$(echo "$keys_output" | grep -i 'PrivateKey:' | awk '{print $2}' || echo "$keys_output" | grep -i 'Private key:' | awk '{print $3}')"
  FOREIGN_REALITY_PUBLIC_KEY="$(echo "$keys_output" | grep -i 'Password:' | awk '{print $2}' || echo "$keys_output" | grep -i 'Public key:' | awk '{print $3}')"
fi

FOREIGN_SHORT_ID="${FOREIGN_SHORT_ID:-$(openssl rand -hex 8)}"

echo "=== [3/5] Generating config.json from template ==="
TEMPLATE_FILE="$REPO_ROOT/config/templates/foreign.json.tmpl"
if [[ ! -f "$TEMPLATE_FILE" ]]; then
  TEMPLATE_FILE="$SCRIPT_DIR/../config/templates/foreign.json.tmpl"
fi

sed \
  -e "s|__HOP_UUID__|$HOP_UUID|g" \
  -e "s|__FOREIGN_TARGET__|$FOREIGN_TARGET|g" \
  -e "s|__FOREIGN_SNI__|$FOREIGN_SNI|g" \
  -e "s|__FOREIGN_PRIVATE_KEY__|$FOREIGN_REALITY_PRIVATE_KEY|g" \
  -e "s|__FOREIGN_SHORT_ID__|$FOREIGN_SHORT_ID|g" \
  "$TEMPLATE_FILE" > "$CONFIG_FILE"

chown -R root:whitelist-bypass "/opt/whitelist-bypass/foreign"
chmod 0640 "$CONFIG_FILE"

echo "Validating Xray configuration..."
"$XRAY_BIN" run -test -config "$CONFIG_FILE"

echo "=== [4/5] Installing and starting systemd service ==="
cp "$REPO_ROOT/systemd/whitelist-bypass-foreign.service" "$SERVICE_FILE"
systemctl daemon-reload
systemctl enable whitelist-bypass-foreign.service
systemctl restart whitelist-bypass-foreign.service
systemctl is-active --quiet whitelist-bypass-foreign.service

echo "=== [5/5] Foreign Exit Deployment Complete! ==="
echo ""
echo "Save these values to configure your Russian Relay node:"
echo "------------------------------------------------------------------"
echo "FOREIGN_REALITY_PUBLIC_KEY=$FOREIGN_REALITY_PUBLIC_KEY"
echo "FOREIGN_SHORT_ID=$FOREIGN_SHORT_ID"
echo "HOP_UUID=$HOP_UUID"
echo "FOREIGN_SNI=$FOREIGN_SNI"
echo "------------------------------------------------------------------"
