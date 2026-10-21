#!/usr/bin/env bash
# Is a device reachable on the ESPHome API port?  ->  bash scripts/dev.sh 192.168.8.132
ip="$1"; [ -z "$ip" ] && { echo "usage: bash scripts/dev.sh <device-ip>"; exit 1; }
timeout 5 bash -c "echo > /dev/tcp/$ip/6053" 2>/dev/null && echo "$ip UP" || echo "$ip DOWN"
