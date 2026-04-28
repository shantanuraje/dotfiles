# Notification System — Status, Known Issues, and Tech Debt

A consolidated map of what's running, what's flaky, what's missing, and
what should be done next. Read this before extending the system.

> **Last updated**: 2026-04-27
> **Read these first for context**: `ntfy-sh Setup.md`, `ntfy Android Setup.md`, `Webhook Receiver.md`

---

## 1. What's deployed and working

### Server side (NixOS-managed)

| Component | Status | Where |
|---|---|---|
| ntfy-sh server (port 8090, tailnet+LAN) | ✅ live | `system_nixos/machines/personal/desktop-beelink.nix` |
| notify-webhook receiver (port 9099, tailnet IP) | ✅ live | `system_nixos/notify-webhook.nix` + `system_scripts/webhook/server.py` |
| Sudoers NOPASSWD entries (7 commands) | ✅ live | declarative in `notify-webhook.nix` |
| Firewall (tailnet 8090 + 9099 + 6080, LAN-v4 5901+6080) | ✅ live | mix of `system-common.nix` + `desktop-beelink.nix` |

### User side (chezmoi + systemd --user)

| Timer / service | Cadence | Status |
|---|---|---|
| `notify-systemd-health.timer` | every 5 min | ✅ |
| `notify-host-monitors.timer` (disk + thermal + network) | every 5 min | ✅ |
| `notify-hydration.timer` | weekdays 09/11/13/15/17 | ✅ |
| `notify-posture.timer` | weekdays 10:30/12/14:30/16 | ✅ |
| `vault-capture-in.service` (long-lived subscriber) | continuous | ✅ |

### Library + wrappers

- `system_scripts/notify/lib.sh` — full ntfy feature surface (header + JSON publish modes, action mini-DSL, helpers)
- 8 send-*.sh wrappers (deploy, power, error, systemd, disk, thermal, network, personal)
- `system_scripts/notify/snooze.sh` — topic snooze utility
- 3 of the wrappers (deploy, disk, systemd) embed action buttons when token present

### Topics in production

`system-deploy`, `power`, `errors`, `system-recover`, `disk`, `temp`, `network`, `tailnet`, `actions`, `personal-hydration`, `personal-pomodoro`, `vault-capture`, `vault-capture-in`, plus `test` / `test-channel` for ad-hoc.

Reserved but **not yet wired**: `vault-briefing`, `vault-inbox`, `vault-evening`, `vault-health`, `vault-due`, `vault-overdue`, `vault-reminders`, `security`, `dev-builds`.

---

## 2. Known issues (not good, by category)

### A. Architectural seams

#### Dual deployment paths (chezmoi + NixOS)

**The problem:** different parts of the system are deployed differently:
- `system_nixos/*.nix` → `bash deploy-nixos.sh` → `nixos-rebuild switch`
- `private_dot_config/`, `system_scripts/`, `~/.config/notify/` → `chezmoi apply`

Until the deploy script auto-runs `chezmoi apply` (added 2026-04-27), it
was easy to deploy a NixOS module that referenced a chezmoi-managed
script that hadn't been pushed to disk yet, leading to "stale code
running" confusion. Mostly fixed, but the underlying split remains.

**Why it's not great:**
- Conceptually messy. Adding a new monitor requires touching both layers.
- A user who only does `chezmoi apply` doesn't realize that NixOS-managed
  services won't pick up changes to chezmoi-tracked scripts.
- Forking conventions: NixOS uses absolute Nix-store paths and immutable
  units; chezmoi uses templated user-home paths.

**What would be better:**
Pick one. Either:
- Move all systemd units into NixOS via `systemd.user.services` + `home-manager`, drop the chezmoi-managed `.service`/`.timer` files. One deploy path. Trade-off: every user-timer tweak now requires `nixos-rebuild`.
- Or move *more* into chezmoi (e.g., manage the receiver Python source via chezmoi but reference via systemd unit copied via chezmoi too — already mostly the case). Trade-off: NixOS no longer guarantees the receiver runs.

Current split is the pragmatic middle and works, but is a frequent source
of "wait, did that get applied?" friction.

#### Hostname resolution on the host itself

`beelink-ser8-desktop` resolves to `127.0.0.2` (NixOS's default
`networking.hostName` → /etc/hosts mapping) on the host itself. The
receiver binds to the *tailnet* IP (`100.116.242.38`). So:
- ✅ Phones / iPad / other tailnet hosts: MagicDNS resolves to the tailnet IP, receiver reachable.
- ❌ The Beelink itself: `curl http://beelink-ser8-desktop:9099/...` fails because 127.0.0.2 isn't where the receiver binds.

**What would be better:**
Add a hosts override (`networking.extraHosts = "100.116.242.38 beelink-ser8-desktop"`) so the host resolves its own MagicDNS name to the tailnet IP. Or always use the IP / `localhost` from the host. Currently hand-waved with "use 100.116.242.38 directly when curling from the box."

### B. Action button limitations (ntfy / Android)

#### 3-action hard limit

ntfy enforces max 3 action buttons per notification. Anything beyond is
silently dropped. This forces design choices:
- Disk warning has GC + Optimise + Snooze → no room for "View dashboard"
- Systemd failure has Restart + journal-deeplink → no room for "Silence-this-unit-1h"

**What would be better:**
Where 4+ actions are needed, generate a follow-up notification with
"More options" linking to a topic that has the next batch. Or use
`Click:` for the most common action and reserve buttons for the
secondary set.

#### `broadcast` actions are Android-only

iOS users see the button, taps do nothing. Anything we want to do on iOS
must use `view` or `http`.

#### Action button token in cached notifications

The Bearer token for the webhook receiver is embedded in the action's
`headers` field. ntfy caches notifications for 12h. Anyone who can read
the topic during that window can extract the token and replay actions.

**Mitigation today:** tailnet is the boundary, and topic names are
known but not random. **The personal-prefix isolation work** (deferred —
see `Future Work — ntfy Personal Topic Prefix.md`) makes topic names
unguessable, partly closing this gap.

**Real fix:** rotate tokens frequently (calendar reminder), or use
short-lived per-action tokens with HMAC + nonce on the receiver. Neither
implemented.

#### No free-form text input on action buttons

ntfy doesn't support "type a prompt" affordances on action buttons. So
"Ask Hermes" buttons must have the prompt baked in at publish time. This
limits the agent-interaction patterns:

- ✅ "Ask Hermes about today's deploy log" (context known at publish time)
- ❌ "Ask Hermes [type your question]" (impossible)

**Workaround:** use `vault-capture-in` as a "send arbitrary text from
phone" channel, then route those messages through Hermes via a
subscriber. Not built yet but designed.

#### `Click:` URI scheme handling diverges across platforms

`obsidian://` works on both Android and iOS *if Obsidian is installed*,
but URL-encoding for nested paths is finicky on Android (untested for
files with spaces/special chars). `intent://` is Android-only. Custom
schemes silently no-op on devices without the handler.

### C. Markdown rendering inconsistency

| Element | Web | Android | iOS |
|---|---|---|---|
| Headings, bold, lists | ✅ | ✅ | ✅ |
| Code blocks | ✅ syntax highlight | ✅ no highlight | ✅ monospace |
| Tables | ✅ | ⚠️ plain | ❌ falls back to text |
| Images | ✅ | varies by version | varies |

**Implication:** when designing notification bodies, target Android +
iOS lowest common denominator. Don't depend on tables or syntax-highlighted
code blocks for critical info. Web UI gets the rich version.

### D. Operational gaps

#### Token rotation is manual and undocumented

`~/.config/notify/webhook-token` is generated once. There's no rotation
schedule, no runbook, and no audit trail. When the phone changes (lost,
upgraded, factory-reset) the token sits in any cached notifications + on
the new phone's app config — and the old token isn't invalidated.

**What would be better:** quarterly cron that:
1. Generates a new token
2. Rewrites `~/.config/notify/webhook-token`
3. Restarts notify-webhook (picks up new token)
4. Publishes a notification "Token rotated — re-subscribe new actions"

Not built.

#### No metrics / observability

To know if a monitor is firing, you have to read journal logs by hand.
No dashboards. No "how many notifications did we send today" view.

**What would help:**
- A simple `notify_count{topic=...,priority=...}` Prometheus exporter.
- A weekly "notification digest" that summarizes what fired.
- Audit log analysis script (the data is there in
  `~/.local/state/notify-webhook/audit.log` — just no consumer).

#### Audit log doesn't include the originating notification

When a webhook action is dispatched, we log
`{action, params, remote, exit_code}` — but not which notification's
button was tapped. So if you later wonder "who triggered run-gc at 3am",
you can't trace back to the originating notification.

**Fix:** include `X-Notification-ID` header in the action POST and log
it. Notification IDs come from ntfy's response on publish. Not done.

#### No retry on follow-up publish failure

If the receiver runs an action successfully but the follow-up publish to
the `actions` topic fails (e.g., ntfy server briefly down), the result
is silently lost. The user has no way to know the action ran.

**Fix:** retry with exponential backoff, or write the follow-up to a
local queue and drain on next successful publish.

#### Webhook receiver doesn't propagate signal to dispatched commands

If you `systemctl stop notify-webhook` while a `claude -p` is mid-run
(taking 60+ seconds), the subprocess gets killed with no follow-up. User
sees no result.

**Fix:** on shutdown, wait for in-flight dispatches OR publish an
"action interrupted" message to `actions` topic before exit.

### E. Specific known bugs / oddities

#### `Documentation=file:///...` URLs in systemd units with spaces

journalctl complains: `Invalid URL, ignoring: Capture-In.md`. The
`Documentation=` field doesn't tolerate spaces or unicode in the path
without URL-encoding. Currently cosmetic — the unit still works.

#### `du` on `/` runs forever without `-x` flag

Hit and fixed in `disk-health.sh` — added `-x` (one filesystem only) and
`timeout 10`. Old runs (before the fix) consumed 1+ minute of CPU and
hundreds of MB of memory on a single timer fire. Logged as a journal
warning entry — kept as a reminder.

#### Battery monitor critical alert respawn on every poll

The original local `notify-send` for critical battery fires on every
30-second poll cycle (no throttle). I added 5-min throttle for the *ntfy*
publish but kept the local notify-send unthrottled. Acceptable for local
desktop popups (they self-dismiss) but a re-design opportunity.

#### `vault-capture-in` writes file with same name on duplicate publish

If you tap "Send" twice within the same minute with the same title, the
second message overwrites the first. No deduplication. Mitigation: keep
distinct titles, or include seconds in filename, or use message-id.

#### No content filtering / sanitization on capture

Anyone on the tailnet can publish a 50KB body to `vault-capture-in` and
it gets written verbatim to the inbox. Acceptable for single-user
tailnet; risk grows with each non-self device added.

### F. Designed-but-not-built (vault automation)

The CLAUDE.md "Scheduled Vault Maintenance Tasks" section defines 7
tasks (morning briefing, work check, inbox sweep, evening review, weekly
inbox reminder, weekly health, monthly orphan/audit). **None are
actually wired.** The systemd units don't exist. Topics are reserved
(`vault-briefing`, etc.) but no publishers.

To wire them, we need to:
1. Decide on log/state location (CLAUDE.md is internally inconsistent).
2. Build wrapper scripts that run `claude -p "..."` and publish summaries.
3. Create `claude-vault-*.{service,timer}` units.
4. Add `OnFailure=` → errors topic.
5. Test each task end-to-end on a real day.

Estimated effort: full session of work.

### G. Stalled / blocked

#### Zeroclaw pairing

`zeroclaw-prompt` action exists in the allowlist but its `Authorization`
header is empty. Pairing requires:
1. Open the Zeroclaw web UI in a browser on the host (`http://127.0.0.1:42617`).
2. Get the displayed pairing code.
3. POST to `/pair` with the code.
4. Store the returned token.
5. Update `webhook-actions.yaml` with the bearer token.
6. SIGHUP / restart the receiver.

Multi-step, requires browser access on the host. Documented as a TODO.

#### Hermes deeper integration

We have `hermes-chat` (CLI fork-per-prompt) working, but Hermes also has:
- `hermes webhook subscribe` — could create *Hermes-side* webhooks where
  Hermes turns incoming events into agent prompts. Not enabled.
- Telegram/Discord/Slack channels via `hermes gateway` — could route
  vault notifications through these channels. Not configured.
- MCP support (`hermes mcp`) — could expose Hermes as an MCP server, or
  consume MCP servers from within Hermes runs. Not explored.

Each is a substantial project on its own.

---

## 3. Tech debt (things to fix sooner rather than later)

In rough priority order:

1. **Fix follow-up publish retry** — silent failures on transient ntfy unavailability.
2. **Token rotation runbook + script** — quarterly. Document exactly what to do when phone changes.
3. **Personal-prefix topic isolation** — the deferred work in `Future Work — ntfy Personal Topic Prefix.md`. Should land *before* anyone non-self joins the tailnet.
4. **Notification-ID linking in audit log** — for forensic clarity on who triggered what.
5. **Hostname resolution from the host** — `extraHosts` override so local curl works by hostname.
6. **`du` timeout on disk-health.sh** — already fixed; add a regression test.
7. **vault-capture-in dedup** — message-ID or seconds in filename so double-taps don't lose data.
8. **Batch metrics dashboard** — or at minimum a daily/weekly `notify_summary.sh` script.
9. **Wire the CLAUDE.md vault timers** — design exists; implementation doesn't. Big ticket.
10. **Zeroclaw pairing** — quick win once you do the browser dance.

---

## 4. Improvements / nice-to-haves

In rough order of value:

| Idea | Effort | Value |
|---|---|---|
| `notify summary` CLI: digest of last N hours of notifications | small | high (visibility) |
| Vault-capture-in attachments support (save image attachments alongside .md) | small | medium |
| AI-enhanced capture (route through `claude -p` to auto-classify, add `suggested_route` to YAML) | medium | high |
| Timer-fired `claude -p` morning briefing posting to `vault-briefing` (the tier 2 vault work) | large | high |
| Action: "Process this inbox item" on capture confirmations (single-file inbox-sweep) | small | medium |
| Hermes Telegram channel — a portable comms thread to your agent via Telegram bot | medium | high (when away from tailnet) |
| Hermes webhook subscriptions (e.g. Stripe / GitHub events → Hermes agent loop) | medium | medium |
| Per-topic priority threshold + DND windows configured server-side via ntfy auth ACLs | medium | medium |
| Cron job: nightly `nix-collect-garbage` if disk > 80%, with summary on `actions` | small | medium |
| Failed-sudo and ssh attempt watcher → `security` topic | small | high (security visibility) |
| `dev-builds` watcher: a wrapper that publishes when long-running commands finish (`done <command>`) | small | medium |
| Real-time pomodoro state machine (start, end, break — currently just calendar timers) | medium | low |

---

## 5. Lessons learned (architectural)

### a. Topic names *as* access control are surprisingly effective

When the tailnet is your boundary, an unguessable topic name (`bhc-x7Hf3kQa9pXm`) works as well as token auth for most threats. bhc_scraper got this right; we should follow when isolation matters.

### b. The 3-action limit shapes design more than expected

Designing notifications with 3 actions in mind forces hierarchical thinking: which 3 things do you actually want a tap-away? The exercise of cutting from 5 candidates to 3 reveals what's really important.

### c. Action mini-DSL escape hell is a thing

We hit two parsing bugs (`:` separator broke URLs, `,` kv separator broke JSON bodies). Pipe + semicolon worked. The lesson: when designing a tiny DSL, pick separators that don't appear in the data. URLs contain `:`, JSON contains `,`. Pipe is the usual answer.

### d. Don't put emoji in HTTP headers (Python urllib)

Python's `urllib` defaults to latin-1 for header values. Any UTF-8 character in a `Title:` header crashes the publish. Use ntfy's JSON publish endpoint when titles can be Unicode — it puts them in the JSON body which is UTF-8 native. Bug in earlier `_publish` cost us 30 minutes of "why aren't follow-ups arriving."

### e. NixOS rebuild only restarts services whose `.nix` changed

Editing a chezmoi-managed Python script doesn't trigger a service restart, even after `nixos-rebuild switch`. The deploy script now explicitly restarts a known set of long-lived services, but this is the kind of thing every change needs to consider. **Conceptual model**: NixOS owns *service definitions*, chezmoi owns *script bodies*; rebuild reconciles definitions, never bodies.

### f. Dual deployment paths *will* drift

Even with auto-`chezmoi apply` in the deploy script, the temptation is to "edit and reload" via `chezmoi apply` directly without a rebuild. This is fine 90% of the time, but the 10% where it isn't (e.g., editing `notify-webhook.nix`'s sudoers list in chezmoi but never deploying) leaves the system in a state where the source claims one thing and the running config claims another.

**What would help:** a pre-commit hook that warns when `chezmoi apply` was run without a corresponding `nixos-rebuild` (or vice versa), based on file mtimes.

### g. The "pre-baked context" pattern works for AI-action buttons

Since action buttons can't take free-form input, agent-interaction notifications work by *capturing the relevant context at notification-publish time* and embedding it in the action body. E.g., a deploy-failure notification publishes with an "Ask Hermes to diagnose" button that has the journal tail as the prompt. This is more useful than it initially seems — most agent questions in this stack are about *specific failures* whose context is naturally available where the failure originates.

---

## 6. What I would do differently if starting over

1. **Single deployment path from day 1** — pick chezmoi or NixOS for systemd units, not both.
2. **JSON publish from the start** — header mode is faster but adds the latin-1 emoji landmine.
3. **Personal-prefix topic isolation enabled from day 1** — small effort upfront, big win later.
4. **Webhook receiver written in Go or Rust** — Python's `http.server` is fine but lacks ergonomic auth/middleware. Receiver complexity is going to grow; starting with a real HTTP framework would pay back.
5. **One NixOS module per concern** instead of stuffing services into desktop-beelink.nix — separate `vnc.nix`, `notify.nix`, `webhook.nix` etc.
6. **Write the topics registry as a generated file** instead of hand-maintained markdown. Single source of truth → topics.yaml → generates topics.md, and validates that publishers use registered topics.
7. **Explicit `Authorization` header always-on** for `vault-capture-in` so we don't have to retrofit auth when isolation lands.

---

## 7. How to extend safely

If you're adding a new notification type:

1. **Pick a topic name**. Add it to `system_scripts/notify/topics.md` with priority + cadence + who-publishes-it.
2. **Build the publisher** — either a wrapper in `system_scripts/notify/send-<domain>.sh` (for one-shot events) or a monitor in `system_scripts/monitor/<thing>-health.sh` (for state transitions).
3. **If transition-based**, persist state in `~/.local/state/<thing>-health/` so re-runs don't spam.
4. **If actionable**, add the action to `~/.config/notify/webhook-actions.yaml` AND restart the receiver via deploy-nixos.sh (auto-restart now does this).
5. **If timer-fired**, add the `.service` + `.timer` to `private_dot_config/systemd/user/` and `chezmoi apply && systemctl --user daemon-reload && systemctl --user enable --now <name>.timer`.
6. **Document it** — extend `topics.md`, and add a section to the relevant per-domain doc.
7. **Subscribe on the phone** to verify end-to-end.

If you're adding a new webhook action:

1. Add to `~/.config/notify/webhook-actions.yaml` with a unique `name`.
2. Decide `command` (subprocess) vs `http_proxy` (forward to localhost service).
3. Pre-declare param slots as `{{params.X}}` placeholders in argv. Never concat into shell strings.
4. Set `timeout_s` aggressively — defaults aren't generous.
5. Choose a `follow_up_topic` (`actions` is the catch-all).
6. If sudo'd, **add a corresponding NOPASSWD entry to `notify-webhook.nix`** before the next deploy, otherwise the action will fail silently with "sudo: a password is required".
7. Restart receiver: `bash deploy-nixos.sh` does it; `sudo systemctl restart notify-webhook` is the manual one.

---

## 8. Related docs (read these for specifics)

- `docs/system/ntfy-sh Setup.md` — server config
- `docs/system/ntfy Android Setup.md` — phone setup, subscription guide
- `docs/system/ntfy Advanced Features Reference.md` — header reference, capability matrix
- `docs/system/On-Host API Endpoints.md` — what action buttons can target
- `docs/system/Interactive Notifications — Architecture.md` — webhook receiver design + threat model
- `docs/system/Webhook Receiver.md` — receiver operations, action authoring
- `docs/system/Host Monitors.md` — disk/thermal/network watchers
- `docs/system/Systemd Health Monitor.md` — systemd unit watcher
- `docs/system/Vault Capture-In.md` — phone → inbox round-trip
- `docs/system/Vault Notification System Design.md` — designed-but-not-built vault automation
- `docs/system/Future Work — ntfy Personal Topic Prefix.md` — deferred isolation work
- `system_scripts/notify/topics.md` — live topic registry
