#!/bin/sh
# CS460 Module 5 — no-hardware fallback "device".
# Publishes an ESPHome-style BME680 air-quality sensor over MQTT discovery, then
# updates its readings every few seconds so Home Assistant shows a live device.
# Used only with `docker compose --profile sim up -d`. Not a replacement for the
# real ESP32 demo — a backup for testing the Codespace or if hardware misbehaves.
set -u
BROKER="${MQTT_BROKER:-127.0.0.1}"
DEV="cs460air"
DISCO="homeassistant/sensor/${DEV}"
DEVICE_JSON='"device":{"identifiers":["cs460air"],"name":"CS460 ESPHome Air Sensor (SIM)","manufacturer":"ESPHome","model":"BME680"}'

echo "sim-device: waiting for broker ${BROKER}:1883..."
until mosquitto_pub -h "$BROKER" -t "${DISCO}/iaq/config" -m '{}' 2>/dev/null; do sleep 2; done

# --- retained discovery configs: one entity per BME680 reading --------------
mosquitto_pub -h "$BROKER" -r -t "${DISCO}/iaq/config" -m \
  "{\"name\":\"IAQ\",\"state_topic\":\"${DISCO}/state\",\"value_template\":\"{{ value_json.iaq }}\",\"unit_of_measurement\":\"IAQ\",\"unique_id\":\"${DEV}_iaq\",${DEVICE_JSON}}"
mosquitto_pub -h "$BROKER" -r -t "${DISCO}/temp/config" -m \
  "{\"name\":\"Temperature\",\"device_class\":\"temperature\",\"state_topic\":\"${DISCO}/state\",\"value_template\":\"{{ value_json.temp }}\",\"unit_of_measurement\":\"°C\",\"unique_id\":\"${DEV}_temp\",${DEVICE_JSON}}"
mosquitto_pub -h "$BROKER" -r -t "${DISCO}/humidity/config" -m \
  "{\"name\":\"Humidity\",\"device_class\":\"humidity\",\"state_topic\":\"${DISCO}/state\",\"value_template\":\"{{ value_json.humidity }}\",\"unit_of_measurement\":\"%\",\"unique_id\":\"${DEV}_hum\",${DEVICE_JSON}}"

echo "sim-device: publishing live readings every 5s"
while true; do
  IAQ=$(awk 'BEGIN{srand();print 40+int(rand()*120)}')
  TEMP=$(awk 'BEGIN{srand();print 20+int(rand()*8)}')
  HUM=$(awk 'BEGIN{srand();print 35+int(rand()*30)}')
  mosquitto_pub -h "$BROKER" -r -t "${DISCO}/state" \
    -m "{\"iaq\":${IAQ},\"temp\":${TEMP},\"humidity\":${HUM}}"
  sleep 5
done
