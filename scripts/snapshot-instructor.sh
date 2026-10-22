#!/usr/bin/env bash
# Capture the CURRENT Home Assistant fleet state into instructor-seed/ and push it on the
# instructor-demo branch, so `instructor-demo` launches pre-loaded with the demo devices.
# EXCLUDES every auth/secret file (auth, auth_provider.*, http.auth, person, onboarding, uuid).
# Run from the repo root ON the instructor-demo branch.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"
[ "$(git branch --show-current)" = "instructor-demo" ] || { echo "Checkout instructor-demo first."; exit 1; }
SRC=config/.storage; DST=instructor-seed/storage
mkdir -p "$DST"; rm -f "$DST"/* 2>/dev/null
cp "$SRC"/{core.config_entries,core.device_registry,core.entity_registry,core.area_registry,homeassistant.exposed_entities,lovelace,lovelace_dashboards,lovelace.dashboard-drone,lovelace.map} "$DST"/ 2>/dev/null
cp "$SRC"/esphome.* "$DST"/ 2>/dev/null
if grep -rlEa '"(noise_psk|password|access_token|refresh_token|api_key|private_key)": *"[^"]' "$DST"/; then
  echo "ABORT: a credential value was found in the snapshot - not committing."; exit 2
fi
N=$(ls "$DST" | wc -l); echo "Snapshot: $N files (no secrets)."
git add instructor-seed/storage
git commit -m "instructor-demo: snapshot HA fleet state ($N storage files, no secrets)" -m "Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
git push -u origin instructor-demo && echo "Pushed instructor-demo."
