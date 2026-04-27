#!/usr/bin/env bash
# network-health.sh — watch WAN + tailnet + public IPv6 prefix.
#
# Three transitions tracked:
#   1. WAN: reachable ↔ unreachable (DNS+ICMP test)
#   2. Tailnet: connected ↔ disconnected (tailscale status)
#   3. Public IPv6 prefix change (first 4 hextets)
#
# State persisted under ~/.local/state/network-health/. Down→up notifications
# include downtime duration. Tailnet-down note: if tailnet is down, the
# notification can't reach the phone *until* it comes back; we publish anyway
# so the message is in the cache when reconnect happens.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOTIFY="${SCRIPT_DIR}/../notify/send-network.sh"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/network-health"
mkdir -p "$state_dir"

now=$(date +%s)
fmt_duration() {
    local s=$1
    if   (( s < 60   )); then echo "${s}s"
    elif (( s < 3600 )); then echo "$(( s / 60 ))m$(( s % 60 ))s"
    else                       echo "$(( s / 3600 ))h$(( s % 3600 / 60 ))m"
    fi
}

# ── 1. WAN reachability ──────────────────────────────────────────────────────
# Considered up if either DNS or ICMP works against a public anchor.
wan_up=0
if getent ahosts cloudflare.com >/dev/null 2>&1; then wan_up=1; fi
if (( wan_up == 0 )) && ping -c1 -W2 1.1.1.1 >/dev/null 2>&1; then wan_up=1; fi

wan_state_file="${state_dir}/wan"
wan_down_since="${state_dir}/wan-down-since"
wan_prev=$(cat "$wan_state_file" 2>/dev/null || echo 1)

if (( wan_up == 0 && wan_prev == 1 )); then
    echo "$now" > "$wan_down_since"
    "$NOTIFY" wan-down || true
elif (( wan_up == 1 && wan_prev == 0 )); then
    down_at=$(cat "$wan_down_since" 2>/dev/null || echo "$now")
    "$NOTIFY" wan-up "$(fmt_duration $((now - down_at)))" || true
    rm -f "$wan_down_since"
fi
echo "$wan_up" > "$wan_state_file"

# ── 2. Tailnet connectivity ──────────────────────────────────────────────────
# `tailscale status --peers=false --self=true` returns 0 with a self line if up.
tailnet_up=0
if command -v tailscale >/dev/null 2>&1; then
    if tailscale status --peers=false --json 2>/dev/null \
        | grep -q '"BackendState":"Running"'; then
        tailnet_up=1
    fi
fi

tn_state_file="${state_dir}/tailnet"
tn_down_since="${state_dir}/tailnet-down-since"
tn_prev=$(cat "$tn_state_file" 2>/dev/null || echo 1)

if (( tailnet_up == 0 && tn_prev == 1 )); then
    echo "$now" > "$tn_down_since"
    "$NOTIFY" tailnet-down || true
elif (( tailnet_up == 1 && tn_prev == 0 )); then
    down_at=$(cat "$tn_down_since" 2>/dev/null || echo "$now")
    "$NOTIFY" tailnet-up "$(fmt_duration $((now - down_at)))" || true
    rm -f "$tn_down_since"
fi
echo "$tailnet_up" > "$tn_state_file"

# ── 3. Public IPv6 prefix change ─────────────────────────────────────────────
# First 4 hextets of any global v6 on the primary uplink.
v6_prefix=$(ip -6 -brief addr show scope global 2>/dev/null \
    | awk '$1!~/^tailscale/ && $0!~/temporary/ {for(i=3;i<=NF;i++) if($i ~ /^[0-9a-f:]+\//) {print $i; exit}}' \
    | cut -d: -f1-4 | head -1 || echo "")

if [[ -n "$v6_prefix" ]]; then
    v6_state_file="${state_dir}/v6-prefix"
    v6_prev=$(cat "$v6_state_file" 2>/dev/null || echo "")
    if [[ -n "$v6_prev" && "$v6_prev" != "$v6_prefix" ]]; then
        "$NOTIFY" ipv6-changed "$v6_prev" "$v6_prefix" || true
    fi
    echo "$v6_prefix" > "$v6_state_file"
fi
