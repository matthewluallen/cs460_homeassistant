# Flashing the Cardputer from the browser (Module 5)

Each student can flash their own **M5Stack Cardputer (ESP32-S3) + ENV Pro (BME688)** using the ESPHome
dashboard running in the Codespace and **Chrome WebSerial** — no local toolchain install.

## The one thing to understand first
Flashing over **WebSerial talks from your browser to the USB port on the laptop the Cardputer is plugged
into.** The Codespace **builds** the firmware and **serves** the dashboard (over its forwarded HTTPS port,
which satisfies WebSerial's secure-context requirement), but the Codespace **cannot see the USB device** —
the serial write always happens in your own Chrome, to your own machine's USB. So:

- Plug the Cardputer into **your laptop**, and do the flashing step in **Chrome or Edge** (WebSerial isn't
  in Firefox/Safari).
- Some Cardputers need a **USB-serial driver** (CH9102 / CP210x) on the laptop.
- First flash is over **USB**; after that, ESPHome pushes updates **OTA over the tailnet**.

## Steps
1. Start the dashboard:
   ```
   docker compose --profile flash up -d
   ```
   Open the forwarded **6052** port (Ports tab) in **Chrome**.
2. In `esphome/`, copy `secrets.yaml.example` to `secrets.yaml` and fill in Wi-Fi + an API encryption key
   (the dashboard can generate the key). `secrets.yaml` is gitignored.
3. Open **`cardputer-env.yaml`** in the dashboard. Confirm the **I2C pins** for the Grove port you're
   using (commonly SDA=GPIO2, SCL=GPIO1) and the BME688 address (`0x77`, some units `0x76`).
4. Click **Install → Plug into this computer**. Chrome prompts for the serial port → pick the Cardputer →
   it compiles (in the Codespace) and flashes (via your browser). ~a few minutes the first time.
5. **Provision Wi-Fi (captive portal):** if the Cardputer can't join a known network it raises a
   **"Cardputer-Setup"** hotspot — join it from a phone/laptop and enter the Wi-Fi credentials in the browser.
   (No keyboard driver needed.)
6. The Cardputer **screen shows its IP address** once it's on Wi-Fi (plus live temp/humidity/IAQ). In Home
   Assistant: **Add Integration → ESPHome → host = that IP : 6053** (+ the API encryption key). Entities
   appear — and now you can compare the value **on the Cardputer screen** with the value **in HA**.

## Confirmed working settings (validated on real hardware, Cardputer + ENV Pro)
- Display: `model: TTGO TDisplay 135x240` + `rotation: 90` (the panel is the same ST7789V2 as a T-Display).
- Sensor: BME688 at **I2C 0x76**, Grove pins **SDA=GPIO2, SCL=GPIO1** (M5 Grove: Yellow=G2=SDA, White=G1=SCL).
- The screen shows the IP and live Temp/Humidity/IAQ once it's on Wi-Fi.

## Flashing a batch (esphome on the Mac, no WebSerial needed)
`cd ~/cardputer-lab && ./flash-cardputer.sh` per device (plug in → run → next). A **brand-new Cardputer flashes
cleanly** (auto-reset works on first flash). If a board ever refuses with *"No serial data received"* (happens
after its firmware is already running the USB port), **unplug/replug it**, or hold the **BOOT/G0 button** while
it connects — then re-run.

## If WebSerial won't connect
- Make sure the page is the **HTTPS forwarded URL** (not http), and you're in **Chrome/Edge**.
- Close other programs holding the serial port (Arduino IDE, screen, another tab).
- Driver missing → install CH9102/CP210x, replug.
- Fallback: in the dashboard use **Install → Manual download**, get the `.bin`, and flash with
  **https://web.esphome.io** (also Chrome WebSerial) or `esphome-flasher`.

## Validated here
The ESPHome dashboard container (`ghcr.io/esphome/esphome`, v2026.9.1) runs in the Codespace and serves
its web UI on port 6052. The WebSerial flash itself requires the physical Cardputer on a student's
laptop, so it's verified in class, not from the cloud — the constraints above are what make it work.
