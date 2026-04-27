# ntfy Advanced Features — Reference

Distilled from research agent investigation 2026-04-27. The full agent
report is preserved at the bottom; this top section is the operational
reference.

## Server-side capabilities (verified live)

| Setting | Our value | Default | Notes |
|---|---|---|---|
| `attachment-cache-dir` | `/var/lib/ntfy-sh/attachments` | — | |
| `cache-duration` | 12h | 12h | Notification cached for delivery to late subscribers |
| `attachment-file-size-limit` | 15M (default) | 15M | Per file |
| `attachment-total-size-limit` | 5G (default) | 5G | Per visitor |
| `attachment-expiry-duration` | 3h (default) | 3h | **Critical**: attachments outlived by their notification |
| `message-delay-limit` | 3 days (default) | 3 days | Max `Delay:` |
| Health endpoint | `/v1/health` | — | Returns `{"healthy":true}` |

## Headers — cheat sheet

```
Title:       <text>                           # title line, supports emoji
Priority:    1..5 | min|low|default|high|urgent
Tags:        <slug>,<slug>...                 # emoji slugs render as emojis
Click:       <url>                            # tap action (https/obsidian/intent/mailto/...)
Icon:        <url>                            # 64-128px PNG/JPG
Attach:      <url>                            # server fetches & re-serves
Filename:    <name>                           # display name for attachment / for body upload
Markdown:    yes                              # body rendered as GFM (web full, Android good, iOS limited)
Delay:       <duration|time>                  # 30min / 9am / 2026-04-27T08:00 / unix
Cache:       no                               # don't cache; deliver only to live subscribers
Email:       <addr>                           # forward as email (server-side smtp config required)
Actions:     <type>,<label>,<key>=<value>; ...   # see below — max 3 actions
Authorization: Bearer <token>                 # for publish, when auth enabled
```

## Action buttons (max 3)

Three types: `view` (open URL), `http` (POST/GET back to a URL from the
device), `broadcast` (Android Intent only).

### Shorthand header

```
Actions: <type>, <label>, <key1>=<value1>, <key2>=<value2>; <next action>; ...
```

### JSON publish (cleaner for actions/attachments/delay)

```bash
curl http://beelink-ser8-desktop:8090/ -H "Content-Type: application/json" -d '{
  "topic": "errors",
  "title": "Disk full",
  "message": "/home is at 92%",
  "priority": 4,
  "tags": ["warning","floppy_disk"],
  "markdown": true,
  "actions": [
    {"action":"view","label":"Open dashboard","url":"https://grafana.local/","clear":true},
    {"action":"http","label":"Run GC","url":"http://beelink:9099/action/run-gc",
     "method":"POST","headers":{"Authorization":"Bearer xyz"},
     "body":"{\"reason\":\"disk-full\"}","clear":true},
    {"action":"broadcast","label":"Snooze 4h",
     "intent":"net.dinglisch.android.tasker.ACTION_TASK",
     "extras":{"task":"NtfySnooze4h"},"clear":false}
  ]
}'
```

### Action types

| Type | Where it runs | iOS | Android | Web | Notes |
|---|---|---|---|---|---|
| `view` | client device opens URL | ✓ | ✓ | ✓ | Universal. Supports custom URI schemes if app installed. |
| `http` | client device makes HTTP request | ✓ | ✓ | ✓ | Method + headers + body. **Token in headers visible to anyone subscribed to the topic** — treat as proof-of-receipt, not auth. |
| `broadcast` | Android Intent fires | ✗ (silent no-op) | ✓ | ✗ | Use only for Tasker/Macrodroid handoff; iOS ignores. |

### Critical limits

- **Max 3 actions per notification.** Hard cap. 4th is dropped.
- **`broadcast` extras can only be strings.** No nested maps, no booleans.
- **`http` action runs on the device** — URL must be reachable from there. Tailnet hostnames work (phone is on tailnet).
- **`clear=true`** removes from tray after successful tap; doesn't delete from server cache.

## Click action URI schemes

| Scheme | Android | iOS | Web | Notes |
|---|---|---|---|---|
| `https://` `http://` | ✓ | ✓ | ✓ | |
| `obsidian://open?vault=...&file=...` | ✓ if installed | ✓ if installed | Browser-handled | URL-encode nested paths carefully on Android |
| `intent://...` | ✓ | ✗ | ✗ | Android-specific deep intent |
| `mailto:` `tel:` `sms:` `geo:` | ✓ | ✓ (geo: Apple Maps) | ✓ | |
| Custom schemes (`tasker://`, `kdeconnect://`) | ✓ if installed | iOS needs `LSApplicationQueriesSchemes` | Browser-handled | |

## Markdown rendering — what works on each client

| Element | Web | Android (v1.16+) | iOS |
|---|---|---|---|
| Headings | ✓ | ✓ | partial |
| Bold / italic | ✓ | ✓ | ✓ |
| Lists (ordered/unordered/nested) | ✓ | ✓ | ✓ |
| Inline code | ✓ | ✓ | ✓ (monospace) |
| Code blocks (with syntax highlighting) | ✓ syntax | ✓ no highlight | ✓ monospace |
| Tables | ✓ | ✓ but plain | text fallback |
| Blockquotes | ✓ | ✓ | ✓ |
| Links | ✓ | ✓ | ✓ |
| Images `![](url)` | ✓ | depends on version | depends |
| Strikethrough `~~text~~` | ✓ | ✓ | partial |
| Wikilinks `[[Note]]` | **not processed** | not processed | not processed |

For **Obsidian-clickable links**, use:
`[Note](obsidian://open?vault=personal&file=path/to/note.md)`

## Subscriber-side filtering (URL params)

```
GET /<topic>/json?priority=4,5&tags=warning&since=12h
GET /<topic>/sse?title=disk
GET /<topic>/ws?message=fail
```

- `priority=N,M` — only listed priorities
- `tags=foo,bar` — must contain ALL listed tags
- `title=substring` — title contains
- `message=substring` — message contains
- `since=12h` / `since=<msg-id>` / `since=<unix-ts>` — replay window

Filtering is client-side; server still ships every message.

## Authentication (when we enable it later)

```bash
# Server-side
sudo ntfy user add deploy-bot              # password
sudo ntfy access deploy-bot system-deploy write-only
sudo ntfy token add deploy-bot             # → tk_xxxxx
# Per-topic ACL: read-only, write-only, read-write, deny

# Publish with token
curl -H "Authorization: Bearer tk_xxxxx" -d "msg" http://server/topic

# Browser fallback (when headers blocked)
http://server/topic?auth=<base64(Bearer tk_xxxxx)>
```

Tokens don't auto-renew. Rotation is manual: new token → update phone subscription credentials → revoke old.

## Inbound integration (subscribe pattern)

ntfy has **no built-in outbound webhooks**. To bridge to other systems,
write a small subscriber:

```python
import requests, json
with requests.get("http://beelink:8090/vault-capture-in/json", stream=True) as r:
    for line in r.iter_lines():
        if not line: continue
        msg = json.loads(line)
        if msg.get("event") != "message": continue
        # write to vault inbox
        with open(f"/path/to/inbox/{msg['id']}.md", "w") as f:
            f.write(f"---\ntitle: {msg.get('title','(captured)')}\n---\n\n{msg['message']}")
```

Run as a systemd user service. Auto-reconnects on transient failure if
written defensively.

## Pitfalls (operational)

1. **3 action limit.** Design notifications around it.
2. **`broadcast` is Android-only.** iOS users see the button, tap does nothing.
3. **`http` action token leaks** to anyone subscribed to the topic. Use it as **identity** (phone authenticated to ntfy), not as **authority** (server still re-validates).
4. **Markdown inconsistency** — iOS renders less than Android renders less than web. Don't depend on tables/code-blocks for critical info on iOS.
5. **`Click:` URI schemes diverge** — `intent://` Android-only, custom schemes need app installed.
6. **Token expiry is silent** — Android stops receiving with no UI feedback. Long-lived tokens behind tailnet are pragmatic.
7. **Attachments expire in 3h by default** — outlive their own notification. Increase `attachment-expiry-duration` if needed, or accept time-bound delivery.
8. **No server-side outbound webhooks.** Bridge with subscriber processes.
9. **No phone-call routing on self-hosted** (`Call:` is paid hosted-only).
10. **Web app doesn't auto-discover topics.** Topic registry in dotfiles is the source of truth.
11. **Insistent ringtone for max priority is per-subscription on Android** — off by default. Configure per topic in the app.

## See also

- `system_scripts/notify/lib.sh` — to be extended for actions/attachments/delay
- `system_scripts/notify/topics.md` — topic registry
- `docs/system/Interactive Notifications — Architecture.md` — system design
- `docs/system/On-Host API Endpoints.md` — what we can target with `http` actions
