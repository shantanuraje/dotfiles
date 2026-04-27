# Interactive Notifications — Architecture

> **Status**: implementation complete on the receiver + library side. NixOS
> deploy still pending to start the webhook receiver as a system service.
> See `Webhook Receiver.md` for operational details, `ntfy Advanced
> Features Reference.md` for the full ntfy feature set, and `On-Host API
> Endpoints.md` for what action buttons can target.

## Goal

Make notifications actionable — tap a button and something happens on the
host: restart a service, run nix-collect-garbage, approve a PR, ping a
running agent (Hermes / Zeroclaw / opencode), capture into the vault, etc.
Use the full ntfy feature set (action buttons, markdown, attachments,
deep-links, delays, attachments) instead of pure passive text.

## Threat Model

The threat to design around is *not* a remote attacker — Tailscale already
gates network access. The threats are:

1. **Shoulder-surfing on the phone**: a notification action button is
   visible to anyone holding the phone. A "Power off the host" button is a
   bad idea even if technically possible.
2. **Lost / stolen phone**: a notification with action buttons remains
   actionable until cleared. If the buttons hit unauthenticated endpoints,
   anyone with the phone can act.
3. **Replay**: an attacker who captures one action POST URL could replay it
   indefinitely.
4. **Confused-deputy**: a button targeting an external host with the host's
   credentials in the body could be tricked into acting on the wrong system.

Mitigations baked into the design below: shared-secret token in `Authorization`
header, allowlist of commands (no shell-string passing from the phone),
optional HMAC over body, per-action TTL.

## Layered Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  Phone (ntfy app, on tailnet)                                   │
│                                                                 │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  📦 Disk filling: /                                    │     │
│  │  /home is 86% full (3.2G free)                         │     │
│  │                                                        │     │
│  │  [Run nix-collect-garbage] [Snooze 4h] [Open]          │     │
│  └────────────────────────────────────────────────────────┘     │
│                                                                 │
│  Tap "Run nix-collect-garbage" →                                │
│  POST http://beelink-ser8-desktop:9099/action/run-gc            │
│  Authorization: Bearer <token-from-app-settings>                │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ (over tailnet only)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Beelink — webhook-receiver.service                             │
│                                                                 │
│  1. Verify token (constant-time compare)                        │
│  2. Look up action by name in allowlist                         │
│  3. Run the corresponding command (no shell interpolation       │
│     from the request — only from the static config)             │
│  4. Capture stdout/stderr/exit code                             │
│  5. Publish a follow-up notification with the result            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
              Result published to ntfy on `actions` topic
              Phone shows: "✓ Garbage collection done — freed 4.2G"
```

## Components

### A. Webhook receiver (the new piece)

A small HTTP server on the Beelink listening on tailnet:9099 (placeholder),
firewalled to tailnet only.

| Aspect | Choice | Why |
|---|---|---|
| Language | Python 3 + `http.server` (or FastAPI if richer routing) | Already in our stack; minimal deps |
| Process model | Long-running systemd service | Same pattern as ntfy-sh |
| Auth | `Authorization: Bearer <token>` against `~/.config/notify/webhook-token` | Same tailnet-secret pattern documented in "Future Work — Personal Topic Prefix" |
| Allowlist | YAML or TOML config of action-name → command + args | Phone can't pass arbitrary shell |
| Response | 200 + JSON `{result, exit_code}` synchronously, OR 202 + async with follow-up notification | Long-running actions get the async path |
| Logging | systemd journal | Searchable via `journalctl -u webhook-receiver` |
| Audit | Append every accepted action to `~/.local/state/webhook-receiver/audit.log` | Forensics |

### B. Allowlist config (proposed location)

`~/.config/notify/webhook-actions.yaml` — example structure:

```yaml
# Each action gets a unique name. Notifications reference these names; the
# server maps name → command. The phone cannot pass arbitrary commands.
actions:
  run-gc:
    description: "Run nix-collect-garbage"
    command: ["sudo", "nix-collect-garbage", "-d"]
    timeout_s: 600
    follow_up_topic: actions
    requires: ["wheel"]   # group check before running
    
  restart-x11vnc:
    description: "Restart x11vnc service"
    command: ["sudo", "systemctl", "restart", "x11vnc"]
    timeout_s: 30
    follow_up_topic: actions
    
  process-inbox:
    description: "Trigger Claude inbox processing"
    command: ["claude", "-p", "Process the inbox per the Inbox Specialist protocol. Report what you did."]
    timeout_s: 600
    follow_up_topic: vault-inbox
    cwd: "/home/shantanu/Documents/personal"
    
  hermes-continue:
    description: "Send a continue message to running Hermes session"
    type: http_proxy
    target: "http://localhost:<HERMES_PORT>/<HERMES_API_PATH>"
    method: POST
    body_template: '{"session_id": "{{params.session_id}}", "message": "continue"}'
    follow_up_topic: actions
    
  snooze:
    description: "Mark a topic snoozed for N hours"
    command: ["{{notify_dir}}/snooze.sh", "{{params.topic}}", "{{params.hours}}"]
    timeout_s: 5
    follow_up_topic: null   # silent
```

The key elements: `command` (positional, no shell), `type: http_proxy` for
agent endpoints, `params` from the action POST body (pre-validated against a
schema), and `follow_up_topic` so the user gets a confirmation back.

### C. Library extension

`lib.sh` gains a new function for building action-rich notifications:

```bash
# Existing:
notify::send <topic> <title> <message> [-p priority] [-t tags] [-c click] [-i icon] [-m]

# New:
notify::send-actionable <topic> <title> <message> \
    [-p priority] [-t tags] [-c click] [-i icon] [-m] \
    [-a "view, <label>, <url>" ] \
    [-a "http, <label>, <action-name>[, key=value, key=value, ...]"] \
    [-a "broadcast, <label>, <intent>[, extras...]"] \
    [--clear-on-action]
```

The `-a "http, ..."` form takes an *action name* (mapped to allowlist on the
server side), not a raw URL. The library expands it to:

```
Actions: http, Run GC, http://beelink-ser8-desktop:9099/action/run-gc,
         method=POST,
         headers.Authorization=Bearer <token>,
         clear=true
```

Token is sourced from `~/.config/notify/webhook-token` at publish time and
embedded in the action header. (Note the security trade-off: the token then
sits inside notifications cached on the ntfy server — anyone who reads the
notification can replay the action. Acceptable on a tailnet-only server with
open auth; would need to be revisited if we enable per-topic auth and the
notifications get cached for other users.)

### D. NixOS module

```nix
systemd.services.webhook-receiver = {
  description = "ntfy action-button webhook receiver";
  after = [ "network.target" "ntfy-sh.service" ];
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    Type = "simple";
    User = "shantanu";   # so it can sudo / run user services
    ExecStart = "${pkgs.python3.withPackages (ps: [ ps.fastapi ps.uvicorn ps.pyyaml ])}/bin/python3 /home/shantanu/.local/share/chezmoi/system_scripts/webhook/server.py";
    Restart = "on-failure";
    RestartSec = "5s";
  };
};

# tailnet-only access
networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 9099 ];
```

## Notification Patterns (planned, will detail after research lands)

1. **Disk full** — markdown body with df breakdown table, action: run-gc, action: snooze 4h, click: open du report.
2. **Systemd unit failed** — markdown body with journal tail in code block, action: restart-unit, action: view logs (deep-link to a ttyd session?), action: silence-this-unit-for-1h.
3. **PR review requested** — title with PR title, markdown body with diffstat, action: approve via gh API, action: comment LGTM, click: open in browser.
4. **Hermes/Zeroclaw response ready** — agent-generated summary, action: continue conversation (HTTP proxy to agent), action: discard.
5. **Vault capture round-trip** — phone publishes to vault-capture-in topic, listener writes to inbox, replies on vault-capture with action: open in Obsidian (deep-link), action: edit-in-app.
6. **Battery + meeting** — meeting in 10min + battery at 18%, action: plug-in-now (silence reminder for that meeting), click: open meeting URL.

## Open Questions

- **Token rotation**: when do we rotate the webhook token? Quarterly? On phone replacement? Workflow needs to be documented.
- **Per-action throttling**: should `run-gc` be throttle-protected (max once / hour) at the receiver?
- **Confirmation step**: do destructive actions need a 2-tap confirmation (button → confirmation notification → second button)?
- **Cross-device action visibility**: if I tap "Run GC" on phone, does iPad clear the original notification? ntfy `clear=true` does this server-side but client behavior differs.
- **Async result delivery**: action runs for 10 minutes — do we deliver progress updates, or just a single completion notification?

## Pending Work

Done:
- [x] ntfy advanced features research → `docs/system/ntfy Advanced Features Reference.md`
- [x] On-host API surface map → `docs/system/On-Host API Endpoints.md`
- [x] Webhook receiver schema → `system_scripts/webhook/webhook-actions.example.yaml`
- [x] Receiver implementation → `system_scripts/webhook/server.py` (live-tested)
- [x] Library extension → `lib.sh` rewritten with `-a/-A/-D/-E/-N/--auth-token` + helpers
- [x] Sophisticated wrappers → `send-deploy.sh`, `send-disk.sh`, `send-systemd.sh` now ship action buttons
- [x] NixOS module + firewall rule → `system_nixos/notify-webhook.nix`
- [x] Token environment file wired into existing timer services → `EnvironmentFile=-%h/.config/notify/webhook-env`
- [x] Documentation → `Webhook Receiver.md`, this doc, topics.md, ntfy advanced reference

Still pending:
- [ ] NixOS deploy to start `notify-webhook.service` (chezmoi files in place, system service not yet running)
- [ ] Pair receiver with Zeroclaw — `POST http://127.0.0.1:42617/pair` and bake the bearer token into webhook-actions.yaml
- [ ] Build `vault-capture-in` subscriber (separate process: subscribes to a topic, writes to vault inbox)
- [ ] Map Hermes API surface beyond `/v1/health` (404 on every other path)
- [ ] Token rotation runbook (when phone changes / quarterly)

## Related

- `docs/system/ntfy-sh Setup.md` — server
- `docs/system/ntfy Android Setup.md` — phone
- `docs/system/Future Work — ntfy Personal Topic Prefix.md` — per-topic isolation (worth bundling with token rotation policy)
- `system_scripts/notify/lib.sh` — library to extend
- `system_scripts/notify/topics.md` — registry to add `actions` topic
