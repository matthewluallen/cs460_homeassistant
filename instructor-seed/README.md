# instructor-demo branch — pre-loaded Home Assistant fleet

This branch launches Home Assistant **already paired with the Module 5 tailscale device fleet**
(ESPHome nodes by IP + the Drone dashboard). `main` stays clean for students (empty HA).
**Never merge this branch into `main`.**

## What is committed (instructor-seed/storage/)
A sanitized snapshot of HA's `.storage`: config entries (devices by IP), device/entity/area
registries, the Lovelace dashboards (incl. the Drone dashboard), and Assist exposure.
**No secrets** — `auth`, `auth_provider.*`, `http.auth`, `person`, `onboarding`, and the
install `core.uuid` are excluded; a secret-guard in `scripts/snapshot-instructor.sh` enforces it.

## Launch it
Create a Codespace on the `instructor-demo` branch. On first boot `seed-instructor.sh` copies
the snapshot into a fresh HA, then HA starts. Do onboarding once (create a local owner — not an
Illinois login); the devices + Drone dashboard are already loaded. Power on the demo devices and
`tsup` so the ESPHome nodes come online.

## Re-capture after adding/changing devices
On this branch, with your live HA populated: `bash scripts/snapshot-instructor.sh`

## Note
Captured with **14 of 15** fleet devices — the AtomS3 ENV (.198) was powered off at capture time.
Add it when online (Add Integration -> ESPHome -> 192.168.8.198:6053, key blank), then re-run the
snapshot helper.
