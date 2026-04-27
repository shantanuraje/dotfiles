# ntfy-sh Self-Hosted Notification Server

## Overview

Self-hosted [ntfy.sh](https://ntfy.sh) push notification server running on the
Beelink desktop, exposed only on the Tailscale network. Used for sending
notifications from scripts, services, and automation to phones, tablets, and
other tailnet devices.

| Setting | Value |
|---------|-------|
| Host | `beelink-ser8-desktop` (tailnet MagicDNS) |
| Tailnet IP | `100.116.242.38` |
| Port | `8090` (TCP) |
| Base URL | `http://beelink-ser8-desktop:8090` |
| Auth | Open (`read-write`) — tailnet ACLs are the access boundary |
| State dir | `/var/lib/ntfy-sh/` |
| Logs | `journalctl -u ntfy-sh` |

## NixOS Configuration

**File**: `system_nixos/machines/personal/desktop-beelink.nix`

```nix
services.ntfy-sh = {
  enable = true;
  settings = {
    base-url = "http://beelink-ser8-desktop:8090";
    listen-http = ":8090";
    behind-proxy = false;
    cache-file = "/var/lib/ntfy-sh/cache.db";
    cache-duration = "12h";
    attachment-cache-dir = "/var/lib/ntfy-sh/attachments";
    # auth-default-access defaults to "read-write" (open).
    # To tighten: set "deny-all" and `ntfy user add`.
  };
};

# Open ntfy port on tailnet interface only (merges with system-common.nix list)
networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 8090 ];
```

The NixOS module installs the `ntfy` CLI system-wide and runs the server as a
`DynamicUser` with state under `/var/lib/ntfy-sh/`. No further setup needed.

## Why Tailnet-Only

- IP must never be exposed to the internet (per security policy).
- Tailscale ACLs gate which devices can reach port 8090 — defense in depth on
  top of the NixOS firewall, which only opens 8090 on `tailscale0`.
- No TLS needed for tailnet traffic (WireGuard already encrypts).
- No auth needed because the tailnet itself authenticates devices.

## Usage

### Publish from any tailnet device

```bash
# Simple message
ntfy publish http://beelink-ser8-desktop:8090/<topic> "hello"

# Or via curl
curl -d "build done" http://beelink-ser8-desktop:8090/<topic>

# With title, priority, tags
curl \
  -H "Title: Deploy complete" \
  -H "Priority: high" \
  -H "Tags: white_check_mark" \
  -d "Beelink rebuild succeeded" \
  http://beelink-ser8-desktop:8090/deploys
```

Topic names are arbitrary — they're created the first time you publish to them.
Pick something unguessable for any channel that carries sensitive content
(though the tailnet boundary already protects you).

### Subscribe from phone / iPad

1. Install the **ntfy** app (Android Play Store / iOS App Store).
2. Settings → "Default server" → `http://beelink-ser8-desktop:8090`.
3. Add subscription → topic name (e.g. `deploys`, `alerts`).
4. The phone must be connected to the tailnet for messages to deliver.

### Subscribe from CLI / scripts

```bash
# Stream messages
ntfy subscribe http://beelink-ser8-desktop:8090/<topic>

# JSON output for scripting
ntfy subscribe --format json http://beelink-ser8-desktop:8090/<topic>
```

### Web UI

Open `http://beelink-ser8-desktop:8090` in any browser on a tailnet device.
The web UI lets you subscribe, publish, and inspect topics interactively.

## Suggested Integration Points

- **NixOS deploy script** (`system_scripts/deploy-nixos.sh`): publish to
  `deploys` topic on success/failure.
- **Battery monitor** (existing `battery-monitor.service`): publish low-battery
  alerts to `alerts` topic instead of (or in addition to) local notifications.
- **Vault automation timers** (`claude-*.timer`): publish summary on completion
  so you know the morning briefing / inbox sweep ran.
- **CI / long builds**: publish when a remote build finishes.
- **One-off tasks**: `long-running-thing && ntfy publish .../done "✓"`

## Hardening Path (when needed)

If you ever want per-topic ACLs or tokens:

```nix
services.ntfy-sh.settings = {
  auth-default-access = "deny-all";
  auth-file = "/var/lib/ntfy-sh/user.db";  # already the default
};
```

Then create users:

```bash
sudo ntfy user add --role=admin shantanu
sudo ntfy access shantanu deploys read-write
sudo ntfy token add shantanu  # for headless publishers
```

Use the token via `Authorization: Bearer <token>` header.

## Troubleshooting

```bash
# Service status
systemctl status ntfy-sh

# Logs
journalctl -u ntfy-sh -f

# Health check (from any tailnet device)
curl http://beelink-ser8-desktop:8090/v1/health

# Verify port is open on tailscale0 only
sudo iptables -L nixos-fw -n | grep 8090
```

If a phone can't connect: confirm Tailscale is up on the phone, MagicDNS is
enabled in the tailnet, and the phone is not on a "shields up" / exit-node
config that blocks LAN.

## Related

- `docs/system/ntfy Android Setup.md` — phone subscription guide
- `system_scripts/notify/lib.sh` — shell library used by deploy/battery/etc.
- `system_scripts/notify/topics.md` — topic registry (publish/subscribe targets)
- `docs/system/2026-03-09 Tailscale VPN Setup.md` — tailnet, MagicDNS, firewall pattern
- `docs/system/VNC_Setup.md` — same tailnet-only firewall pattern, different service
