# Deploy Concurrency — Lockfile Protection

## The incident (2026-04-29)

A `bash deploy-nixos.sh` invocation got SIGSTOP'd — most likely Ctrl-Z in a
terminal that subsequently closed, leaving the script paused. The frozen
process kept the nix daemon's per-build lock and never released it.

A second deploy was started — it queued behind the lock and slept.
A third deploy was started — same thing.

Result: **three concurrent `nixos-rebuild switch` processes**, two stopped
(`T` state, holding the lock and not progressing), one waiting (`S` state).
The system stayed on the prior generation. Disk usage grew (~27 GB from
partial builds) and the user observed "every deploy takes forever" while
the actual issue was that nothing was making progress.

```
PID 3549762  T   01:46:46  bash deploy-nixos.sh    ← oldest, stopped
PID 843164   T   46:25     bash deploy-nixos.sh    ← middle, stopped
PID 1098557  S   35:04     bash deploy-nixos.sh    ← active, waiting on lock
```

Recovery required `sudo kill -9` of the entire chain.

## Why it happened

- `bash deploy-nixos.sh` runs in the foreground.
- Job control: Ctrl-Z sends SIGTSTP, which suspends the script.
- If the parent terminal closes while the script is suspended, the script
  ends up orphaned and stopped (parent reparented to PID 1, but state
  remains `T`).
- Stopped processes still hold their open file descriptors and any locks
  they acquired before being stopped — including the nix daemon's
  per-build lock.
- Subsequent deploys try to acquire the same lock, see it held, and wait.
  No timeout.

## What changed

`system_scripts/deploy-nixos.sh` now has a lockfile-based concurrency
guard at the top:

```bash
DEPLOY_LOCK=/tmp/nixos-deploy.lock
if [[ -f "$DEPLOY_LOCK" ]]; then
    prior_pid=$(cat "$DEPLOY_LOCK" 2>/dev/null || true)
    if [[ -n "$prior_pid" ]] && kill -0 "$prior_pid" 2>/dev/null; then
        # prior instance still alive — refuse to start
        echo "Another deploy is already running (PID $prior_pid)."
        echo "If it's stuck (T-state) or you want to abort:"
        echo "  sudo kill -9 \$(pgrep -f 'nixos-rebuild') $prior_pid"
        echo "  rm -f $DEPLOY_LOCK"
        exit 1
    fi
    # stale lockfile — process is gone — override and continue
    rm -f "$DEPLOY_LOCK"
fi
echo $$ > "$DEPLOY_LOCK"
trap 'rm -f "$DEPLOY_LOCK"' EXIT
```

### Behavior

| Scenario | Result |
|---|---|
| First deploy ever | Lockfile written, deploy proceeds, lockfile removed on exit |
| Second deploy started while first is running | Refused with clear message + recovery command |
| Second deploy started after first crashed (lockfile stale, PID gone) | Stale lockfile detected, overridden, second deploy proceeds |
| Deploy gets SIGSTOP'd | Lockfile remains. New deploy refuses to start until SIGSTOP'd one is killed. **The user is forced to recognize and resolve the stuck deploy** rather than queueing more on top. |
| Deploy crashes / gets SIGKILL'd | Trap doesn't run, but PID is dead, so next invocation detects stale lock and proceeds |

### Recovery cookbook

If you see "Another deploy is already running (PID X)":

```bash
# 1. Inspect it
ps -p $(cat /tmp/nixos-deploy.lock) -o pid,etime,stat,cmd

# 2. If it's actually progressing, leave it alone. Check journalctl:
journalctl -t nix-daemon --since "10 minutes ago"

# 3. If it's truly stuck (T-state, or stalled on a build that's gone for hours):
sudo kill -9 $(pgrep -f 'nixos-rebuild') $(cat /tmp/nixos-deploy.lock)
rm -f /tmp/nixos-deploy.lock

# 4. Then re-run the deploy
bash ~/.local/share/chezmoi/system_scripts/deploy-nixos.sh
```

## What this does NOT solve

- **Builds that are genuinely slow** (e.g., gemini-cli npm-deps after a
  flake update — that's 5–15 minutes legitimately).
- **The nix daemon itself getting stuck** (rare; would require restarting
  `nix-daemon.service`).
- **Builds in other shells outside the deploy script** (e.g., a manual
  `nix build ...`) — the lockfile is specific to deploy-nixos.sh.

## Operational guidance

- **Don't Ctrl-Z a deploy.** If you need to interrupt, Ctrl-C — that
  sends SIGINT and the script's traps clean up properly. SIGTSTP leaves
  it frozen.
- **Don't run two deploys at once.** The lock now prevents this. If you
  *want* a deploy to wait for another to finish, just press up-arrow + Enter
  later — your second invocation will refuse cleanly with the right
  message.
- **If you need to abort mid-deploy**: Ctrl-C in the terminal running it,
  then run the deploy again. Don't close the terminal while a deploy is
  running.

## Future improvements

- **Status-line indicator** when a deploy is running (write to status bar
  / polybar) so it's visually obvious.
- **Notification on long-running deploys**: if a deploy runs > 10 minutes,
  publish a "still running" ntfy alert.
- **Abort-old-deploy flag**: `--force` to kill any prior stuck deploy
  automatically. Risky enough I haven't added it; user preference.
- **Replace `/tmp` lockfile with `/var/lock`** so it survives a reboot.
  (Currently a reboot wipes /tmp and naturally clears stuck locks. That's
  actually a feature — if a deploy stuck across boots, you want the next
  boot to clear it.)

## Related

- `system_scripts/deploy-nixos.sh` — the lock implementation
- `docs/system/Notification System — Status and Tech Debt.md` — broader operational concerns
- `docs/system/Nix Store Hygiene.md` — what GC/optimise help with
