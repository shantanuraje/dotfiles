# ntfy Topic Registry

All notifications travel through `http://beelink-ser8-desktop:8090` over the
tailnet. Topics are not pre-created — they exist as soon as any client
publishes to or subscribes to them. This file is the source of truth for
*which* topics we use, so we don't fragment names by accident.

Subscribe to whichever subset you want on each device (phone, iPad, browser).
Suggested per-device subscription sets are at the bottom.

| Topic | Domain | Carries | Default priority | Wired by |
|---|---|---|---|---|
| `system-deploy` | NixOS / chezmoi | rebuild ok/fail, generation #, host, duration | normal/high | `system_scripts/deploy-nixos.sh` |
| `system-flake` | flake updates | which inputs bumped, lock changes | low | (tier 2, not yet) |
| `system-gc` | nix-collect-garbage | bytes freed | min | (tier 2) |
| `power` | battery + AC | low (15%), critical (5%), AC plug/unplug | high/urgent | `private_dot_config/polybar/scripts/battery-monitor.sh` |
| `disk` | storage health | / + /home over warn(80%) / critical(90%) | high/urgent | `monitor/disk-health.sh` |
| `temp` | thermal | CPU > 85 °C sustained ≥ 3 polls | high/urgent | `monitor/thermal-health.sh` |
| `tailnet` | mesh state | drop/restore with downtime duration | urgent/normal | `monitor/network-health.sh` |
| `network` | internet | WAN drop/restore, public IPv6 changed | high | `monitor/network-health.sh` |
| `security` | auth | failed sudo, VNC auth fail, sshd attempt | urgent | (tier 3 — pending) |
| `vault-briefing` | morning summary | due today + overdue + inbox count | normal | (design — see `Vault Notification System Design.md`) |
| `vault-inbox` | inbox sweep | items processed, items left | low | (design) |
| `vault-evening` | end-of-day | what shipped, what's pending | low | (design) |
| `vault-health` | weekly audit | broken links, missing frontmatter | low | (design) |
| `vault-due` / `vault-overdue` / `vault-reminders` | task-driven | due/overdue/scheduled task batches | normal/high | (design) |
| `vault-capture` | capture confirmations | inbox arrivals (with obsidian:// click), agent-created notes | low | `vault-capture/server.py` |
| `vault-capture-in` | **inbound** — phone publishes thoughts here | listener writes them to `~/Documents/personal/00-Inbox/` | n/a | `vault-capture/server.py` (subscriber) |
| `dev-builds` | ad-hoc `done` wrapper | `cargo test && done` | normal | (tier 3) |
| `personal-hydration` | break reminders | water / stretch / posture | min | `notify-hydration.timer`, `notify-posture.timer` |
| `personal-pomodoro` | focus | session start/end | low | `send-personal.sh` (manual invoke) |
| `calendar` | upcoming events | "in 15 min: …" with click → meeting URL | high | (tier 3) |
| `media` | downloads | yt-dlp done, big file copied | low | (tier 3) |
| `errors` | systemd OnFailure catch-all + health monitor | unit failures, restart loops, last 10 log lines | urgent | `send-error.sh`, `monitor/systemd-health.sh` |
| `system-recover` | unit recoveries | systemd unit transitioned failed → active | low (info) | `monitor/systemd-health.sh` |
| `actions` | webhook receiver follow-ups | "✓ Run GC done — freed 4.2G", "✗ Restart failed: …" | normal | `system_scripts/webhook/server.py` (post-action confirmations) |

## How to publish

```bash
# Direct (curl)
curl -d "build done" http://beelink-ser8-desktop:8090/dev-builds

# Via the library (shell scripts)
source /home/shantanu/.local/share/chezmoi/system_scripts/notify/lib.sh
notify::ok system-deploy "Deploy succeeded" "generation 142, beelink, 4m12s"
notify::warn power "Battery low" "15% remaining — plug in soon" -c "ssh://beelink"
```

## How to subscribe (devices)

| Device | Suggested subscriptions |
|---|---|
| Phone | `power`, `security`, `errors`, `calendar`, `system-deploy` |
| iPad  | `vault-briefing`, `vault-inbox`, `vault-evening`, `personal-pomodoro`, `calendar` |
| Browser (web UI) | everything during work hours; mute via web app outside |
| CLI tail (any tailnet host) | `ntfy subscribe http://beelink-ser8-desktop:8090/<topic>` |

## Severity convention

| Level | ntfy priority | When |
|---|---|---|
| info | low | Routine signal — no action needed |
| ok | default | Successful completion of an explicit action |
| warn | high | Something needs attention soon |
| alert | urgent | Bypass DND; act now |
| error | high (with bug tag) | Something failed |

The `notify::info / ok / warn / alert / error` wrappers in `lib.sh` set these
defaults. Override with explicit `-p` if needed.

## Naming conventions

- **Plain, lowercase, hyphen-separated.** No `nixos-*` prefix — the server is
  ours and we know what it carries.
- **Domain prefix when a category will have many topics** (`vault-*`,
  `personal-*`, `system-*`, `dev-*`).
- **Singular when the topic carries one type of event** (`power`, `disk`,
  `calendar`); the domain prefix already implies multiplicity.

## Hardening path (not enabled now)

If we ever want per-topic ACLs (e.g., `system-deploy` writable only by deploy
script), set `auth-default-access = "deny-all"` in the ntfy module and:

```bash
sudo ntfy user add deploy-bot
sudo ntfy access deploy-bot system-deploy write-only
sudo ntfy token add deploy-bot
```

Then store the token in a systemd `EnvironmentFile` and add
`-H "Authorization: Bearer $NTFY_TOKEN"` in `lib.sh`. Until then: open auth,
tailnet boundary.
