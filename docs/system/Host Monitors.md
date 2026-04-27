# Host Monitors

Background timer that watches host-level health (disk, thermal, network) and
publishes ntfy notifications on **state transitions**. Companion to the
systemd Health Monitor — same pattern, different signals.

| | |
|---|---|
| Trigger | user systemd timer, every 5 minutes |
| Service | `private_dot_config/systemd/user/notify-host-monitors.service` |
| Timer | `private_dot_config/systemd/user/notify-host-monitors.timer` |
| Scripts | `system_scripts/monitor/{disk,thermal,network}-health.sh` |
| State | `~/.local/state/{disk,thermal,network}-health/` |
| Topics | `disk`, `temp`, `network`, `tailnet` |

## What Each Monitor Detects

### `disk-health.sh`

Polls `df` for `/` and `/home` (or any mounts passed as args).

| Threshold | Topic | Wrapper |
|---|---|---|
| Crosses **80% used** (warn) | `disk` | `notify::warn` |
| Crosses **90% used** (critical) | `disk` | `notify::alert` |
| Drops back below 80% | `disk` | `notify::ok` |

Override defaults via env: `DISK_WARN_PCT=70 DISK_CRITICAL_PCT=85`. State file
per mountpoint at `~/.local/state/disk-health/<sanitized-mount>`.

### `thermal-health.sh`

Reads hottest `/sys/class/thermal/thermal_zone*/temp`. Requires the threshold
to be **sustained for 3 consecutive polls** (15 minutes) to fire — avoids
false alarms on brief load spikes.

| Threshold | Topic | Wrapper |
|---|---|---|
| Crosses **85 °C** (warn) | `temp` | `notify::warn` |
| Crosses **95 °C** (critical) | `temp` | `notify::alert` |
| Drops back below 85 °C | `temp` | `notify::ok` |

Override via env: `THERMAL_WARN_C=75 THERMAL_CRITICAL_C=85
THERMAL_SUSTAIN_RUNS=2`.

### `network-health.sh`

Three independent signals:

1. **WAN reachability** — DNS lookup of cloudflare.com OR ICMP ping to 1.1.1.1. If both fail, WAN is down. Drop and recovery both notified, with downtime duration on recovery.
2. **Tailnet state** — `tailscale status --json` parsed for `BackendState: Running`. Drop and recovery both notified. (Caveat: a tailnet-down notification is published into the local cache; it'll only reach the phone *after* the tailnet comes back. Better than silence — but not real-time.)
3. **Public IPv6 prefix change** — first 4 hextets of any global v6 on a non-tailscale interface. Notifies when prefix changes (relevant because we audited a public-IPv6 exposure on x11vnc; future re-exposure on a new prefix would want re-checking).

Topics: WAN/v6 → `network`, tailnet → `tailnet`.

## Why Transitions Only

Same pattern as the systemd health monitor: a unit (or disk, or thermal
state) that's been bad for hours doesn't re-spam every 5 min. State files
under `~/.local/state/*-health/` track previous state, and transitions
(prev != current) are what fire notifications. Recovery transitions also
fire — so you get end-to-end visibility of incidents.

## Manage

```bash
# Status of the unified host-monitor timer
systemctl --user status notify-host-monitors.timer
systemctl --user status notify-host-monitors.service

# Logs
journalctl --user -u notify-host-monitors.service --since "1 hour ago"

# Trigger immediately (e.g. after fixing something to confirm recovery)
systemctl --user start notify-host-monitors.service

# Disable
systemctl --user disable --now notify-host-monitors.timer

# Run a single monitor by hand (useful for testing / one-off threshold check)
~/.local/share/chezmoi/system_scripts/monitor/disk-health.sh / /home /tmp
~/.local/share/chezmoi/system_scripts/monitor/thermal-health.sh
~/.local/share/chezmoi/system_scripts/monitor/network-health.sh

# Reset state (will re-notify on next run if currently in non-ok state)
rm -rf ~/.local/state/{disk,thermal,network}-health/
systemctl --user start notify-host-monitors.service
```

## Tuning

| Variable | Default | Where |
|---|---|---|
| Disk warn % | 80 | `DISK_WARN_PCT` env or edit script |
| Disk critical % | 90 | `DISK_CRITICAL_PCT` env |
| Thermal warn °C | 85 | `THERMAL_WARN_C` env |
| Thermal critical °C | 95 | `THERMAL_CRITICAL_C` env |
| Thermal sustain runs | 3 | `THERMAL_SUSTAIN_RUNS` env (3 polls × 5min = 15min sustained) |
| Poll interval | 5 min | `OnUnitActiveSec=` in `notify-host-monitors.timer` |

To pass env to the systemd unit: `systemctl --user edit notify-host-monitors.service` and add `[Service]\nEnvironment=DISK_WARN_PCT=70`.

## What's Not Yet Covered

These belong to the same domain but aren't implemented:

- **Memory pressure / swap thrashing** — needs `/proc/pressure/memory` or PSI scrape.
- **Failed login / sudo attempts** — needs journal scanning via `journalctl _SYSTEMD_UNIT=sudo.service`. Reserved as `security` topic.
- **High network throughput anomaly** — needs `ip -s link` baseline + delta comparison.
- **Timer drift** (a timer not firing as scheduled) — different signal from "failed unit"; not yet caught.

## Related

- `system_scripts/notify/lib.sh` — publish library
- `system_scripts/notify/send-{disk,thermal,network}.sh` — formatters
- `system_scripts/notify/topics.md` — topic registry
- `docs/system/Systemd Health Monitor.md` — companion monitor for systemd units
- `docs/system/ntfy-sh Setup.md` — server config
