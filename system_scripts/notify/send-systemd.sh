#!/usr/bin/env bash
# send-systemd.sh — publish notifications about systemd unit health.
#
# Sophisticated version: failure notifications include "Restart unit" and
# "View logs" actions. The restart action goes via the webhook receiver,
# which has narrow sudoers entries for the specific units we whitelist.
#
# Usage:
#   send-systemd.sh failed       <unit> <scope>           # newly failed
#   send-systemd.sh recovered    <unit> <scope>           # failed → healthy
#   send-systemd.sh restart-loop <unit> <scope> <count>   # NRestarts ≥ threshold

set -euo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${LIB_DIR}/lib.sh"

action="${1:?need action}"
unit="${2:?need unit name}"
scope="${3:?need scope: system | user}"
extra="${4:-}"
host="$(hostname)"

# journalctl invocation differs for system vs user scope
journal_cmd=( journalctl --no-pager --lines=10 --output=short )
case "$scope" in
    system) journal_cmd+=( -u "$unit" ) ;;
    user)   journal_cmd+=( --user-unit "$unit" ) ;;
    *) echo "send-systemd.sh: bad scope: $scope" >&2; exit 2 ;;
esac

journal_tail() {
    "${journal_cmd[@]}" 2>/dev/null | tail -10 || echo '(no log lines)'
}

# Build action buttons. Only for units we have specific restart actions for —
# otherwise the button would just 404 against the webhook.
known_restart_actions() {
    case "$1" in
        x11vnc.service)                  echo "restart-x11vnc" ;;
        novnc.service)                   echo "restart-novnc" ;;
        vncserver-x11-serviced.service)  echo "restart-realvnc" ;;
        ntfy-sh.service)                 echo "restart-ntfy" ;;
        *) echo "" ;;
    esac
}

actions_args=()
if [[ -n "${NTFY_WEBHOOK_TOKEN:-}" ]] && [[ "$action" == "failed" || "$action" == "restart-loop" ]]; then
    restart_act=$(known_restart_actions "$unit")
    if [[ -n "$restart_act" ]]; then
        actions_args+=( -a "$(notify::action_webhook "Restart ${unit%.service}" "$restart_act")" )
    fi
fi

case "$action" in
    failed)
        notify::alert errors \
            "💥 ${scope} unit failed: ${unit}" \
            "**Host**: ${host}
**Scope**: ${scope}

### Last log lines
\`\`\`
$(journal_tail)
\`\`\`" \
            -t boom,bug -m "${actions_args[@]}"
        ;;
    recovered)
        notify::info system-recover \
            "✓ ${scope} unit recovered: ${unit}" \
            "**${unit}** on **${host}** is back to healthy state." \
            -t white_check_mark,arrow_up -m
        ;;
    restart-loop)
        notify::warn errors \
            "🔁 Restart loop: ${unit}" \
            "**${unit}** on **${host}** (${scope}) has restarted **${extra}** times.

### Last log lines
\`\`\`
$(journal_tail)
\`\`\`" \
            -t repeat,warning -m "${actions_args[@]}"
        ;;
    *)
        echo "send-systemd.sh: unknown action: $action" >&2
        exit 2
        ;;
esac
