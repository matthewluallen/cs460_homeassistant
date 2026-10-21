#!/usr/bin/env bash
# Is Home Assistant up?  ->  bash scripts/up.sh
docker compose ps --format '{{.Service}} {{.Status}}' 2>/dev/null | grep -Ei 'homeassistant|hub-adapter|ollama'
printf 'HA HTTP: '; curl -s -o /dev/null -w '%{http_code}\n' http://localhost:8123/
