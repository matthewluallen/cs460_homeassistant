#!/usr/bin/env bash
# CS460 Module 5 — connection-gated keep-alive so the Codespace does not idle
# out mid-class. Mirrors the cs460_caldera keep-alive, but watches the Home
# Assistant port (8123). While someone is connected to a watched port, it keeps
# the Codespace active; after GRACE_MIN with no connections it stops resetting,
# and a hard CAP_MIN ceiling bounds the whole run.
set -uo pipefail

PORTS="${KEEPALIVE_PORTS:-8123}"
GRACE_MIN="${KEEPALIVE_GRACE_MIN:-10}"
CAP_MIN="${KEEPALIVE_CAP_MIN:-240}"

start=$(date +%s)
last_seen=$start
echo "[keepalive] watching ports: ${PORTS} (grace ${GRACE_MIN}m, cap ${CAP_MIN}m)"

has_conn() {
  if command -v ss >/dev/null 2>&1; then
    for p in ${PORTS//,/ }; do
      ss -Htan "sport = :${p}" 2>/dev/null | grep -q ESTAB && return 0
    done
    return 1
  fi
  # No ss available — fall back to "always active" (timer-bounded by CAP_MIN).
  return 0
}

while true; do
  now=$(date +%s)
  elapsed_min=$(( (now - start) / 60 ))
  if [ "$elapsed_min" -ge "$CAP_MIN" ]; then
    echo "[keepalive] hit cap ${CAP_MIN}m — exiting"
    exit 0
  fi
  if has_conn; then
    last_seen=$now
  else
    idle_min=$(( (now - last_seen) / 60 ))
    if [ "$idle_min" -ge "$GRACE_MIN" ]; then
      echo "[keepalive] idle ${idle_min}m (>= grace ${GRACE_MIN}m) — exiting"
      exit 0
    fi
  fi
  # Touch activity: a trivial write keeps the Codespace's idle timer from firing.
  : > /tmp/.cs460-keepalive
  sleep 60
done
