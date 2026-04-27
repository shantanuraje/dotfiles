# systemd Health Monitor

Background timer that watches systemd unit health (both system-scope and
user-scope) and publishes ntfy notifications on **state transitions**.

| | |
|---|---|
| Trigger | user-level systemd timer, fires every 5 minutes |
| Script | `system_scripts/monitor/systemd-health.sh` |
| Service unit | `private_dot_config/systemd/user/notify-systemd-health.service` |
| Timer unit | `private_dot_config/systemd/user/notify-systemd-health.timer` |
| State | `~/.local/state/systemd-health/{system,user}/{failed,restart-counts}` |
| Topics | `errors` (urgent), `system-recover` (low) |
| Privilege | runs as user — reading systemd state needs no root |

## What It Detects

| Transition | Topic | Priority | Tags | Includes |
|---|---|---|---|---|
| Healthy → failed | `errors` | urgent | `boom,bug` | unit name, scope, last 10 journal lines |
| Failed → active | `system-recover` | low | `white_check_mark,arrow_up` | unit name, scope |
| Restart count ≥ 3 (and rising) | `errors` | high | `repeat,warning` | unit name, scope, NRestarts, last 10 journal lines |

Notifications fire only on **transitions** — a unit that's been failed for
hours doesn't re-spam every 5 minutes. State is persisted between runs in
`~/.local/state/systemd-health/`.

## Why User-Scope for Both

A user can read systemd state for system units without privilege
(`systemctl list-units --failed` works as any user). Running the timer at
user-scope avoids needing a NixOS module change, gets us linger-protected
delivery (timer keeps running across logout), and consolidates state under
the user's XDG dirs. Two `ExecStart=` lines in one service unit cover both
scopes:

```ini
[Service]
Type=oneshot
ExecStart=%h/.local/share/chezmoi/system_scripts/monitor/systemd-health.sh --scope system
ExecStart=%h/.local/share/chezmoi/system_scripts/monitor/systemd-health.sh --scope user
```

## What It Catches in Practice

- `claude-causelist-sync.service` failed (cron job error) — fires once
  immediately on the next poll, doesn't re-fire until it recovers and fails
  again.
- `hermes-gateway.service` crash-loops (e.g. config breakage) — restart-loop
  notification once NRestarts ≥ 3, escalates each time the count rises.
- `battery-monitor.service` died — failure notification.
- `claude-bhc-poller.service` succeeded after multiple failures — recovery
  notification on `system-recover` (mute on phone, watch on web UI).
- New NixOS rebuild leaves a system service in a failed state — caught
  within 5 minutes.

## What It Does Not Catch (yet)

- **Stuck timers**: a timer whose `LAST` is older than the next expected
  fire window. (A failed timer would show as a failed unit, but a *silent*
  timer that's not firing wouldn't.) Add later if needed.
- **Slow / hung services**: oneshot services that stall but don't fail.
  Would need timeout logic.
- **Severity in journal**: services that log ERRORs/CRITICALs but stay
  active. Would need a separate journal scanner.

## Manage

```bash
# Status
systemctl --user status notify-systemd-health.timer
systemctl --user status notify-systemd-health.service

# Logs
journalctl --user -u notify-systemd-health.service --since "1 hour ago"

# Trigger a run manually
systemctl --user start notify-systemd-health.service

# Disable
systemctl --user disable --now notify-systemd-health.timer

# Reset state (will re-notify currently-failed units on next run)
rm -rf ~/.local/state/systemd-health/
systemctl --user start notify-systemd-health.service
```

## Tuning

- **Interval**: change `OnUnitActiveSec=5min` in the `.timer` file. Shorter
  = faster alerts, more wakeups. 5 min is a reasonable default.
- **Restart-loop threshold**: change `RESTART_THRESHOLD=3` near the top of
  `systemd-health.sh`.
- **Suppressing a noisy unit**: add the unit name to a skip list before the
  diff (currently the script doesn't have one — add a `SKIP_UNITS` array
  and `comm -23 ... | grep -vFf <(printf '%s\n' "${SKIP_UNITS[@]}")` if it
  becomes necessary).

## Related

- `system_scripts/notify/lib.sh` — the publish helper
- `system_scripts/notify/send-systemd.sh` — formats the systemd notifications
- `system_scripts/notify/topics.md` — full topic registry
- `docs/system/ntfy-sh Setup.md` — server setup
- `docs/system/ntfy Android Setup.md` — phone subscription guide
