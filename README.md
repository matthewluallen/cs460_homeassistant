# CS460 Module 5 — Home Assistant (IoT / Hardware Security)

A pre-built **Home Assistant** Codespace for the Module 5 in-person lab. Students open the
Codespace, Home Assistant starts automatically, they join the class tailnet, and they add an
**ESPHome device** — an **M5Stack Cardputer (ESP32-S3) + ENV Pro (BME688)** — **by its tailnet IP**,
then explore its entities. Students can also **flash the Cardputer themselves** from the browser
(see `FLASH.md`).

This mirrors `cs460_caldera`: pre-built, Tailscale baked in, a keep-alive so it survives class, and
a repo prebuild so it starts fast.

---

## Quick start (in class)

1. **Create a Codespace** on this repo (Code → Codespaces → Create). The dev container pre-pulls
   Home Assistant and starts it automatically (~1–2 min first time).
   - If VS Code prompts, click **Trust folder** and **Allow automatic tasks**.
2. In the **Ports** tab, open the forwarded **8123** URL → the Home Assistant onboarding page.
   Create a local account (this is a throwaway lab instance).
3. **Join the class tailnet** in a terminal:
   ```
   tsup
   tailscale status
   ```
   You should see your Codespace and the instructor's **device/router** listed. **Note the device's
   100.x tailnet IP.**
4. **Add the device** (it will *not* auto-discover over Tailscale — see below):
   Settings → **Devices & Services** → **Add Integration** → **ESPHome** →
   **Host = the device's tailnet IP**, **Port = 6053** (+ API encryption key if set) → Submit.
5. Open the new device → watch its **entities** (IAQ, temperature, humidity, …) update live.

---

## Why you add the device by IP (the lab's point)

Home Assistant normally *auto-discovers* local devices with **mDNS/zeroconf**. mDNS is **link-local
multicast**, and **Tailscale does not carry multicast/broadcast between peers** — not even through a
subnet router (those forward *unicast* only). So across the tailnet the device is **reachable by IP
but not discoverable**. This is the core IoT-security lesson and it ties straight back to the Module 4
Tailscale work: discovery is LAN-scoped; **remote/OT access requires explicit addressing over an
overlay.** You reach the device over Tailscale with its native API (ESPHome `:6053`) or via MQTT.

---

## No hardware? Simulated-device fallback

To test the Codespace, or as a backup demo if the physical ESP32/router misbehaves, start a software
device (an ESPHome-style BME680 published over MQTT):

```
docker compose --profile sim up -d
```

Then in Home Assistant: **Add Integration → MQTT**, broker **127.0.0.1**, port **1883** (no auth). A
device **"CS460 ESPHome Air Sensor (SIM)"** appears with IAQ / temperature / humidity entities that
update every 5 seconds. (MQTT needs no discovery, which is why it works over the tailnet too.)

---

## Optional: flash the Cardputer yourself (browser)

Flash an **M5Stack Cardputer + ENV Pro (BME688)** from Chrome via the ESPHome dashboard running in the
Codespace — full steps and the WebSerial constraint are in **`FLASH.md`**.

```
docker compose --profile flash up -d   # ESPHome dashboard on :6052 (open in Chrome)
```

## Optional: talk to your devices with an LLM

Home Assistant's **Assist** chat (browser) can be backed by a conversation agent — either a **local
model** on the Codespace, or **your own chat.illinois.edu chatbot** (each student uses their own Illinois
login + key). Full steps, including the campus-hub adapter and secret handling, are in **`LLM.md`**.

```
docker compose --profile llm up -d   # local model (Ollama)
docker compose --profile hub up -d   # campus LLM hub (chat.illinois.edu) via adapter
```

## What's in here

```
.devcontainer/devcontainer.json   HA Codespace (docker-in-docker, NET_ADMIN+tun, forward 8123)
.devcontainer/setup.sh            onCreate: pre-pull images, install Tailscale
.devcontainer/post-start.sh       start tailscaled + 'tsup' helper + bring HA up
docker-compose.yml                homeassistant service (+ optional 'sim' profile)
config/configuration.yaml         default_config + http.trusted_proxies (Codespaces proxy fix)
scripts/keepalive.sh              connection-gated keep-alive on port 8123
.vscode/tasks.json|settings.json  run the keep-alive on folder open
sim/                              no-hardware MQTT device fallback
hub-adapter/                      Ollama->chat.illinois.edu shim (profile: hub) — see LLM.md
esphome/cardputer-env.yaml        Cardputer + BME688 firmware config (flash via ESPHome dashboard)
LLM.md                            local model (Ollama) + campus hub (student login) walkthrough
FLASH.md                          flash the Cardputer from Chrome (WebSerial) via the Codespace
```

## Troubleshooting

- **Login shows "400: Bad Request".** The `http.trusted_proxies` block in `config/configuration.yaml`
  handles the github.dev forwarded-port proxy. If you still hit it, confirm that block is present and
  restart HA: `docker compose restart homeassistant`.
- **Device never appears / won't connect.** You must `tsup` first and use the device's **tailnet** IP,
  not a LAN IP. Check `tailscale status` shows the device. If `tsup` errors, the auth key is likely
  expired — regenerate a reusable key, update the `OTSIM_TAILSCALE_AUTHKEY` Codespaces secret, and
  restart the Codespace (secrets apply at start).
- **HA didn't start.** `docker compose up -d homeassistant` then `docker compose logs -f homeassistant`.
