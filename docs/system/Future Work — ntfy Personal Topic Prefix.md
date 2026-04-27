# Future Work — Personal Topic Prefix Isolation

**Status**: deferred. Implement when notification stack moves out of testing
phase OR when other people (bhc users, household members, future tailnet
guests) start using the ntfy server alongside you.

**Priority**: medium — meaningful security/privacy improvement, not urgent.

## Problem

The ntfy server at `beelink-ser8-desktop:8090` accepts publishes and
subscriptions from anyone on the tailnet, on any topic name. Currently:

- bhc_scraper publishes to per-user random topics like `bhc-x7Hf3kQa9pXm` —
  unguessable strings act as access secrets. Each bhc user only sees their
  own messages.
- Our system notifications publish to bare names: `power`, `errors`,
  `system-deploy`, `vault-briefing`, etc. **Any tailnet member who guesses
  these names can subscribe and read every system event.**

Today this is fine because the only people on the tailnet are:
- shantanu (me) on multiple devices
- bhc users may be added in future

But once a non-self entity joins the tailnet, our bare-name topics become
visible to them.

## Solution

Adopt the same pattern bhc_scraper uses: a personal random secret that
prefixes every topic name we own.

```
bare      → power
prefixed  → <secret>-power     e.g. qz8pxm4n-power
```

Anyone who doesn't have the exact `<secret>` value can't subscribe (because
they don't know the topic name).

## Implementation Plan

### 1. Generate the secret (one-time)

```bash
mkdir -p ~/.config/notify
chmod 700 ~/.config/notify
head -c 16 /dev/urandom | base32 | tr -d '=' | tr 'A-Z' 'a-z' > ~/.config/notify/secret
chmod 600 ~/.config/notify/secret
```

The secret is **not** stored in chezmoi (so it doesn't get committed). It's
machine-local. Each tailnet host that publishes can have its own secret, or
they can share — share if you want all hosts publishing into the same
subscription set on your phone.

### 2. Update `lib.sh` to read and prefix

```bash
# In lib.sh near the top:
NTFY_TOPIC_PREFIX="${NTFY_TOPIC_PREFIX:-$(cat ~/.config/notify/secret 2>/dev/null || echo '')}"

# In notify::send, after parsing args:
if [[ -n "$NTFY_TOPIC_PREFIX" ]]; then
    topic="${NTFY_TOPIC_PREFIX}-${topic}"
fi
```

Override via `NTFY_TOPIC_PREFIX=""` in env if you want to publish to a bare
name (e.g., a topic shared with bhc).

### 3. Update topic registry

`system_scripts/notify/topics.md` — add a section explaining the prefix and
update each topic to show its prefixed form, e.g.
`<prefix>-power`. Keep the bare name as the canonical reference; the prefix
is documentation only (never write the actual secret in topics.md).

### 4. Re-subscribe on phone

Each subscription on the ntfy app needs the new prefixed name. Quickest path:
unsubscribe from bare topics, subscribe to prefixed ones. iOS/Android workflow
is identical — the topic name field is what changes.

### 5. Document the regenerate workflow

If the secret ever leaks (e.g., posted in a shared screenshot, exfiltrated):

```bash
# Pick a new secret
head -c 16 /dev/urandom | base32 | tr -d '=' | tr 'A-Z' 'a-z' > ~/.config/notify/secret
# Re-subscribe phone with the new prefixed topic names
```

The old prefix is now dead — anyone with the old secret sees nothing.

## When to Trigger Implementation

- **As soon as** bhc_scraper goes live and starts publishing to its own
  topics over the same server (already happening).
- **Before** adding any non-self person to the tailnet.
- **As part of** a quarterly security review.
- **Immediately if** a non-self device unexpectedly appears on the tailnet.

## Why Not Just Enable Auth?

ntfy supports proper auth (`auth-default-access = "deny-all"` + per-user
tokens). Considered and rejected for now because:

- Requires NixOS module change (set `auth-default-access`, manage
  `auth-file`).
- Requires user/token management on the server (`ntfy user add`,
  `ntfy access`, `ntfy token add`).
- Requires every publisher to carry a token (in `EnvironmentFile=` for
  systemd units, in env for scripts).
- Complicates phone subscription (username + token instead of just topic
  name).
- Breaks bhc_scraper's existing flow (which uses bare topics with
  random suffixes, identical to our proposed pattern).

The prefix-secret pattern delivers the same isolation benefit at a fraction
of the operational cost. If we ever need *server-side* enforcement (e.g.,
prevent a publisher from spamming someone else's topic), then auth becomes
worthwhile.

## Estimated Effort

- One-time setup script: 5 minutes.
- `lib.sh` patch + tests: 15 minutes.
- topics.md update: 10 minutes.
- Phone re-subscription: 5 minutes per device.
- Documentation update: 15 minutes.
- **Total: ~45 minutes.**

## Related

- `system_scripts/notify/lib.sh` — where the prefix would be applied
- `system_scripts/notify/topics.md` — registry
- `~/Projects/bhc_scraper/bhc_watcher/users.py` — reference implementation of the same pattern
- `docs/system/ntfy-sh Setup.md` — server config (would need `auth-default-access` change *only* if we go the auth route instead)
