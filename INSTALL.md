# Creating the `cs460_homeassistant` repo (instructor, one-time)

This session can't create a GitHub repo for you (it's scoped to the existing course repos), so create
it once by hand. Everything below is drop-in — same pattern as `cs460_caldera`.

## 1. Create the repo + add these files
1. Create a new repo under your account, e.g. **`matthewluallen/cs460_homeassistant`** (private or public).
2. Add the contents of this folder to the repo root. Fastest paths:
   - **Upload:** GitHub → *Add file → Upload files* → drag the whole tree → commit to `main`.
   - **Or git:**
     ```
     git init && git add . && git commit -m "CS460 Module 5: pre-built Home Assistant Codespace"
     git branch -M main
     git remote add origin https://github.com/matthewluallen/cs460_homeassistant.git
     git push -u origin main
     ```
   Keep the paths exactly as-is (`.devcontainer/`, `.vscode/`, `scripts/`, `config/`, `sim/`).
3. Make the shell scripts executable if git didn't keep the bit:
   `git update-index --chmod=+x .devcontainer/setup.sh .devcontainer/post-start.sh scripts/keepalive.sh sim/publish-sim-device.sh`

## 2. Tailscale secret (same as the other repos)
Add the Codespaces secret **`OTSIM_TAILSCALE_AUTHKEY`** (Settings → Secrets and variables → Codespaces)
and **grant it to `cs460_homeassistant`**. Use the current reusable class key. The lab never prints the
key — `tsup` reads it from the environment.

## 3. Prebuild (so students start fast)
Repo → Settings → Codespaces → **Set up prebuild**: branch `main`, config
`.devcontainer/devcontainer.json`, regions **US East + US West**, trigger on every push. The prebuild
runs `setup.sh`, which pre-pulls the Home Assistant image (the slow part) and installs Tailscale.

## 4. Smoke-test it yourself before class
1. Create a Codespace on the repo. Click **Trust folder** + **Allow automatic tasks** if prompted.
2. Port **8123** should auto-forward; open it → Home Assistant onboarding. Create a throwaway account.
   - This confirms the **reverse-proxy fix** works (validated here: onboarding + login succeed behind the
     github.dev proxy because of `http.trusted_proxies` in `config/configuration.yaml`).
3. `tsup` → `tailscale status` → confirm your device/router shows up.
4. **With hardware:** Add Integration → ESPHome → device's **tailnet IP : 6053**.
   **Without hardware:** `docker compose --profile sim up -d`, then Add Integration → MQTT → `127.0.0.1:1883`.

---

## What was validated in advance (so you're not debugging in class)
Run live against `ghcr.io/home-assistant/home-assistant:stable` (HA 2026.10.1), the same engine Codespaces uses:

- ✅ HA boots and serves; onboarding + token exchange complete.
- ✅ **Reverse-proxy gotcha cleared** — onboarding and login succeed with simulated github.dev
  `X-Forwarded-For/Proto/Host` headers, thanks to the `trusted_proxies` block. (Without it HA returns
  "400: Bad Request" on login.)
- ✅ **Device ingestion** — HA picks up a networked device and shows live entities (validated via the
  bundled MQTT sim: IAQ / temperature / humidity updating every 5 s).
- ✅ **ESPHome integration is addable by IP** (the manual path you use over Tailscale).
- ✅ `docker compose config` + all JSON/YAML valid.

## Known limitation (by design — it's the lab's teaching point)
**mDNS / zeroconf auto-discovery will NOT work over Tailscale**, even with a subnet router or an mDNS
reflector — Tailscale carries no multicast between peers. Add the device **by its tailnet IP** (ESPHome
`:6053`) or via **MQTT**. Confirmed against Tailscale docs.

## Still needs YOUR hardware to fully confirm (can't be done from here)
- The live tailnet hop HA ↔ real ESP32 over your travel router, and the ESPHome native API (`:6053`)
  specifically over the tailnet. The add-by-IP path is confirmed available; only the physical device
  leg is unverified. The MQTT sim is your backstop if the hardware misbehaves.
