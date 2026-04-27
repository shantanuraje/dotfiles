# On-Host API Endpoint Map (for ntfy action targets)

Live-probed 2026-04-27. This document lists what's actually reachable from
where, what auth each requires, and which are viable as **direct** action
targets vs which need to be **proxied** by the planned webhook receiver.

## Listener inventory

| Service | Port | Bind | Auth | Tailnet-reachable? | Direct action target? |
|---|---|---|---|---|---|
| ntfy-sh | 8090 | `*:8090` | open | ✓ | n/a (it's the publisher) |
| **vault-api** (lawyer-vault) | 7000 | `100.116.242.38` (tailnet) | unknown — see live probe below | ✓ | ✓ |
| **bhc-watcher API** | 8765 | `100.116.242.38` (tailnet) | unknown | ✓ (bind-based, **not** in firewall allowlist) | ✓ |
| **hermes-gateway** | 8642 | `127.0.0.1` (loopback) | none | ✗ | ✗ — needs proxy |
| **zeroclaw daemon** | 42617 | `127.0.0.1` (loopback) | **paired bearer token** | ✗ | ✗ — needs proxy |
| Obsidian Electron | 8080 | `*:8080` | n/a | ✓ | n/a (Obsidian's internal renderer port — not an API surface, just leaked) |
| noVNC websockify | 6080 | tailnet (firewall) | none | ✓ | n/a |
| x11vnc | 5901 | (after fix) tailnet only | password | ✓ | n/a |
| CUPS | 631 | `127.0.0.1` | n/a | ✗ | n/a |
| VS Code internal | 43015 | `127.0.0.1` | n/a | ✗ | n/a |

## Vault-API (`100.116.242.38:7000`)

**Reachable from phone over tailnet. Returns FastAPI OpenAPI.**

```
GET /openapi.json   →   {"title":"Lawyer Vault API","version":"0.1.0"}
```

Endpoints (verified):

```
/api/ai/agents                                  # list AI agents
/api/ai/chat                                    # chat with agent
/api/dashboard/data                             # dashboard data
/api/entities/{entity_type}                     # CRUD entities
/api/entities/{entity_type}/{path}              # specific entity
/api/events                                     # event log
/api/file                                       # file ops
/api/file/{path}                                # specific file CRUD
/api/file/{path}/binary                         # binary content
/api/file/{path}/frontmatter                    # YAML frontmatter only
/api/file/{path}/move                           # rename/move file
/api/folder                                     # folder ops
/api/health                                     # health check
/api/inbox                                      # inbox operations
/api/index                                      # vault index
/api/legal/causelist/digests                    # cause list digests
/api/legal/causelist/digests/{bench}/{date_str} # specific causelist
/api/legal/regimes/check                        # regime check
/api/legal/sync-causelist                       # trigger causelist sync
/api/legal/tracked-cases                        # tracked cases list
/api/legal/tracked-cases/{case_number}/{bench}  # specific case
/api/pin/{path}                                 # pin a note
/api/search                                     # search vault
/api/settings                                   # settings
/api/star/{path}                                # star a note
/api/tasks/{path}/timer/start                   # TaskNotes timer integration!
```

**Important caveat**: this serves `~/Documents/lawyer-vault`, NOT
`~/Documents/personal/`. So for personal-vault automation, vault-api at port
7000 isn't the right target. We'd need a parallel server bound at a
different port (or extend it to multi-vault).

**Useful direct action targets** (lawyer-vault):
- `/api/legal/sync-causelist` — trigger fresh causelist sync
- `/api/file/{path}/move` — file management
- `/api/inbox` — inbox operations
- `/api/tasks/{path}/timer/start` — start TaskNotes timer

Action button example:
```
Actions: http, "Sync causelist now",
         http://100.116.242.38:7000/api/legal/sync-causelist,
         method=POST, headers.Authorization=Bearer xxx, clear=true
```

## bhc-watcher API (`100.116.242.38:8765`)

```
GET /openapi.json   →   {"title":"bhc-watcher","version":"0.2.0"}
```

```
/health                            # health check
/matches                           # match list
/me                                # current user info
/subscriptions                     # CRUD subscriptions
/subscriptions/{sub_id}            # specific subscription
/subscriptions/{sub_id}/active     # toggle active
```

Already publishes notifications via ntfy itself (per its source). Our
notifications could include action buttons that toggle subscription state:

```
Actions: http, "Pause this subscription",
         http://100.116.242.38:8765/subscriptions/SUB_ID/active,
         method=PATCH, body={"active":false}, clear=true
```

## hermes-gateway (`127.0.0.1:8642`)

**Loopback-only.** Not reachable from phone directly.

Probed paths — only one responds:
```
GET /v1/health   →   200   {"status":"ok","platform":"hermes-agent"}
```

All other common paths (`/v1/agents`, `/v1/sessions`, `/v1/messages`,
`/api/v1`, `/openapi.json`, `/docs`) return **404**. Hermes runs aiohttp
(`Server: Python/3.13 aiohttp/3.13.3`) which doesn't auto-mount OpenAPI.

This implies hermes-gateway is a private daemon for **channel integrations**
(Telegram, Discord, Slack — confirmed via the broader `nix-ai-tools`
package), not a general HTTP API. Direct messaging from notification action
buttons is **not currently feasible** without spelunking the source.

**Recommended pattern**: drive hermes via its CLI (`hermes ...`) from the
webhook receiver, not via direct HTTP.

## zeroclaw daemon (`127.0.0.1:42617`)

**Loopback-only.** Serves a Svelte/Vite SPA + a paired-auth REST API.

```
GET /api/health   →   401  {"error":"Unauthorized — pair first via POST /pair, then send Authorization: Bearer <token>"}
```

So zeroclaw has a **proper auth flow**: `POST /pair` to obtain a token, then
include `Authorization: Bearer <token>` on subsequent requests. SPA paths
(`/api/agents`, `/api/run`, etc.) return the SPA HTML on `GET` because the
SPA router falls through; the actual JSON API endpoints require the bearer
token.

**Zeroclaw configuration** (read from `~/.zeroclaw/config.toml`):
- Provider: `opencode`, model `kimi-k2.5`
- Autonomy: `supervised`
- Allowed roots: `~/.local/share/chezmoi`, `~/Documents/personal`, `~/Projects`, `~/.config`, `~/.zeroclaw`
- Allowed commands: ~150 commands including `systemctl`, `journalctl`, `nix-collect-garbage`, `claude`, `opencode`, `git`, `chezmoi`, etc.
- Max actions/hour: 60
- Max cost/day: $1.00
- E-stop: enabled

This means **zeroclaw already implements the security model we want for
action buttons**: scoped command allowlist, rate limits, cost caps, e-stop.
Rather than reinvent in our webhook receiver, the receiver can **proxy
selected agentic actions to zeroclaw** and rely on zeroclaw's enforcement.

**Recommended pattern**: webhook receiver pairs once with zeroclaw at first
boot, stores the token, and proxies "agent run X" actions to zeroclaw's
API. Direct system commands (systemctl restart, nix-gc) stay in the
receiver's own allowlist.

## opencode / claude-agent-acp

**No HTTP API.** ACP is JSON-RPC over stdio. The `opencode-obsidian` plugin
spawns the OpenCode CLI as a child process and pipes; there's no daemon
listening for HTTP requests.

**Recommended pattern**: webhook receiver action that spawns
`claude -p "..."` or `opencode run --agent <name> ...` as a subprocess,
captures output, posts a follow-up notification on completion.

## Mystery: port 8080 Electron

Resolved: it's **Obsidian's internal renderer process** (not a custom
service or API). Obsidian's Electron stack listens on this port for its own
IPC — not user-addressable, not a security issue per se but unusual to leak
to all interfaces. Worth confirming whether Obsidian respects an interface
binding or always grabs `0.0.0.0`.

## Security flags for follow-up

1. **bhc-watcher API on 8765 is bound to tailnet IP but not in
   `allowedTCPPorts` for tailscale0.** It's reachable because the tailscale0
   bind path is what matters with `--netfilter-mode=nodivert`. Either add
   `8765` to the allowlist (intentional exposure) or rebind to localhost
   (no exposure). Current state is "exposed but not declared."
2. **No auth on tailnet-exposed services.** vault-api, bhc-api, ntfy, noVNC
   are all open-on-tailnet. Acceptable threat model today (tailnet is the
   boundary), but if a tailnet device is compromised → full access. The
   personal-prefix-isolation plan partially mitigates ntfy; vault-api and
   bhc-api would benefit from the same shared-secret pattern.
3. **noVNC binding** — if bound `0.0.0.0:6080`, LAN-reachable. Should be
   tailnet-only via interface bind, similar to vault-api.
4. **Obsidian on `*:8080`** — investigate whether it can be bound to
   localhost.
5. **hermes-gateway has no auth** on loopback. Once a webhook receiver
   proxies to it, the receiver's auth is the only gate.

## Recommended webhook receiver design (refined)

Given findings above:

| Action category | Mechanism |
|---|---|
| Direct system commands (`systemctl restart x11vnc`, `nix-collect-garbage`) | Receiver's own allowlist + subprocess exec |
| AI agent runs (`opencode run --agent vault`, `claude -p ...`) | Receiver subprocess exec; relies on agents' own safety nets |
| Zeroclaw agent loop | Receiver proxies POST /api/messages or /api/prompt to `127.0.0.1:42617` after pairing |
| Hermes (channel ops) | Receiver shells out to `hermes` CLI |
| Vault-api operations | Action button can target vault-api **directly** (tailnet-reachable) — no proxy needed, just include token |
| bhc-watcher subscription toggle | Direct (tailnet-reachable) |

The receiver mostly handles `loopback proxy + subprocess exec`. Direct
tailnet services (vault-api, bhc-watcher) can be hit directly from action
buttons.

## See also

- `docs/system/Interactive Notifications — Architecture.md` — receiver design
- `docs/system/ntfy Advanced Features Reference.md` — what action buttons can do
- `system_nixos/zeroclaw.nix` — zeroclaw service definition
- `~/Projects/obsidian-vault-config/vault-api/` — vault-api source
- `~/Projects/bhc_scraper/bhc_watcher/` — bhc API source
