#!/usr/bin/env bash
# CS460 Module 5 — runs at every Codespace start (postStartCommand).
# 1) Ensures the Tailscale daemon is up and installs the one-word 'tsup' helper.
# 2) AUTO-JOINS the class tailnet (so a restart never drops you to "Logged out").
# 3) Brings Home Assistant up via docker compose.
# The auth key is read from the Codespaces secret env var only — it is never
# written into this file or the repo.
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

# One-word manual (re)join helper: 'tsup' expands to the full 'tailscale up'
# with the Codespaces secret. References the env var only — the key value is
# never written here. Kept as a fallback for the auto-join below.
BRC="${HOME}/.bashrc"
if ! grep -q 'cs460-tsup' "${BRC}" 2>/dev/null; then
  cat >> "${BRC}" <<'RC'

# cs460-tsup : join the class tailnet in one word  ->  tsup
tsup() { sudo tailscale up --authkey "$OTSIM_TAILSCALE_AUTHKEY" --accept-routes "$@"; }
RC
  echo "post-start: installed 'tsup' helper in ~/.bashrc"
fi

# --- Auto-join the class tailnet -------------------------------------------
# Runs on EVERY start so a stop/restart reconnects automatically (no more
# "Logged out"). Re-running 'tailscale up' is idempotent. Students who have
# not set their own OTSIM_TAILSCALE_AUTHKEY secret get a notice and can join
# manually with 'tsup' once the secret is in place. The key is read from the
# environment only and is never baked into the repo.
if [ -n "${OTSIM_TAILSCALE_AUTHKEY:-}" ]; then
  echo "post-start: joining class tailnet (tailscale up --accept-routes)"
  if sudo tailscale up --authkey "${OTSIM_TAILSCALE_AUTHKEY}" --accept-routes; then
    echo "post-start: tailnet joined"
  else
    echo "post-start: tailnet auto-join failed — run 'tsup' manually once your secret is set"
  fi
else
  echo "post-start: OTSIM_TAILSCALE_AUTHKEY not set — add it as a Codespaces secret for THIS repo, then run 'tsup' (or restart the Codespace)"
fi

# --- Home Assistant --------------------------------------------------------
echo "post-start: starting Home Assistant (docker compose up -d homeassistant)"
docker compose up -d homeassistant || echo "post-start: compose up warning"

echo "post-start: done — the tailnet auto-joins; open the forwarded port 8123. (Manual re-join: 'tsup'.)"
