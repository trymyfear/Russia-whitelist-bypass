#!/usr/bin/env bash
set -euo pipefail

xray=/opt/whitelist-bypass/relay/bin/xray
config=/tmp/direct-foreign-test.json
log=/tmp/wlb-direct-foreign.log

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
if egress="$(curl -fsS --max-time 20 --socks5-hostname 127.0.0.1:10991 https://api.ipify.org)"; then
  printf 'DIRECT_FOREIGN_EGRESS=%s\n' "$egress"
else
  result=$?
  printf 'DIRECT_FOREIGN_CURL_FAILED=%s\n' "$result"
  cat "$log"
  exit "$result"
fi
cat "$log"
