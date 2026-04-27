#!/usr/bin/env bash
# snooze.sh — record a "snoozed until" timestamp for a topic.
#
# Usage:
#   snooze.sh <topic> <minutes>
#
# Writes ~/.local/state/notify-snooze/<topic> with epoch-seconds-until
# timestamp. Publishers check this file and skip publishing while snoozed.

set -euo pipefail

topic="${1:?need topic}"
minutes="${2:?need minutes}"

# Validate inputs to prevent path traversal / injection
[[ "$topic" =~ ^[a-zA-Z0-9_.-]+$ ]] || { echo "bad topic: $topic" >&2; exit 1; }
[[ "$minutes" =~ ^[0-9]+$ ]] || { echo "bad minutes: $minutes" >&2; exit 1; }

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/notify-snooze"
mkdir -p "$state_dir"

until_ts=$(( $(date +%s) + minutes * 60 ))
echo "$until_ts" > "${state_dir}/${topic}"

echo "snoozed ${topic} until $(date -d @${until_ts})"
