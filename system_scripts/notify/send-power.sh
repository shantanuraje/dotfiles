#!/usr/bin/env bash
# send-power.sh — publish battery / AC notifications.
#
# Usage:
#   send-power.sh low       <capacity%>
#   send-power.sh critical  <capacity%>
#   send-power.sh charging  <capacity%>
#   send-power.sh full      <capacity%>
#   send-power.sh unplugged <capacity%>

set -euo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${LIB_DIR}/lib.sh"

action="${1:?need action: low | critical | charging | full | unplugged}"
cap="${2:-?}"
host="$(hostname)"

case "$action" in
    critical)
        notify::alert power \
            "🔋 Battery critical" \
            "**${host}** at ${cap}% — **plug in now** to avoid shutdown." \
            -t rotating_light,battery \
            -m
        ;;
    low)
        notify::warn power \
            "🪫 Battery low" \
            "**${host}** at ${cap}% — consider charging soon." \
            -t warning,battery \
            -m
        ;;
    charging)
        notify::info power \
            "⚡ Charging" \
            "**${host}** plugged in at ${cap}%." \
            -t electric_plug,battery \
            -m
        ;;
    full)
        notify::ok power \
            "🔌 Battery full" \
            "**${host}** fully charged (${cap}%) — safe to unplug." \
            -t white_check_mark,battery \
            -m
        ;;
    unplugged)
        notify::info power \
            "🔌 Unplugged" \
            "**${host}** running on battery at ${cap}%." \
            -t electric_plug,battery \
            -m
        ;;
    *)
        echo "send-power.sh: unknown action: $action" >&2
        exit 2
        ;;
esac
