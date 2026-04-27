#!/usr/bin/env bash
# disk-health.sh — watch mountpoint usage, notify on threshold transitions.
#
# Polls `df` for configured mountpoints. Two thresholds (warn, critical).
# Tracks state per mountpoint so we only notify on transitions:
#   ok → warn          → notify warn
#   warn → critical    → notify critical
#   critical/warn → ok → notify recover
#
# Usage:
#   disk-health.sh                          # default mounts
#   disk-health.sh / /home /var/lib         # specific mounts
#
# Defaults: warn at 80%, critical at 90%.

set -euo pipefail

WARN_PCT="${DISK_WARN_PCT:-80}"
CRITICAL_PCT="${DISK_CRITICAL_PCT:-90}"

mounts=( "$@" )
[[ ${#mounts[@]} -eq 0 ]] && mounts=( / /home )

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOTIFY="${SCRIPT_DIR}/../notify/send-disk.sh"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/disk-health"
mkdir -p "$state_dir"

current_state_for() {
    local mnt="$1" pct="$2"
    if   (( pct >= CRITICAL_PCT )); then echo "critical"
    elif (( pct >= WARN_PCT     )); then echo "warn"
    else                                  echo "ok"
    fi
}

for mnt in "${mounts[@]}"; do
    [[ -d "$mnt" ]] || continue

    # df --output=pcent gives "  84%"; strip space and %
    pct=$(df --output=pcent "$mnt" 2>/dev/null | tail -1 | tr -d ' %' || echo 0)
    free_human=$(df -h --output=avail "$mnt" 2>/dev/null | tail -1 | tr -d ' ' || echo "?")
    [[ -z "$pct" ]] && continue

    current=$(current_state_for "$mnt" "$pct")
    state_file="${state_dir}/$(echo "$mnt" | tr '/' '_')"
    prev=$(cat "$state_file" 2>/dev/null || echo "ok")

    if [[ "$current" != "$prev" ]]; then
        case "$current" in
            warn)     "$NOTIFY" warn     "$mnt" "$pct" "$free_human" || true ;;
            critical) "$NOTIFY" critical "$mnt" "$pct" "$free_human" || true ;;
            ok)       [[ "$prev" != "ok" ]] && "$NOTIFY" recover "$mnt" "$pct" "$free_human" || true ;;
        esac
    fi

    echo "$current" > "$state_file"
done
