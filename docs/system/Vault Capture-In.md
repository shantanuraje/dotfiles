# Vault Capture-In — phone-to-inbox via ntfy

Subscribe-side companion to the rest of the notification stack. The
*ntfy server* is the bus; everything else publishes to it. This service
*listens* to a specific topic and writes anything it hears to the vault
inbox. Lets you "text yourself into the vault" from any tailnet device.

| | |
|---|---|
| Source | `system_scripts/vault-capture/server.py` |
| Service | `vault-capture-in.service` (user systemd) |
| Listens on | topic `vault-capture-in` (server: `beelink-ser8-desktop:8090`) |
| Writes to | `~/Documents/personal/00-Inbox/` |
| Confirms via | topic `vault-capture` (with `obsidian://` click-through) |
| Auth | none — tailnet membership is the boundary |

## What you get

```
phone (or any tailnet device)        Beelink (this service)
─────────────────────────────────    ─────────────────────────
type a thought in ntfy app
hit Send                             vault-capture-in.service
  → POST /vault-capture-in           receives the message
                                     writes ~/Documents/personal/
                                       00-Inbox/<TS> <title>.md
                                       with proper YAML frontmatter
                                     publishes confirmation
                                       to /vault-capture
                                       title: ✓ Captured: <title>
                                       click: obsidian://open?...
phone gets the confirmation
tap notification → opens the
  note in Obsidian
```

## How to use it from Android

1. **Subscribe to `vault-capture-in`** in the ntfy app:
   - tap **+** → topic name `vault-capture-in` → optional display name "📥 Capture"
2. To capture a thought:
   - open the topic in the app
   - tap the **plus / send** button (paper airplane icon)
   - **Title** = note title (becomes the file's `title:` and the start of its filename)
   - **Body** = the thought (becomes the markdown body)
   - Optional **tags** become extra YAML tags on the note
   - hit Send
3. Within 1-2 seconds a confirmation arrives on `vault-capture` topic with a tap-to-open Obsidian deep-link.

## Generated file shape

Filename: `YYYY-MM-DD HH-MM <slugified-title>.md`
under `~/Documents/personal/00-Inbox/`.

```markdown
---
title: <whatever you typed in Title>
dateCreated: 2026-04-27T20:27:47.000-04:00
dateModified: 2026-04-27T20:27:47.000-04:00
tags:
  - inbox
  - capture-in
  - <any tags you set in the publish>
source: ntfy-capture-in
archived: false
---
<the body you typed>
```

The tags `inbox` and `capture-in` are always present — gives the Inbox
Specialist agent (per `~/.config/opencode/agents/process.md`) a stable hook
for routing these later.

## Manage

```bash
# Status / logs
systemctl --user status vault-capture-in
journalctl --user -u vault-capture-in --since "1 hour ago"

# Test from another tailnet device (or this host)
curl -X POST -H "Title: Test capture" \
     -d "Hello from CLI" \
     http://beelink-ser8-desktop:8090/vault-capture-in

# Restart after editing server.py (chezmoi-managed source)
chezmoi apply
systemctl --user restart vault-capture-in

# Disable
systemctl --user disable --now vault-capture-in
```

## Auth model

Currently **open** — anyone on the tailnet can publish to
`vault-capture-in` and the message gets written to your inbox. Acceptable
because tailnet is your access boundary today.

When the personal-prefix isolation lands (see
`Future Work — ntfy Personal Topic Prefix.md`), the topic name will become
`<your-secret>-vault-capture-in` — unguessable string acts as a shared
secret. Anyone without the prefix can't publish.

For genuine multi-user later: enable ntfy auth + grant write-only access
to specific tokens. But that's overkill for the current single-user case.

## Pitfalls

- **No deduplication.** If you send the same message twice, you get two
  inbox files. The receiver doesn't track message IDs.
- **No content filtering.** Whatever you publish gets written verbatim.
  If you publish a 50KB body, you get a 50KB file in the inbox.
- **Filename collisions** if you send two messages in the same minute with
  the same title. The second overwrites the first. To fix: include
  message ID in the filename, or use seconds in the timestamp. Currently
  acceptable since it's hard to do accidentally.
- **Subscribe loop reconnects on stream break** (5s backoff) but messages
  published *during* the disconnect are still in the server cache and
  replayed via `since=0s` on reconnect — so no message loss within the
  cache window (12h).
- **No archival.** Files accumulate in `00-Inbox/` until the user (or the
  inbox-sweep cron job) processes and routes them.

## Future ideas

- **AI-enhanced capture**: route the message through `claude -p` first to
  auto-classify into Resource / Project / Area before writing. Adds a
  `suggested_route:` field to the frontmatter that the Inbox Specialist
  can pick up.
- **Action buttons on the confirmation**: "Process now" → triggers
  inbox-sweep on this single file.
- **Rich attachments**: when ntfy `attach` is set, save the attachment
  alongside the markdown file.

## Related

- `system_scripts/notify/topics.md` — registry (capture-in is here)
- `system_scripts/notify/lib.sh` — publish library used by confirmations
- `~/.config/opencode/agents/process.md` — Inbox Specialist (downstream consumer)
- `docs/system/Vault Notification System Design.md` — broader design including egress vault-* topics
- `docs/system/Webhook Receiver.md` — companion (egress vs ingress)
