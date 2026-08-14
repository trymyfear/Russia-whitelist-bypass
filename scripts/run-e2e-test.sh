#!/usr/bin/env bash
set -euo pipefail

xray=/opt/whitelist-bypass/foreign/bin/xray
config=/tmp/e2e-test-client.json
log=/tmp/wlb-e2e.log

"$xray" run -test -config "$config"
"$xray" run -config "$config" >"$log" 2>&1 &
test_pid=$!
cleanup() {
  kill "$test_pid" 2>/dev/null || true
  wait "$test_pid" 2>/dev/null || true
}
trap cleanup EXIT

sleep 2
kill -0 "$test_pid"

expected_egress="${1:-${EXPECTED_EGRESS:-}}"
egress="$(curl -fsS --max-time 20 --socks5-hostname 127.0.0.1:10990 https://api.ipify.org)"
printf 'EGRESS_IP=%s\n' "$egress"
if [[ -n "$expected_egress" ]]; then
  test "$egress" = "$expected_egress"
fi

curl -fsS --max-time 20 --socks5-hostname 127.0.0.1:10990 \
  -o /dev/null -w 'HTTPS_STATUS=%{http_code}\n' \
  https://www.cloudflare.com/cdn-cgi/trace

python3 /tmp/dns-udp-test.py
printf 'XRAY_TEST_LOG\n'
tail -n 20 "$log"
