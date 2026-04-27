#!/usr/bin/env bash
# send-network.sh — internet/tailnet connectivity notifications.
#
# Usage:
#   send-network.sh wan-down
#   send-network.sh wan-up         <downtime-human>
#   send-network.sh tailnet-down
#   send-network.sh tailnet-up     <downtime-human>
#   send-network.sh ipv6-changed   <old-prefix> <new-prefix>

set -euo pipefail
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${LIB_DIR}/lib.sh"

action="${1:?need action}"
host="$(hostname)"

case "$action" in
    wan-down)
        notify::warn network "🌐 WAN down" \
            "**${host}** lost internet connectivity (DNS + ICMP both failing)." \
            -t warning,globe_with_meridians -m
        ;;
    wan-up)
        downtime="${2:-?}"
        notify::ok network "🌐 WAN back up" \
            "**${host}** reconnected to the internet after ${downtime} downtime." \
            -t white_check_mark,globe_with_meridians -m
        ;;
    tailnet-down)
        notify::alert tailnet "🔌 Tailnet down" \
            "**${host}** lost Tailscale connectivity. ntfy notifications won't reach the phone until restored. (You're seeing this only if it published before the drop.)" \
            -t rotating_light,electric_plug -m
        ;;
    tailnet-up)
        downtime="${2:-?}"
        notify::ok tailnet "✓ Tailnet restored" \
            "**${host}** is back on the tailnet after ${downtime} downtime." \
            -t white_check_mark,electric_plug -m
        ;;
    ipv6-changed)
        old="${2:?need old prefix}"
        new="${3:?need new prefix}"
        notify::warn network "🌐 Public IPv6 changed" \
            "**${host}** public IPv6 prefix changed:
\`${old}\` → \`${new}\`

If anything was relying on the old prefix in DNS or firewall rules, audit." \
            -t warning,globe_with_meridians -m
        ;;
    *) echo "send-network.sh: unknown action: $action" >&2; exit 2 ;;
esac
