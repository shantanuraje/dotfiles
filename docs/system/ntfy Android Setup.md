# ntfy on Android — Subscribing to Self-Hosted Topics

This guide covers subscribing your Android phone to the self-hosted ntfy
server (`http://beelink-ser8-desktop:8090`) over Tailscale.

> **TL;DR**: Install the ntfy app, set the default server to your tailnet
> hostname, and add subscriptions for the topics you care about. Make sure
> Tailscale stays connected on the phone — that's the *only* network path
> between your phone and the server.

## Prerequisites

| Requirement | How to check |
|---|---|
| Android phone is on **your tailnet** | Open Tailscale app → green "Connected" indicator |
| Phone can reach the server | Browser → `http://beelink-ser8-desktop:8090` shows the ntfy web UI |
| Server topic registry available | `docs/system/notify topics.md` lists everything publishable |

If the browser test fails, fix Tailscale first — there is no internet path to
this server (by design).

## Install the App

1. Play Store → search **ntfy**.
2. Install **"ntfy"** by Philipp C. Heckel (the official app — green icon).
3. Open it. Skip any "subscribe to ntfy.sh" prompts.

iOS users: install **"ntfy"** from the App Store instead. Configuration steps
below are the same; UI labels differ slightly.

## Point the App at Your Self-Hosted Server

This sets the *default* server for new subscriptions so you don't have to
type the URL each time.

1. In the app: **Settings** (gear icon, top-right) → scroll to **Default
   server**.
2. Enter: `http://beelink-ser8-desktop:8090`
   - Use **`http://`** (not https). The server has no TLS — tailnet WireGuard
     is the encryption layer.
   - Use the MagicDNS hostname (`beelink-ser8-desktop`), not the raw tailnet
     IP. Hostname survives if the IP ever changes; the IP doesn't.
3. (Optional) Set **Connection protocol** → "WebSockets" for lower battery
   use vs default polling. Recommended.
4. Leave **UnifiedPush** off unless you specifically use it for other apps.

## Subscribe to Topics

> Topics don't need to be created in advance. Subscribing to a name that has
> never been published to just means you'll be the first listener when it
> eventually gets a message.

### Per-Subscription Workflow

1. Tap the **+** floating action button on the main screen.
2. **Topic name**: type the topic (e.g. `power`, `errors`, `system-deploy`).
3. **Use another server?** → leave **off**. The default server you configured
   above will be used.
4. *(Optional)* Tap **▾ Show advanced** to set per-subscription:
   - **Display name**: friendly label (e.g. "🔋 Battery") — replaces topic
     name in the UI.
   - **Auto-delete messages**: e.g. "1 day" for noisy topics like `vault-inbox`.
   - **Insistent ringtone for max priority**: ON for `errors`, `security`,
     `power` so urgent alerts override DND.
   - **Dedicated channel**: ON. Lets Android route this topic to its own
     notification category, so you can mute/customize per topic in Android
     Settings.
5. **Subscribe**.

### Recommended Phone Subscription Set

Phones are best for *actionable* alerts. Subscribe to topics that warrant
interrupting you:

| Topic | Display name | Notes |
|---|---|---|
| `errors` | 💥 Errors | Insistent ringtone ON. Bypasses DND. |
| `security` | 🔐 Security | Insistent ringtone ON. |
| `power` | 🔋 Power | Critical alerts wake the phone. |
| `system-deploy` | ⚙️ Deploy | Routine — no insistent ringtone. |
| `calendar` | 📅 Calendar | Click-through opens meeting URL. |
| `network` | 🌐 Network | WAN drops, public IP changes. |

Skip these on the phone (route to iPad / web UI instead — they're
informational, not interrupt-worthy):
- `vault-*` (use iPad)
- `personal-*` (use whichever device hosts the relevant timer)
- `system-flake`, `system-gc`, `dev-watch` (low signal — browser is fine)

## Auto-Discovery — How It Actually Works

Short answer: **ntfy doesn't have true auto-discovery.** Topics are routed
purely by name; the server keeps no list of "valid" topics. Your client has
to know the names to subscribe.

What you do get:

1. **The web UI shows topics with recent traffic.** Open
   `http://beelink-ser8-desktop:8090` in any browser on the tailnet. The
   left sidebar lists topics that the *browser* has subscribed to in *that*
   browser session — not a global list. If you publish to a new topic and
   then refresh the web UI, it doesn't appear automatically.
2. **The cache exposes recent messages by topic via the API.** While the
   `cache-duration` window (12 hours, in our config) is open, you can query
   `GET /<topic>/json?poll=1&since=12h` to see recent messages on a topic
   you already know about. Still no enumeration of unknown topics.
3. **The topic registry in this repo is the source of truth.** See
   `system_scripts/notify/topics.md`. When new topics are added there, also
   subscribe in the app.

### Why This Is Intentional

ntfy is "topic = capability". If the server enumerated topics, anyone with
network access could discover and read every channel. By making topics
unguessable strings (when you want privacy), the topic name itself acts as
a shared secret. We don't rely on this — tailnet is our access boundary —
but it's why the protocol works the way it does.

### Pragmatic "Discovery" Workflow

If you forget which topics exist:

```bash
# From any tailnet host
cat ~/.local/share/chezmoi/system_scripts/notify/topics.md | grep '^| `'
```

Or open the topic registry in Obsidian:
`docs/system/ntfy Setup.md` (linked from there).

When new topics are added, the registry is updated; check it as part of
weekly system review.

## Verify End-to-End

Run this from your laptop (or the Beelink itself):

```bash
ntfy publish http://beelink-ser8-desktop:8090/test \
  -t test_tube,sparkles \
  -p high \
  -m "Hello from $(hostname) at $(date +%H:%M:%S)"
```

The phone should buzz within 1-3 seconds. If it doesn't:

1. **Check Tailscale on the phone** — must be Connected.
2. **Confirm subscription topic** matches `test` exactly.
3. **Confirm default server URL** in Settings is correct (typo in
   `beelink-ser8-desktop` or wrong port is the most common issue).
4. **Try the web UI from the phone's browser**:
   `http://beelink-ser8-desktop:8090/test` → click **Subscribe** in the
   bottom-right. If web UI works but the app doesn't, the app's connection
   to the server is broken — kill and restart the app.
5. **Check Android battery optimizations**: Settings → Apps → ntfy →
   Battery → **Unrestricted**. Otherwise Android may kill the persistent
   connection in the background.

## Battery and Connectivity

The ntfy app maintains a persistent connection to the server when foreground
or in **WebSockets** mode (recommended above). Approximate impact:

- WebSockets mode + tailnet: **<1% per day** in our testing.
- Polling mode: more battery drain (default 1-min poll), but works on
  networks where WebSockets is blocked. Not relevant here since we control
  both sides.
- If Tailscale drops on the phone (cellular handoff, airplane mode), the
  ntfy app reconnects automatically when the tailnet returns. **Messages
  published while disconnected are delivered on reconnect** (within the 12 h
  cache window).

## Topic Hygiene

- **Unsubscribe** from topics you stop caring about — they keep a notification
  channel registered with Android, which clutters Settings.
- **Mute** rather than unsubscribe if you want to keep history but stop
  interrupts. App: long-press topic → mute icon.
- **Clear all messages** for a topic: long-press topic → trash icon. Doesn't
  unsubscribe.

## Hardening Path (Future)

If we ever enable per-topic auth (`auth-default-access = "deny-all"` +
`ntfy user add`):

1. Generate a long-lived token: `sudo ntfy token add <user>`.
2. App: long-press subscription → **Edit** → enter username + token (or
   token alone, depending on access mode).
3. Tokens are stored encrypted by the OS keychain. Can be revoked
   server-side at any time without touching the phone.

Until that's enabled, no auth is configured. Tailnet membership is the only
gate.

## See Also

- `docs/system/ntfy Setup.md` — server-side configuration
- `system_scripts/notify/topics.md` — current topic registry
- `system_scripts/notify/lib.sh` — publish helpers used by NixOS scripts
- `docs/system/2026-03-09 Tailscale VPN Setup.md` — tailnet itself
