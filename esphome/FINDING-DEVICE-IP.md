# Finding a device's IP (to add it in Home Assistant)

You add every ESPHome device to Home Assistant by **IP address** —
**Add Integration → ESPHome → `<IP>` : `6053`, encryption key blank**.

**Why by IP (not auto-discovery / `name.local`)?** HA runs in your Codespace and reaches
the devices across the class **Tailscale** network. mDNS/multicast (what powers
auto-discovery and `<name>.local`) **does not cross Tailscale**, so HA will never
"just find" the device and `<name>.local` won't resolve. You give it the IP.

## If the device has a screen (Cardputer)
Read the IP straight off the display — it shows `IP 192.168.8.x` once it joins Wi-Fi.

## If the device has NO screen (AtomS3, AtomS3 Lite, anything headless)
Use any of these — the first is the everyday method, the second is best for a class:

### 1. Router client list  ← primary, works for every device
ESPHome registers each device's **name as its DHCP hostname**. So on the GL-iNet admin
page (`http://192.168.8.1`) → **Clients**, the device appears by its name — e.g.
`atoms3-tmos`, `atoms3lite-tmos`, `cardputer-hall` — with its IP next to it. Read the IP
there. (Every device file sets a distinct `name:`, so each is easy to spot.)

### 2. Reserved IPs  ← recommended for the classroom
On the GL-iNet, **reserve a static IP per device by MAC** (DHCP reservations). Then each
device always has the same IP and you can hand students a simple sheet:

| Device name | MAC | Reserved IP |
|---|---|---|
| cardputer-env | …​ | 192.168.8.50 |
| atoms3lite-tmos | …​ | 192.168.8.51 |
| … | … | … |

No hunting, no screen needed, and the HA integration never breaks when a lease changes.

### 3. The flash log  ← works at flash time, no router access
Right after you flash over USB in the ESPHome dashboard, open **Logs** (serial). On boot
the log prints:
```
[wifi] WiFi Connected ... IP Address: 192.168.8.x
```
That's the device's IP. (This is also how you confirm Wi-Fi joined at all.)

### 4. AtomS3 Lite status LED  ← is it even online?
The Lite host lights its onboard RGB LED **green** once it has an IP (joined Wi-Fi) and
**blue** while it's still in the first-boot `<name>-Setup` AP. Green = go find its IP by
method 1–3; blue = finish Wi-Fi provisioning first (join the `<name>-Setup` hotspot and
enter the Wi-Fi credentials).

> First-boot Wi-Fi provisioning is the same on every device: if it can't join a known
> network it raises a **`<name>-Setup`** hotspot — join it from a phone/laptop and enter
> the lab Wi-Fi credentials in the browser. Then use a method above to get its IP.
