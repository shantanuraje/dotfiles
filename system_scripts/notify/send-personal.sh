#!/usr/bin/env bash
# send-personal.sh — personal nudges (hydration, posture, breaks, pomodoro).
#
# Usage:
#   send-personal.sh hydration
#   send-personal.sh posture
#   send-personal.sh stretch
#   send-personal.sh pomo-start    <session-name>
#   send-personal.sh pomo-end      <session-name>
#   send-personal.sh pomo-break    <session-name>

set -euo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${LIB_DIR}/lib.sh"

action="${1:?need action}"
extra="${2:-}"

case "$action" in
    hydration)
        notify::send personal-hydration "💧 Sip water" \
            "Quick hydration check. Take a few sips." \
            -p min -t droplet
        ;;
    posture)
        notify::send personal-hydration "🧍 Posture check" \
            "Roll shoulders back. Sit up straight. Adjust monitor height if needed." \
            -p min -t bowing_man
        ;;
    stretch)
        notify::send personal-hydration "🧘 Stretch" \
            "Stand up. Stretch shoulders, neck, wrists. 60 seconds." \
            -p min -t person_in_lotus_position
        ;;
    pomo-start)
        notify::send personal-pomodoro "🍅 Pomodoro started" \
            "**${extra:-Focus session}** — 25 min. Phone face-down. One task." \
            -p low -t tomato -m
        ;;
    pomo-end)
        notify::send personal-pomodoro "🍅 Pomodoro complete" \
            "**${extra:-Focus session}** done. 5 min break time. Stand up, drink water, look out a window." \
            -p default -t tomato,white_check_mark -m
        ;;
    pomo-break)
        notify::send personal-pomodoro "☕ Long break" \
            "Long break (15 min). Walk around if you can." \
            -p low -t coffee -m
        ;;
    *) echo "send-personal.sh: unknown action: $action" >&2; exit 2 ;;
esac
