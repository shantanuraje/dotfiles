#!/usr/bin/env bash
# send-disk.sh — disk space notifications with action buttons.
#
# Critical disk warning includes:
#   - "Run nix-collect-garbage" button (webhook → sudo nix-collect-garbage)
#   - "Run nix-store --optimise" button (webhook)
#   - "Snooze 4h" button (webhook → state file)
#
# Usage:
#   send-disk.sh warn     <mount> <pct-used> <free-human>
#   send-disk.sh critical <mount> <pct-used> <free-human>
#   send-disk.sh recover  <mount> <pct-used> <free-human>

set -euo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${LIB_DIR}/lib.sh"

action="${1:?need action: warn | critical | recover}"
mount="${2:?need mount}"
pct="${3:?need pct used}"
free="${4:?need free-human}"
host="$(hostname)"

# Top consumers — captured at notification time. Bounded with timeout +
# `-x` (one filesystem) + `-d 1` (one level) to avoid scanning trees.
top_consumers=""
if [[ "$action" != "recover" ]] && command -v du >/dev/null 2>&1; then
    top_consumers=$(timeout 10 du -shx -d 1 "${mount}"/* 2>/dev/null \
        | sort -h -r | head -5 \
        | awk '{print "- `" $1 "` " $2}' \
        || true)
fi

# Build action buttons when webhook token is available
actions_args=()
if [[ -n "${NTFY_WEBHOOK_TOKEN:-}" ]] && [[ "$action" != "recover" ]]; then
    actions_args+=( -a "$(notify::action_webhook "Run GC" "run-gc")" )
    actions_args+=( -a "$(notify::action_webhook "Optimise store" "optimise-store")" )
    snooze_body=$(printf '{"params":{"topic":"disk","minutes":"240"}}')
    actions_args+=( -a "$(notify::action_webhook "Snooze 4h" "snooze-topic" "$snooze_body")" )
fi

case "$action" in
    warn)
        notify::warn disk "💾 Disk filling: ${mount}" \
            "**${host}** \`${mount}\` is **${pct}%** full (${free} free).${top_consumers:+

### Top consumers
${top_consumers}}" \
            -t warning,floppy_disk -m "${actions_args[@]}"
        ;;
    critical)
        notify::alert disk "🔥 Disk almost full: ${mount}" \
            "**${host}** \`${mount}\` is **${pct}%** full — only ${free} free. Free space now to avoid failures.${top_consumers:+

### Top consumers
${top_consumers}}" \
            -t rotating_light,floppy_disk -m "${actions_args[@]}"
        ;;
    recover)
        notify::ok disk "✓ Disk recovered: ${mount}" \
            "**${host}** \`${mount}\` is back under threshold (${pct}% used, ${free} free)." \
            -t white_check_mark,floppy_disk -m
        ;;
    *) echo "send-disk.sh: unknown action: $action" >&2; exit 2 ;;
esac
