#!/usr/bin/env bash
# send-deploy.sh — publish NixOS / chezmoi deploy notifications.
#
# Sophisticated version: action buttons on success (view generation list),
# on failure (rollback + view logs).
#
# Usage:
#   send-deploy.sh ok       <duration> [host]
#   send-deploy.sh fail     <duration> [host]
#   send-deploy.sh rollback <reason>   [host]

set -euo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${LIB_DIR}/lib.sh"

action="${1:?need action: ok | fail | rollback}"
arg="${2:-}"
host="${3:-$(hostname)}"

# Pull short stats from the system
generation=""
if command -v nixos-rebuild >/dev/null 2>&1; then
    generation=$(readlink /nix/var/nix/profiles/system 2>/dev/null | grep -oE '[0-9]+$' || true)
fi

# Build action specs (best-effort — if NTFY_WEBHOOK_TOKEN unset, we just skip them)
actions_args=()
if [[ -n "${NTFY_WEBHOOK_TOKEN:-}" ]]; then
    case "$action" in
        ok)
            actions_args+=( -a "$(notify::action_view "View generation history" "obsidian://open?vault=personal&file=05-Meta/05-04-System-Management" false)" )
            ;;
        fail)
            actions_args+=( -a "$(notify::action_webhook "Rollback now" "rollback-nixos")" )
            actions_args+=( -a "$(notify::action_view "View systemd journal" "ssh://${host}/?cmd=journalctl%20-xe" true)" )
            ;;
    esac
fi

case "$action" in
    ok)
        notify::ok system-deploy \
            "✓ NixOS deploy succeeded" \
            "**${host}** rebuilt successfully in ${arg:-?}.${generation:+
**Generation**: \`${generation}\`}" \
            -t white_check_mark,gear -m "${actions_args[@]}"
        ;;
    fail)
        notify::error system-deploy \
            "✗ NixOS deploy failed" \
            "**${host}** rebuild failed after ${arg:-?}.

\`/etc/nixos\` left as-is for inspection. System still on previous generation (boot loader untouched).

To restore previous /etc/nixos files: \`sudo cp -r /tmp/nixos-backup-* /etc/nixos/\`" \
            -t x,gear,fire -m "${actions_args[@]}"
        ;;
    rollback)
        notify::warn system-deploy \
            "⏪ NixOS rollback" \
            "**${host}** rolled back. Reason: ${arg:-unspecified}." \
            -t rewind,gear -m
        ;;
    *)
        echo "send-deploy.sh: unknown action: $action" >&2
        exit 2
        ;;
esac
