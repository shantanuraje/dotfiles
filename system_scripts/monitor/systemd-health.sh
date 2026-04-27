#!/usr/bin/env bash
# systemd-health.sh — monitor systemd unit health, publish transitions to ntfy.
#
# Detects:
#   - Newly failed units (transition: healthy → failed)
#   - Recovered units (failed → active)
#   - Restart loops (NRestarts ≥ threshold, throttled per unit)
#
# Usage:
#   systemd-health.sh --scope system    # run as root, monitors system units
#   systemd-health.sh --scope user      # run as user, monitors user units
#
# State is kept per-scope so the two scopes don't trample each other:
#   system → /var/lib/systemd-health/state-system
#   user   → ~/.local/state/systemd-health/state-user
#
# Designed to be invoked by a 5-minute systemd timer.

set -euo pipefail

# ── Args ──────────────────────────────────────────────────────────────────────
scope=""
while (( $# )); do
    case "$1" in
        --scope) scope="$2"; shift 2 ;;
        *) echo "unknown flag: $1" >&2; exit 2 ;;
    esac
done
[[ "$scope" == "system" || "$scope" == "user" ]] \
    || { echo "must pass --scope system|user" >&2; exit 2; }

# ── Paths ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOTIFY="${SCRIPT_DIR}/../notify/send-systemd.sh"
[[ -x "$NOTIFY" ]] || { echo "missing $NOTIFY" >&2; exit 1; }

# State always lives under user XDG dir — the timer runs as user for both
# scopes (reading systemd state needs no privilege). System vs user scope is
# distinguished by the systemctl invocation and the state file suffix.
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/systemd-health/${scope}"
if [[ "$scope" == "system" ]]; then
    SYSTEMCTL=( systemctl )
else
    SYSTEMCTL=( systemctl --user )
fi
mkdir -p "$state_dir"
failed_state="${state_dir}/failed"
restart_state="${state_dir}/restart-counts"
touch "$failed_state" "$restart_state"

# ── Restart-loop threshold ────────────────────────────────────────────────────
RESTART_THRESHOLD=3

# ── Detect currently-failed units ─────────────────────────────────────────────
# `systemctl list-units --failed` output has a header + footer; --plain --no-legend
# strips both. First column is unit name.
current_failed=$(
    "${SYSTEMCTL[@]}" list-units --failed --plain --no-legend --all \
        2>/dev/null | awk 'NF{print $1}' | sort -u
)
prev_failed=$(sort -u "$failed_state" 2>/dev/null || true)

# Newly failed = in current but not previous
while IFS= read -r unit; do
    [[ -z "$unit" ]] && continue
    "$NOTIFY" failed "$unit" "$scope" || true
done < <(comm -23 <(echo "$current_failed") <(echo "$prev_failed"))

# Recovered = in previous but not current AND now active
while IFS= read -r unit; do
    [[ -z "$unit" ]] && continue
    state=$("${SYSTEMCTL[@]}" is-active "$unit" 2>/dev/null || true)
    if [[ "$state" == "active" ]]; then
        "$NOTIFY" recovered "$unit" "$scope" || true
    fi
done < <(comm -13 <(echo "$current_failed") <(echo "$prev_failed"))

# Persist current set
echo "$current_failed" > "$failed_state"

# ── Restart-loop detection ────────────────────────────────────────────────────
# Walk active services, compare NRestarts to last-known. If >= threshold AND
# higher than last reported, fire once.
declare -A last_restarts
if [[ -s "$restart_state" ]]; then
    while IFS='=' read -r u n; do
        [[ -n "$u" ]] && last_restarts["$u"]=$n
    done < "$restart_state"
fi

> "${restart_state}.new"
while IFS= read -r unit; do
    [[ -z "$unit" ]] && continue
    nr=$("${SYSTEMCTL[@]}" show -p NRestarts --value "$unit" 2>/dev/null || echo 0)
    [[ -z "$nr" ]] && nr=0
    echo "${unit}=${nr}" >> "${restart_state}.new"
    if (( nr >= RESTART_THRESHOLD )); then
        prev="${last_restarts[$unit]:-0}"
        if (( nr > prev )); then
            "$NOTIFY" restart-loop "$unit" "$scope" "$nr" || true
        fi
    fi
done < <("${SYSTEMCTL[@]}" list-units --type=service --state=active,activating \
                          --plain --no-legend 2>/dev/null \
            | awk 'NF{print $1}')
mv "${restart_state}.new" "$restart_state"
