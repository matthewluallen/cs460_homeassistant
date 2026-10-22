#!/usr/bin/env bash
# instructor-demo branch ONLY. Pre-loads the saved HA fleet snapshot into a FRESH Home
# Assistant so launching this branch shows all demo devices + the Drone dashboard.
# Safe: it only seeds when config/.storage has no config entries yet (never overwrites a
# live instance). No secrets are in the snapshot - you create the HA owner login once via
# onboarding; the devices and dashboards are already there.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SEED="$ROOT/instructor-seed/storage"; DEST="$ROOT/config/.storage"
[ -d "$SEED" ] && [ -n "$(ls -A "$SEED" 2>/dev/null)" ] || { echo "seed-instructor: no snapshot yet - run scripts/snapshot-instructor.sh"; exit 0; }
if [ -f "$DEST/core.config_entries" ]; then echo "seed-instructor: HA already populated - skipping"; exit 0; fi
mkdir -p "$DEST"; cp -a "$SEED/." "$DEST/" && echo "seed-instructor: loaded instructor fleet snapshot ($(ls "$SEED" | wc -l) files)"
