#!/usr/bin/env bash
# Start a hardened keep-alive so the Codespace survives quiet gaps.
#   bash scripts/keep.sh            # grace 60m, cap 360m
#   bash scripts/keep.sh 90 360     # grace 90m, cap 360m
d="$(cd "$(dirname "$0")" && pwd)"
KEEPALIVE_GRACE_MIN="${1:-60}" KEEPALIVE_CAP_MIN="${2:-360}" nohup bash "$d/keepalive.sh" >/tmp/keepalive.log 2>&1 &
echo "keepalive started (grace ${1:-60}m cap ${2:-360}m) -> tail -f /tmp/keepalive.log"
