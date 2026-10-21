# CS460 Module 5 — one modular ESPHome firmware for many M5 boards + sensors

All hardware is M5Stack. Instead of a separate hand-written firmware per board, this
is **one package tree** you compose per device:

```
esphome/
  common/base.yaml        Wi-Fi + captive portal, API (no key), OTA, logging, IP sensor,
                          and a generic on-screen status line (disp_line)
  hosts/<board>.yaml      board + display + the port-pin substitutions for that host
  sensors/<module>.yaml   one sensor, written against the host's pin substitutions
  <device>.yaml           top-level: substitutions (name) + 3 package includes
```

A device file is ~6 lines. To put a module on a board, pick a host include and a sensor
include:

```yaml
substitutions: { name: cardputer-hall, friendly_name: "Cardputer Hall" }
esphome: { name: ${name}, friendly_name: ${friendly_name} }
packages:
  base:   !include common/base.yaml
  host:   !include hosts/cardputer.yaml
  sensor: !include sensors/hall-a3144e.yaml
```

**One sensor per device** (each board carries one module), so the shared port pins never
collide. Flash from the ESPHome dashboard (port 6052) → Install → "Plug into this computer"
(Chrome/Edge WebSerial). The screen shows the IP; add it in Home Assistant via
**Add Integration → ESPHome → `<IP>`:6053, key blank**. After the first USB flash, updates
go OTA over the tailnet.

## Hosts

| Host | ESPHome board | Grove port pins | Screen |
|---|---|---|---|
| **Cardputer** | esp32-s3-devkitc-1 | white=G1=GPIO1, yellow=G2=GPIO2 | ST7789V2 240×135 (shows IP + reading) |
| **AtomS3 / Lite** | esp32-s3-devkitc-1 | white=G1=GPIO1, yellow=G2=GPIO2 | none in ESPHome (GC9107 unsupported) — read in HA |
| **CamS3** | — | **no free sensor port** (Grove is USB D+/D− only) | camera device, not a sensor host |

PORT.A I²C convention on these ports: **SDA = yellow (GPIO2), SCL = white (GPIO1)**.

## Sensors

| Module | Chip | Bus / wire | ESPHome | Package | Status |
|---|---|---|---|---|---|
| ENV Pro | BME688 | I²C 0x77 | `bme68x_bsec2` (official) | `sensors/env-bme688.yaml` | ✅ validated on HW |
| TMOS PIR | STHS34PF80 | I²C 0x5A | M5 external `sths34pf80` | `sensors/tmos-pir.yaml` | ✅ (needs ESPHome ≥ 2026.2.2) |
| DLight | BH1750 | I²C 0x23 | native `bh1750` | `sensors/dlight-bh1750.yaml` | ✅ |
| Hall | A3144E | digital, white | native `gpio` (active-low) | `sensors/hall-a3144e.yaml` | ✅ |
| Reflective IR | LM393 | digital=yellow, analog=white | native `gpio` + `adc` | `sensors/reflective-ir.yaml` | ✅ |
| GPS | AT6558 (BDS+GPS) | UART 9600, white=unit TX | native `gps` | `sensors/gps.yaml` | ✅ |
| **ToF4M** | **VL53L1X** | I²C 0x29 | ❌ not native (ESPHome does VL53L0X, a different chip); M5's ESPHome ToF is also VL53L0X-only | — | ⚠ pending component |
| **Ultrasonic I²C** | **RCWL-9620** | I²C 0x57 | ❌ native `ultrasonic` is trigger/echo only, not I²C | — | ⚠ needs custom component |
| **Thermal** | **MLX90640** | I²C 0x33 | ❌ no maintained component; 32×24 frame read/render impractical on-device | — | ⚠ custom (best case min/max/avg) |

### About the three flagged sensors — and M5's own driver code to build from
No honest *native* ESPHome path today, but M5 publishes reference drivers we can port into a
custom ESPHome I²C component. Each component would live in `esphome/components/<name>/` and be
pulled with `external_components: - source: components:`.

- **Ultrasonic — RCWL-9620 @ 0x57 — SMALLEST LIFT.** M5 Arduino lib:
  https://github.com/m5stack/M5Unit-Sonic . Protocol is tiny: write the trigger command, wait
  ~50 ms, read 3 bytes of distance (µm → ÷1000 for mm; 2–450 cm range). A ~60-line custom
  `PollingComponent` + `sensor` is very doable. (Register details: the `.ino` examples + the
  RCWL-9620 datasheet.) **Recommended first custom component.**
- **ToF4M — VL53L1X (VL53L1CXV0FY) @ 0x29.** M5's own driver is MicroPython:
  https://github.com/m5stack/uiflow-micropython → `examples/unit/tof4m/` (method `get_distance`
  → mm, check `get_data_ready`). No M5 Arduino driver; the usual Arduino basis is ST's VL53L1X
  ULD or the Pololu `VL53L1X` library — port either into an ESPHome component.
- **Thermal — CHECK WHICH UNIT YOU HAVE, it changes everything:**
  - **Unit Thermal2 (U135)** has an **onboard ESP32-PICO-D4** that processes the MLX90640 and
    exposes **min / max / average temps + hi/lo alarms** over I²C @ 0x33 — so a custom component
    reads a few processed registers, *not* 768 raw floats. **Feasible and genuinely useful.**
    M5 Arduino lib: https://github.com/m5stack/M5Unit-Thermal2 (+ its "I²C Protocol" PDF).
  - **Unit Thermal (U016/U062)** is the **raw MLX90640** — no onboard MCU, 32×24 frame reads;
    impractical in ESPHome (better handled by a CamS3/Pi). Only min/max/avg via a heavy custom
    component at best.

**Suggested order if you want these built:** Ultrasonic (smallest) → Thermal2 *if that's the unit
you have* (high value, processed data) → ToF4M (VL53L1X port). Tell me which thermal unit it is and
I'll start on the ultrasonic component.

### Security / teaching hooks (ties into the Module 5 LLM lab)
- **Hall + Reflective IR + TMOS** give you real **binary/presence** entities → motion-triggered
  automations, and the sharper LLM angle: an Assist agent with *control* tools acting on physical
  presence (OWASP LLM06 Excessive Agency; a motion event as untrusted trigger input = LLM01).
- **GPS** adds a location entity → a nice **sensitive-data-disclosure** talking point (what leaves
  the device, and to whom, once an LLM/hub can read it — OWASP LLM02).
