#!/usr/bin/env bash
# send-thermal.sh — CPU temperature notifications.
#
# Usage:
#   send-thermal.sh hot      <temp-c>   # crossed warn threshold
#   send-thermal.sh critical <temp-c>   # at throttle threshold
#   send-thermal.sh cool     <temp-c>   # back below warn threshold

set -euo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${LIB_DIR}/lib.sh"

action="${1:?need action: hot | critical | cool}"
temp="${2:?need temp °C}"
host="$(hostname)"

case "$action" in
    hot)
        notify::warn temp "🌡️ CPU running hot" \
            "**${host}** CPU at **${temp}°C** — sustained over warn threshold." \
            -t warning,fire -m
        ;;
    critical)
        notify::alert temp "🔥 CPU thermal critical" \
            "**${host}** CPU at **${temp}°C** — likely throttling. Check airflow / load." \
            -t rotating_light,fire -m
        ;;
    cool)
        notify::ok temp "✓ CPU cooled down" \
            "**${host}** CPU back to normal (${temp}°C)." \
            -t white_check_mark,snowflake -m
        ;;
    *) echo "send-thermal.sh: unknown action: $action" >&2; exit 2 ;;
esac
