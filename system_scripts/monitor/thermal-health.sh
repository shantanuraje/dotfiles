#!/usr/bin/env bash
# thermal-health.sh — watch CPU temperature, notify on sustained threshold transitions.
#
# Reads from /sys/class/thermal/thermal_zone*/temp (millidegrees C). Picks the
# hottest zone. Requires that the temp stays above threshold for SUSTAIN_RUNS
# consecutive polls before notifying — avoids flapping on brief spikes.
#
# State transitions notified:
#   cool → hot        → notify hot
#   hot → critical    → notify critical
#   any → cool        → notify cool (only if previously hot/critical)
#
# Defaults: warn 85°C, critical 95°C, 3 consecutive runs to confirm.

set -euo pipefail

WARN_C="${THERMAL_WARN_C:-85}"
CRITICAL_C="${THERMAL_CRITICAL_C:-95}"
SUSTAIN_RUNS="${THERMAL_SUSTAIN_RUNS:-3}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOTIFY="${SCRIPT_DIR}/../notify/send-thermal.sh"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/thermal-health"
mkdir -p "$state_dir"
state_file="${state_dir}/state"
counter_file="${state_dir}/counter"

# Pick hottest available zone. Glob fallback if no zones (returns 0).
max_milli=0
for f in /sys/class/thermal/thermal_zone*/temp; do
    [[ -r "$f" ]] || continue
    v=$(cat "$f" 2>/dev/null || echo 0)
    (( v > max_milli )) && max_milli=$v
done
[[ "$max_milli" -eq 0 ]] && exit 0    # no thermal zones — nothing to monitor

temp_c=$(( max_milli / 1000 ))

if   (( temp_c >= CRITICAL_C )); then current="critical"
elif (( temp_c >= WARN_C     )); then current="hot"
else                                   current="cool"
fi

prev=$(cat "$state_file" 2>/dev/null || echo "cool")
counter=$(cat "$counter_file" 2>/dev/null || echo 0)

if [[ "$current" == "$prev" ]]; then
    counter=$(( counter + 1 ))
else
    counter=1
fi
echo "$counter" > "$counter_file"

# Only commit a transition once we've sustained it
if [[ "$current" != "$prev" ]] && (( counter >= SUSTAIN_RUNS )); then
    case "$current" in
        hot)      "$NOTIFY" hot      "$temp_c" || true ;;
        critical) "$NOTIFY" critical "$temp_c" || true ;;
        cool)     [[ "$prev" != "cool" ]] && "$NOTIFY" cool "$temp_c" || true ;;
    esac
    echo "$current" > "$state_file"
    echo 0 > "$counter_file"
fi
