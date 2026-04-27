# ntfy Webhook Receiver

Tailnet HTTP server that turns ntfy notification action buttons into real
system actions. When you tap "Run GC" or "Restart x11vnc" on the phone, the
button POSTs to this receiver, which dispatches the corresponding command
from a server-side allowlist.

| | |
|---|---|
| Bind | `100.116.242.38:9099` (tailnet IP) |
| Auth | `Authorization: Bearer <token>` against `~/.config/notify/webhook-token` |
| Allowlist | `~/.config/notify/webhook-actions.yaml` |
| Audit log | `~/.local/state/notify-webhook/audit.log` (append-only JSONL) |
| Source | `system_scripts/webhook/server.py` |
| NixOS module | `system_nixos/notify-webhook.nix` (imported by `desktop-beelink.nix`) |
| Service | `notify-webhook.service` (system, runs as user `shantanu`) |
| Topic for follow-ups | `actions` |

## How it Works End-to-End

1. **Publisher** (e.g. `send-disk.sh`) builds a notification with action
   buttons, embedding the webhook token in the action's HTTP headers.

2. **ntfy server** caches and delivers the notification to subscribed devices.

3. **Phone receives** the notification. User sees buttons rendered on the
   notification card.

4. **User taps a button**. The ntfy app on the device makes the configured
   HTTP request — `POST http://beelink-ser8-desktop:9099/action/<name>` with
   `Authorization: Bearer <token>` and a JSON body of params.

5. **Webhook receiver** validates auth, looks up the action by name,
   substitutes params into the pre-declared command argv slots (no shell
   interpolation), runs it with a timeout, captures output.

6. **Receiver publishes follow-up** to the `actions` topic with the result.
   User sees "✓ Run GC done — freed 4.2G" or "✗ Failed: …".

## Threat Model

The receiver protects against:

- **Lost / stolen phone**: action buttons remain in the notification tray
  until cleared. If the phone is unlocked, anyone can tap. The receiver
  enforces server-side allowlist — phone can't pass arbitrary commands or
  paths.
- **Replay**: optional `X-Action-Nonce` header is tracked in memory with
  TTL. Repeated nonces return 409.
- **Token leak via cached notifications**: ntfy notifications cache the
  action body for 12h. Tokens live in those caches. We treat the token as
  "proof of receipt", not "proof of intent". The allowlist is the actual
  enforcement.
- **Confused-deputy / param injection**: param values are validated against
  a strict regex (`^[a-zA-Z0-9_.@:/-]{0,256}$`) before substitution. They
  only fill pre-declared positional placeholders, never get concatenated
  into shell strings.

What the receiver does **not** protect against:

- A compromised tailnet device. Tailnet is the boundary — anyone on tailnet
  with the token can act.
- Token rotation. Manual: regenerate the token file, update phone
  subscriptions (token sits in action headers, so phone needs a refreshed
  notification — easiest path is to publish a "rotated, please dismiss old
  notifications" message).
- Auditing what action triggered what notification. We log the dispatch
  but not which originating notification produced it.

## Authoring an Action

`~/.config/notify/webhook-actions.yaml` (mode 600, **not** in chezmoi):

```yaml
actions:
  my-action:
    type: command
    description: What this does (shows in follow-up notifications)
    command: ["sudo", "systemctl", "restart", "my-service"]
    timeout_s: 30
    follow_up_topic: actions
```

Reload after edit: `systemctl restart notify-webhook` (or `kill -HUP <pid>`
for hot-reload of just the actions table).

For commands that need params:

```yaml
actions:
  snooze-topic:
    type: command
    description: Snooze a topic
    command: ["/path/to/snooze.sh", "{{params.topic}}", "{{params.minutes}}"]
    timeout_s: 5
    # follow_up_topic omitted → silent
```

Param substitution rules:
- Only **full-token replacement** of `{{params.X}}` placeholders. No shell
  concat, no f-string-style interpolation.
- Param values must match `^[a-zA-Z0-9_.@:/-]{0,256}$`. Anything else is
  rejected at the receiver before exec.
- Param keys must match `^[a-zA-Z0-9_.-]{1,64}$`.

For HTTP proxy actions (e.g. talking to loopback Hermes/Zeroclaw):

```yaml
actions:
  zeroclaw-prompt:
    type: http_proxy
    description: Send a prompt to Zeroclaw
    target: "http://127.0.0.1:42617/api/prompt"
    method: POST
    body_template: '{"prompt": "{{params.prompt}}"}'
    headers:
      Content-Type: application/json
      Authorization: "Bearer <zeroclaw-token-after-pairing>"
    timeout_s: 300
    follow_up_topic: actions
```

## Building Action-Rich Notifications

In any `send-*.sh` wrapper:

```bash
source "${LIB_DIR}/lib.sh"

actions_args=()
if [[ -n "${NTFY_WEBHOOK_TOKEN:-}" ]]; then
    actions_args+=( -a "$(notify::action_webhook "Run GC" "run-gc")" )
    actions_args+=( -a "$(notify::action_view "Open dashboard" "https://grafana.local/")" )
    snooze_body='{"params":{"topic":"disk","minutes":"240"}}'
    actions_args+=( -a "$(notify::action_webhook "Snooze 4h" "snooze-topic" "$snooze_body")" )
fi

notify::warn disk "Title" "Body markdown" -m "${actions_args[@]}"
```

The helpers:

| Helper | Purpose |
|---|---|
| `notify::action_webhook <label> <action-name> [body-json]` | Build an HTTP action targeting the local webhook receiver. Token sourced from `$NTFY_WEBHOOK_TOKEN`. |
| `notify::action_view <label> <url> [clear=true]` | Build a view action (open URL). |
| `notify::action_broadcast <label> <intent> [extras]` | Build an Android broadcast action (silent on iOS). |

Hard limit: **3 actions per notification** (ntfy enforces).

## Token Provisioning

```bash
# Initial setup
mkdir -p ~/.config/notify
chmod 700 ~/.config/notify
head -c 32 /dev/urandom | base64 | tr -d '/+=' | head -c 32 > ~/.config/notify/webhook-token
chmod 600 ~/.config/notify/webhook-token

# Make the token available to the systemd timer environment so all
# wrappers can build action-rich notifications. Add to /etc/profile.d/ or
# the user's ~/.profile, OR set per-service via Environment= in the
# .timer's [Service] section.
echo "export NTFY_WEBHOOK_TOKEN=\$(cat ~/.config/notify/webhook-token)" \
    >> ~/.profile
```

For systemd user services that publish notifications (battery-monitor,
notify-host-monitors, etc.), the token must be in their environment. Add to
each service's `[Service]` section:

```ini
EnvironmentFile=-/home/shantanu/.config/notify/webhook-env
```

…where `webhook-env` is:

```
NTFY_WEBHOOK_TOKEN=<the-token>
```

## Audit Log

Every dispatched action is logged to `~/.local/state/notify-webhook/audit.log`:

```jsonl
{"ts":1777324983.40,"event":"dispatch","action":"snooze-topic","params":{"topic":"test","minutes":"5"},"remote":"127.0.0.1"}
{"ts":1777324983.41,"event":"complete","action":"snooze-topic","exit_code":0,"duration_s":0.01}
{"ts":1777325000.12,"event":"auth_fail","path":"/action/run-gc","remote":"100.96.204.84"}
```

Useful queries:
```bash
# All failed auths in the last hour
jq 'select(.event == "auth_fail" and .ts > now - 3600)' ~/.local/state/notify-webhook/audit.log

# All run-gc invocations
jq 'select(.action == "run-gc")' ~/.local/state/notify-webhook/audit.log

# Histogram of actions
jq -r 'select(.event == "dispatch") | .action' ~/.local/state/notify-webhook/audit.log | sort | uniq -c
```

## Manage

```bash
# Status
systemctl status notify-webhook

# Logs
journalctl -u notify-webhook --since "1 hour ago"

# Reload action config (hot-reload, no restart)
sudo systemctl kill --signal=HUP notify-webhook

# Restart (full reload)
sudo systemctl restart notify-webhook

# Hand-test without ntfy involvement
TOKEN=$(cat ~/.config/notify/webhook-token)
curl -X POST -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"params":{"topic":"test","minutes":"10"}}' \
     http://beelink-ser8-desktop:9099/action/snooze-topic

# Health check (no auth required)
curl http://beelink-ser8-desktop:9099/health
```

## Pre-built Actions

See `system_scripts/webhook/webhook-actions.example.yaml` for the canonical
list. As of writing:

| Name | Type | Description |
|---|---|---|
| `run-gc` | command | `sudo nix-collect-garbage -d` |
| `optimise-store` | command | `sudo nix-store --optimise` |
| `restart-x11vnc` | command | `sudo systemctl restart x11vnc` |
| `restart-novnc` | command | `sudo systemctl restart novnc` |
| `restart-realvnc` | command | `sudo systemctl restart vncserver-x11-serviced` |
| `restart-ntfy` | command | `sudo systemctl restart ntfy-sh` |
| `process-inbox` | command | `claude -p "..." ` against vault inbox |
| `vault-health` | command | `claude -p "..."` health audit |
| `morning-briefing` | command | `claude -p "..."` briefing generation |
| `snooze-topic` | command | Mark a topic snoozed for N minutes |
| `zeroclaw-prompt` | http_proxy | POST to `127.0.0.1:42617/api/prompt` (needs pairing) |
| `hermes-health` | http_proxy | GET hermes `/v1/health` |

## Next Steps

- [ ] **Pair with Zeroclaw** — `POST http://127.0.0.1:42617/pair`, store
      token, fill in `Authorization: Bearer <token>` for `zeroclaw-prompt`.
- [ ] **Document Zeroclaw API** — once paired, map its endpoints and add
      richer actions (run agent, list tasks, get status).
- [ ] **Wire token into timer services** — `EnvironmentFile=` on
      `notify-host-monitors.service`, `notify-systemd-health.service`,
      `battery-monitor.service` so their notifications include action
      buttons.
- [ ] **Build vault-capture-in listener** — separate subscriber that takes
      phone publishes → vault inbox files. (Subscriber pattern, not
      receiver — different process.)
- [ ] **Token rotation runbook** — quarterly cadence + when the phone
      changes.

## Related

- `system_scripts/notify/lib.sh` — extended publish library
- `system_scripts/notify/topics.md` — topic registry (`actions` is here)
- `docs/system/ntfy Advanced Features Reference.md` — header / API reference
- `docs/system/On-Host API Endpoints.md` — what actions can target
- `docs/system/Interactive Notifications — Architecture.md` — design decisions
- `docs/system/Future Work — ntfy Personal Topic Prefix.md` — defers per-topic isolation
