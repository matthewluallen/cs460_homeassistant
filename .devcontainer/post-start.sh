#!/usr/bin/env bash
# CS460 Module 5 — runs at every Codespace start (postStartCommand).
# 1) Ensures the Tailscale daemon is up and installs the one-word 'tsup' helper.
# 2) Brings Home Assistant up via docker compose.
# We never run 'tailscale up' here — joining with the key is a manual, teachable
# step, and the key must never be baked in.
set -uo pipefail

# --- Tailscale daemon (same pattern as cs460_caldera) ----------------------
if command -v tailscaled >/dev/null 2>&1; then
  if ! pgrep -x tailscaled >/dev/null 2>&1; then
    echo "post-start: starting tailscaled"
    sudo mkdir -p /var/lib/tailscale
    if [ -c /dev/net/tun ]; then
      sudo nohup tailscaled --state=/var/lib/tailscale/tailscaled.state >/tmp/tailscaled.log 2>&1 &
    else
      sudo nohup tailscaled --tun=userspace-networking --state=/var/lib/tailscale/tailscaled.state >/tmp/tailscaled.log 2>&1 &
    fi
    sleep 2
  else
    echo "post-start: tailscaled already running"
  fi
fi

# One-word join: 'tsup' expands to the full 'tailscale up' with the Codespaces
# secret. It references the env var only — the key value is never written here.
BRC="${HOME}/.bashrc"
if ! grep -q 'cs460-tsup' "${BRC}" 2>/dev/null; then
  cat >> "${BRC}" <<'RC'

# cs460-tsup : join the class tailnet in one word  ->  tsup
tsup() { sudo tailscale up --authkey "$OTSIM_TAILSCALE_AUTHKEY" --accept-routes "$@"; }
RC
  echo "post-start: installed 'tsup' helper in ~/.bashrc"
fi

# --- Home Assistant --------------------------------------------------------
echo "post-start: starting Home Assistant (docker compose up -d homeassistant)"
docker compose up -d homeassistant || echo "post-start: compose up warning"

echo "post-start: done — open the forwarded port 8123; join the tailnet with 'tsup'"
