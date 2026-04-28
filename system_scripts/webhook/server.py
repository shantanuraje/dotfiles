#!/usr/bin/env python3
"""
Webhook receiver for ntfy action buttons.

Listens on the tailnet, authenticates via shared-secret Bearer token,
and dispatches to allowlisted actions defined in webhook-actions.yaml.

Two action types supported:
  - command: exec a static argv (no shell). Param substitution via {{params.X}}
             but only into pre-declared positional slots, no shell concat.
  - http_proxy: forward to a loopback URL (Hermes/Zeroclaw/etc). Body
                template can reference {{params.X}}.

Replay protection: optional X-Action-Nonce header tracked in an in-memory
set with TTL. Token check uses hmac.compare_digest to be timing-safe.

Async by default for commands >5s (returns 202, posts follow-up notification
on completion). Sync 200 for fast actions.

Bind: 100.116.242.38:9099 (tailnet IP) — same pattern as vault-api.
Service: notify-webhook.service (NixOS-managed, see system_nixos/notify-webhook.nix).

Audit log: ~/.local/state/notify-webhook/audit.log (append-only).
"""

from __future__ import annotations

import hmac
import json
import logging
import os
import re
import shlex
import subprocess
import sys
import threading
import time
import urllib.request
from dataclasses import dataclass
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any

import yaml

# ── Config locations ──────────────────────────────────────────────────────────
TOKEN_FILE = Path.home() / ".config" / "notify" / "webhook-token"
ACTIONS_FILE = Path.home() / ".config" / "notify" / "webhook-actions.yaml"
AUDIT_DIR = Path.home() / ".local" / "state" / "notify-webhook"
AUDIT_LOG = AUDIT_DIR / "audit.log"

NTFY_BASE = os.environ.get("NTFY_BASE_URL", "http://beelink-ser8-desktop:8090")
BIND_HOST = os.environ.get("WEBHOOK_BIND_HOST", "100.116.242.38")
BIND_PORT = int(os.environ.get("WEBHOOK_BIND_PORT", "9099"))

NONCE_TTL = 600  # seconds — replay window
PARAM_KEY_RE = re.compile(r"^[a-zA-Z0-9_.-]{1,64}$")
# Param values are ONLY ever substituted into pre-declared argv slots
# (never concatenated into a shell string), so the threat model is much
# narrower than a free-form shell exec. We forbid only null bytes and
# bound the length. Spaces, punctuation, and Unicode are allowed —
# necessary for natural-language prompts ("Ask Hermes …").
PARAM_VALUE_MAX_LEN = 4096

# ── Globals ───────────────────────────────────────────────────────────────────
log = logging.getLogger("notify-webhook")
_seen_nonces: dict[str, float] = {}
_nonces_lock = threading.Lock()


@dataclass
class Action:
    name: str
    type: str                      # "command" | "http_proxy"
    description: str
    timeout_s: int = 60
    follow_up_topic: str | None = None
    # command-type fields
    argv: list[str] | None = None
    cwd: str | None = None
    # http_proxy-type fields
    target_url: str | None = None
    method: str = "POST"
    body_template: str | None = None
    headers: dict[str, str] | None = None


def _load_token() -> str:
    if not TOKEN_FILE.exists():
        sys.exit(f"missing token file: {TOKEN_FILE}")
    tok = TOKEN_FILE.read_text().strip()
    if len(tok) < 16:
        sys.exit(f"token too short in {TOKEN_FILE}")
    return tok


def _load_actions() -> dict[str, Action]:
    if not ACTIONS_FILE.exists():
        log.warning("no actions file at %s — no actions registered", ACTIONS_FILE)
        return {}
    raw = yaml.safe_load(ACTIONS_FILE.read_text()) or {}
    out: dict[str, Action] = {}
    for name, spec in (raw.get("actions") or {}).items():
        a = Action(
            name=name,
            type=spec["type"],
            description=spec.get("description", ""),
            timeout_s=int(spec.get("timeout_s", 60)),
            follow_up_topic=spec.get("follow_up_topic"),
        )
        if a.type == "command":
            a.argv = list(spec["command"])
            a.cwd = spec.get("cwd")
        elif a.type == "http_proxy":
            a.target_url = spec["target"]
            a.method = spec.get("method", "POST").upper()
            a.body_template = spec.get("body_template")
            a.headers = dict(spec.get("headers", {}))
        else:
            log.error("unknown action type %s for %s — skipping", a.type, name)
            continue
        out[name] = a
    log.info("loaded %d actions: %s", len(out), ", ".join(out.keys()))
    return out


def _audit(event: str, **fields: Any) -> None:
    AUDIT_DIR.mkdir(parents=True, exist_ok=True)
    line = json.dumps({"ts": time.time(), "event": event, **fields}, default=str)
    with AUDIT_LOG.open("a") as f:
        f.write(line + "\n")


def _validate_params(params: dict[str, Any]) -> dict[str, str]:
    """Sanity-check param keys + values.

    Values go into pre-declared argv slots only (never shell strings), so
    we only need to forbid null bytes and bound length. Natural-language
    prompts with spaces / punctuation / Unicode all pass.
    """
    clean: dict[str, str] = {}
    for k, v in params.items():
        if not PARAM_KEY_RE.match(k):
            raise ValueError(f"bad param key: {k!r}")
        s = str(v)
        if len(s) > PARAM_VALUE_MAX_LEN:
            raise ValueError(f"param {k} too long ({len(s)} > {PARAM_VALUE_MAX_LEN})")
        if "\x00" in s:
            raise ValueError(f"param {k} contains null byte")
        clean[k] = s
    return clean


def _expand_argv(argv: list[str], params: dict[str, str]) -> list[str]:
    """Substitute {{params.X}} into argv slots. No shell, no concat — only
    full-token replacement of pre-declared placeholders."""
    out: list[str] = []
    for token in argv:
        m = re.fullmatch(r"\{\{\s*params\.([a-zA-Z0-9_]+)\s*\}\}", token)
        if m:
            key = m.group(1)
            if key not in params:
                raise ValueError(f"missing param: {key}")
            out.append(params[key])
        else:
            out.append(token)
    return out


def _expand_template(tpl: str, params: dict[str, str]) -> str:
    """Substitute {{params.X}} into a string template."""
    def repl(m: re.Match) -> str:
        key = m.group(1)
        if key not in params:
            raise ValueError(f"missing param: {key}")
        return params[key]
    return re.sub(r"\{\{\s*params\.([a-zA-Z0-9_]+)\s*\}\}", repl, tpl)


def _publish(topic: str, title: str, message: str, priority: str = "default", tags: str = "") -> None:
    """Publish to ntfy via the JSON endpoint.

    Why JSON instead of header-mode? HTTP header values must be latin-1 in
    Python's urllib — emoji or any non-Latin-1 char in the Title causes the
    publish to throw `latin-1 codec can't encode`. JSON publish puts the
    title in the JSON body (UTF-8) which works for any Unicode content.
    """
    if not topic:
        return
    pri_map = {"min": 1, "low": 2, "default": 3, "high": 4, "urgent": 5}
    payload: dict[str, Any] = {
        "topic": topic,
        "title": title,
        "message": message,
        "priority": pri_map.get(priority, 3),
    }
    if tags:
        payload["tags"] = tags.split(",")
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
        log.warning("follow-up publish to %s failed: %s", topic, e)


def _run_command(action: Action, params: dict[str, str]) -> tuple[int, str, str]:
    argv = _expand_argv(action.argv or [], params)
    log.info("exec: %s (cwd=%s, timeout=%ds)", shlex.join(argv), action.cwd, action.timeout_s)
    try:
        cp = subprocess.run(
            argv,
            cwd=action.cwd,
            capture_output=True,
            text=True,
            timeout=action.timeout_s,
            env={**os.environ},
        )
        return cp.returncode, cp.stdout, cp.stderr
    except subprocess.TimeoutExpired:
        return 124, "", f"timeout after {action.timeout_s}s"


def _run_http_proxy(action: Action, params: dict[str, str]) -> tuple[int, str, str]:
    body = b""
    if action.body_template:
        body = _expand_template(action.body_template, params).encode("utf-8")
    headers = dict(action.headers or {})
    if body and "Content-Type" not in headers:
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(
        action.target_url, data=body, headers=headers, method=action.method
    )
    log.info("proxy %s %s", action.method, action.target_url)
    try:
        with urllib.request.urlopen(req, timeout=action.timeout_s) as r:
            return r.status, r.read().decode("utf-8", errors="replace"), ""
    except urllib.error.HTTPError as e:
        return e.code, "", e.read().decode("utf-8", errors="replace")
    except Exception as e:
        return 599, "", str(e)


def _follow_up(action: Action, exit_code: int, stdout: str, stderr: str) -> None:
    if not action.follow_up_topic:
        return
    ok = exit_code == 0 or (200 <= exit_code < 300)
    if ok:
        title = f"✓ {action.description or action.name} — done"
        priority = "default"
        tags = "white_check_mark"
    else:
        title = f"✗ {action.description or action.name} — failed"
        priority = "high"
        tags = "x"
    body = (stdout or stderr or "(no output)").strip()
    if len(body) > 800:
        body = body[:800] + "\n…(truncated)"
    _publish(action.follow_up_topic, title, body, priority, tags)


# ── HTTP server ───────────────────────────────────────────────────────────────
class WebhookHandler(BaseHTTPRequestHandler):
    server_version = "ntfy-webhook/1.0"

    # Reduce default verbose logging
    def log_message(self, fmt: str, *args: Any) -> None:
        log.info("%s - %s", self.client_address[0], fmt % args)

    def _reply(self, status: int, body: dict[str, Any]) -> None:
        payload = json.dumps(body).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def _check_auth(self) -> bool:
        h = self.headers.get("Authorization", "")
        if not h.startswith("Bearer "):
            return False
        return hmac.compare_digest(h[7:], self.server.token)  # type: ignore[attr-defined]

    def _check_nonce(self) -> bool:
        nonce = self.headers.get("X-Action-Nonce", "")
        if not nonce:
            return True  # nonce optional — but recommended
        now = time.time()
        with _nonces_lock:
            # Garbage-collect old nonces
            stale = [n for n, t in _seen_nonces.items() if now - t > NONCE_TTL]
            for n in stale:
                del _seen_nonces[n]
            if nonce in _seen_nonces:
                return False
            _seen_nonces[nonce] = now
        return True

    def _read_body(self) -> dict[str, Any]:
        length = int(self.headers.get("Content-Length", "0"))
        if length == 0:
            return {}
        raw = self.rfile.read(length)
        # Try JSON regardless of Content-Type. Some clients (incl. the ntfy
        # Android app at certain versions) send a body without setting an
        # explicit application/json Content-Type. We're lenient: if it parses
        # as JSON, use it; otherwise treat as empty.
        try:
            parsed = json.loads(raw)
            if isinstance(parsed, dict):
                return parsed
        except Exception:
            log.warning("body present but not parseable as JSON dict: %r", raw[:200])
        return {}

    def do_GET(self) -> None:
        if self.path == "/health":
            self._reply(200, {"ok": True, "actions": list(self.server.actions.keys())})  # type: ignore[attr-defined]
            return
        self._reply(404, {"error": "not found"})

    def do_POST(self) -> None:
        if not self.path.startswith("/action/"):
            self._reply(404, {"error": "not found"})
            return
        if not self._check_auth():
            _audit("auth_fail", path=self.path, remote=self.client_address[0])
            self._reply(401, {"error": "unauthorized"})
            return
        if not self._check_nonce():
            _audit("nonce_replay", path=self.path, remote=self.client_address[0])
            self._reply(409, {"error": "nonce replayed"})
            return

        name = self.path.removeprefix("/action/")
        action = self.server.actions.get(name)  # type: ignore[attr-defined]
        if not action:
            _audit("unknown_action", name=name, remote=self.client_address[0])
            self._reply(404, {"error": f"unknown action: {name}"})
            return

        body = self._read_body()
        try:
            params = _validate_params(body.get("params", {}))
        except ValueError as e:
            self._reply(400, {"error": str(e)})
            return

        _audit("dispatch", action=name, params=params, remote=self.client_address[0])

        # Async path for any action — dispatch + return 202 immediately.
        # The follow-up notification carries the result. This avoids tying up
        # the phone's request, especially for nix-collect-garbage-style ops.
        def runner() -> None:
            t0 = time.time()
            try:
                if action.type == "command":
                    rc, out, err = _run_command(action, params)
                else:
                    rc, out, err = _run_http_proxy(action, params)
            except Exception as e:
                log.exception("dispatch failed")
                rc, out, err = 1, "", str(e)
            duration = time.time() - t0
            _audit("complete", action=name, exit_code=rc, duration_s=round(duration, 2))
            _follow_up(action, rc, out, err)

        threading.Thread(target=runner, daemon=True, name=f"action-{name}").start()
        self._reply(202, {"accepted": True, "action": name, "params": params})


class WebhookServer(ThreadingHTTPServer):
    daemon_threads = True

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.token = _load_token()
        self.actions = _load_actions()
        # SIGHUP reloads actions (poor man's hot-reload)
        try:
            import signal
            signal.signal(signal.SIGHUP, lambda *_: self._reload())  # type: ignore[arg-type]
        except Exception:
            pass

    def _reload(self) -> None:
        log.info("reloading actions on SIGHUP")
        self.actions = _load_actions()


def main() -> None:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    )
    AUDIT_DIR.mkdir(parents=True, exist_ok=True)
    server = WebhookServer((BIND_HOST, BIND_PORT), WebhookHandler)
    log.info("listening on %s:%d", BIND_HOST, BIND_PORT)
    log.info("audit log: %s", AUDIT_LOG)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
