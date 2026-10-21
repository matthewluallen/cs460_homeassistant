#!/usr/bin/env bash
# CS460 Module 5 — one-time setup at Codespace creation (onCreateCommand).
# Pre-pulls images and installs Tailscale so the first class start is fast.
set -uo pipefail
say(){ echo "=== [setup] $* ==="; }

say "START in $(pwd)"

# ss for the keep-alive's connection-gating.
say "apt: iproute2"
sudo apt-get update -y >/dev/null 2>&1 && sudo apt-get install -y iproute2 >/dev/null 2>&1 \
  || echo "apt step had warnings (continuing)"

# Pre-pull the Home Assistant image (the slow part) so it is cached in the prebuild.
say "pre-pull Home Assistant image"
docker pull ghcr.io/home-assistant/home-assistant:stable || echo "  !! HA pull warning"

# Pre-pull the sim broker too (used only with --profile sim).
say "pre-pull mosquitto (sim fallback)"
docker pull eclipse-mosquitto:2 || echo "  !! mosquitto pull warning"

# Install the Tailscale binary (student joins the class tailnet with 'tsup').
say "install Tailscale binary"
curl -fsSL https://tailscale.com/install.sh | sh || echo "  !! tailscale install warning"

say "DONE"
