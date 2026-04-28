#!/usr/bin/env python3
"""
vault-capture-in — subscribe to ntfy topic, write incoming messages to vault inbox.

Subscribes to `vault-capture-in` topic on the ntfy server. Each message
arriving on that topic is written as a markdown file with YAML frontmatter
under ~/Documents/personal/00-Inbox/. A confirmation is published on
`vault-capture` so the user sees the round-trip.

Workflow:
  1. From phone, open ntfy app → vault-capture-in topic → tap "Send"
  2. Type a thought (Title is the message title; body is the message body)
  3. Phone POSTs to ntfy
  4. This subscriber receives, writes to inbox, and echoes confirmation
  5. Phone receives the "✓ Captured" notification on vault-capture topic

Filename format: `YYYY-MM-DD HH-MM <slugified-title>.md`
Frontmatter: title, dateCreated (ISO 8601 with -04:00), tags, source, archived

Designed to run as a long-lived systemd user service. Uses ntfy's
HTTP-stream subscription (newline-delimited JSON) which auto-reconnects.

Auth: none, currently. Tailnet membership is the boundary. To prevent abuse
from other tailnet devices, the topic name itself is the access control —
keep it unguessable when personal-prefix isolation lands (see "Future Work
— ntfy Personal Topic Prefix.md").
"""

from __future__ import annotations

import json
import logging
import os
import re
import sys
import time
import urllib.request
from datetime import datetime, timezone, timedelta
from pathlib import Path
from typing import Any

# ── Config ────────────────────────────────────────────────────────────────────
NTFY_BASE = os.environ.get("NTFY_BASE_URL", "http://beelink-ser8-desktop:8090")
LISTEN_TOPIC = os.environ.get("VAULT_CAPTURE_IN_TOPIC", "vault-capture-in")
CONFIRM_TOPIC = os.environ.get("VAULT_CAPTURE_TOPIC", "vault-capture")
VAULT_ROOT = Path(os.environ.get("VAULT_ROOT", str(Path.home() / "Documents" / "personal")))
INBOX_DIR = VAULT_ROOT / "00-Inbox"
TZ_OFFSET = "-04:00"  # matches the rest of the vault's frontmatter

log = logging.getLogger("vault-capture")


def _now_iso() -> str:
    """Return current time as ISO 8601 with the vault's standard offset."""
    tz = timezone(timedelta(hours=-4))
    return datetime.now(tz).strftime("%Y-%m-%dT%H:%M:%S.000") + TZ_OFFSET


def _slugify(s: str, maxlen: int = 60) -> str:
    """Turn an arbitrary string into a safe filename fragment."""
    s = re.sub(r"[^\w\s.-]", "", s, flags=re.UNICODE)
    s = re.sub(r"\s+", " ", s).strip()
    return s[:maxlen] or "untitled"


def _write_inbox_file(title: str, body: str, tags: list[str]) -> Path:
    """Write the captured thought to the inbox and return the path."""
    INBOX_DIR.mkdir(parents=True, exist_ok=True)
    now = datetime.now(timezone(timedelta(hours=-4)))
    fname = f"{now.strftime('%Y-%m-%d %H-%M')} {_slugify(title)}.md"
    path = INBOX_DIR / fname

    yaml_lines = [
        "---",
        f"title: {title}",
        f"dateCreated: {_now_iso()}",
        f"dateModified: {_now_iso()}",
        "tags:",
        "  - inbox",
        "  - capture-in",
    ]
    for tag in tags:
        if tag and tag not in ("inbox", "capture-in"):
            yaml_lines.append(f"  - {tag}")
    yaml_lines.append("source: ntfy-capture-in")
    yaml_lines.append("archived: false")
    yaml_lines.append("---")
    yaml_lines.append("")

    path.write_text("\n".join(yaml_lines) + body.strip() + "\n")
    return path


def _publish_confirmation(title: str, message: str, click_url: str) -> None:
    """Publish a capture-confirmation back to the user."""
    payload = {
        "topic": CONFIRM_TOPIC,
        "title": title,
        "message": message,
        "priority": 2,  # low
        "tags": ["white_check_mark", "memo"],
        "click": click_url,
        "markdown": True,
    }
    body = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        f"{NTFY_BASE}/",
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=5) as r:
            r.read()
    except Exception as e:
        log.warning("confirmation publish failed: %s", e)


def _handle_message(msg: dict[str, Any]) -> None:
    """Process one ntfy message. Skip non-message events (open/keepalive)."""
    if msg.get("event") != "message":
        return

    title = msg.get("title", "").strip() or "Captured thought"
    body = msg.get("message", "").strip()
    if not body and not msg.get("title"):
        log.info("skipping empty message %s", msg.get("id"))
        return

    tags = msg.get("tags") or []

    try:
        path = _write_inbox_file(title, body, tags)
    except Exception as e:
        log.exception("failed to write inbox file: %s", e)
        return

    log.info("captured to %s", path)

    # obsidian:// click-through deep-link.
    rel = path.relative_to(VAULT_ROOT)
    click_url = f"obsidian://open?vault=personal&file={rel.as_posix()}"

    _publish_confirmation(
        title=f"✓ Captured: {title[:60]}",
        message=f"Saved to `{rel.as_posix()}` — tap to open in Obsidian.",
        click_url=click_url,
    )


def _stream_messages() -> None:
    """Subscribe to the topic and dispatch messages indefinitely."""
    url = f"{NTFY_BASE}/{LISTEN_TOPIC}/json?since=0s"
    log.info("subscribing to %s", url)

    while True:
        try:
            with urllib.request.urlopen(url, timeout=None) as resp:
                for raw in resp:
                    raw = raw.strip()
                    if not raw:
                        continue
                    try:
                        msg = json.loads(raw)
                    except Exception:
                        log.warning("bad json line: %r", raw[:200])
                        continue
                    _handle_message(msg)
        except Exception as e:
            log.warning("stream broke: %s — reconnecting in 5s", e)
            time.sleep(5)


def main() -> None:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    )
    if not VAULT_ROOT.is_dir():
        log.error("vault root %s does not exist", VAULT_ROOT)
        sys.exit(1)
    log.info("vault root: %s", VAULT_ROOT)
    log.info("inbox dir: %s", INBOX_DIR)
    log.info("listen topic: %s -> confirm topic: %s", LISTEN_TOPIC, CONFIRM_TOPIC)
    try:
        _stream_messages()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
