---
title: NixOS LightDM Session Crash and PAM Authentication Investigation
dateCreated: 2026-03-25T20:10:00.000-04:00
dateModified: 2026-03-25T20:10:00.000-04:00
tags:
  - nixos
  - debugging
  - lightdm
  - pam
  - vnc
  - awesomewm
  - system-administration
status: open
priority: high
area: Productivity
archived: false
---

# NixOS LightDM Session Crash and PAM Authentication Investigation

**System**: Beelink SER8 Desktop, NixOS 26.05, kernel 6.6.129, LightDM + AwesomeWM
**Date investigated**: 2026-03-25
**Reported symptoms**:
1. Session drops to login screen while AFK (connected via VNC from Android tablet)
2. LightDM rejects correct password on login screen, requiring multiple reboots

---

## Bug 1: Session Drops to Login Screen While AFK

### Incident Timeline

#### Mar 24 ~00:28 — OOM-Induced Crash
| Time | Event |
|------|-------|
| 00:26:33 | `systemd-resolved`: "Under memory pressure, flushing caches" |
| 00:26:52 | `systemd-journald`: "Under memory pressure, flushing caches" (repeats many times) |
| 00:26:56 | AwesomeWM: main loop iteration took **47 seconds** |
| 00:28:36 | AwesomeWM: main loop iteration took **103 seconds** |
| 00:28:36 | D-Bus assertion failure in awesome: `dbus_connection_unref()` — "arguments were incorrect" |
| 00:28:36 | `dunst`: "Cannot connect to DBus" |
| 00:28:36 | awesome crashed with **signal 6 (SIGABRT)** from D-Bus library |
| 00:28:36 | LightDM greeter session started (user sees login screen) |

**Root cause**: Severe memory pressure caused the D-Bus session bus to become corrupted/unavailable. AwesomeWM's main loop froze for >100 seconds. When awesome tried to use the corrupted D-Bus connection, the D-Bus library hit an assertion failure and called `abort()`, killing the WM process. LightDM then reverted to the greeter.

#### Mar 25 ~19:46 — X Server Death (Possible RealVNC Trigger)
| Time | Event |
|------|-------|
| 19:46:00.905 | RealVNC `vncserver-x11-serviced`: BadWindow X11 error on `X_ChangeWindowAttributes` |
| 19:46:00.908 | systemd: Stopped graphical-session target |
| 19:46:00.918 | LightDM: PAM session closed for user shantanu |
| 19:46:00.920 | Session 2 logged out |
| 19:46:00.925 | x11vnc: caught XIO error, X connection broken |
| 19:46:00.925 | Multiple processes report: "X connection to :0 broken (explicit kill or server shutdown)" |
| 19:46:00.925 | polybar: segfault (SIGSEGV) |
| 19:46:00.925 | electron (Obsidian/other): trap (SIGTRAP) |
| 19:46:04 | RealVNC found new X server (pid=911050) — LightDM respawned Xorg for greeter |

**Root cause**: The X server (Xorg) process died. No memory pressure was detected before this crash. The first logged error is RealVNC's `BadWindow` on `X_ChangeWindowAttributes` for resource `0x1000005` (the root window). This suggests either:
1. RealVNC triggered a fatal X protocol error that killed the X server
2. The X server crashed independently and RealVNC's error was just the first symptom logged

**Note**: No Xorg log files found at `/var/log/Xorg*` or `/var/log/lightdm/` — NixOS may not be persisting these. This makes X server crash diagnosis harder.

### Contributing Factors

1. **Recurring AwesomeWM error every 30 seconds** — `rc.lua:323`: `attempt to concatenate global 'temp_now' (a table value)`. The lain temp widget returns a table, but the code treats it as a string. While this error alone doesn't crash awesome, it creates continuous error spam and could contribute to instability under pressure.

2. **Two VNC servers running simultaneously** — Both `x11vnc` (port 5901, systemd service) and `vncserver-x11-serviced` (RealVNC, cloud relay) are running against the same X display `:0`. Two VNC servers polling the same framebuffer and intercepting X events can cause race conditions and X protocol errors.

3. **28GB RAM with 16GB swap** — The Mar 24 crash was caused by memory exhaustion. Need to identify what consumed the memory (possibly Firefox, Electron apps, or AI tools running in the background).

### Recommended Fixes

#### Fix 1: Temp widget bug (quick fix)
```lua
-- rc.lua line 323, change from:
local temperature = temp_now and temp_now .. "°C" or "N/A"
-- to:
local temperature = type(temp_now) == "string" and temp_now .. "°C" or type(temp_now) == "number" and temp_now .. "°C" or type(temp_now) == "table" and (temp_now[1] or "N/A") or "N/A"
```
The lain `temp` widget changed its return format — `temp_now` is now a table, not a string/number.

#### Fix 2: Disable one VNC server
Running both x11vnc and RealVNC against the same display is risky. Choose one:
- **x11vnc only**: Simple, open-source, direct LAN access on port 5901
- **RealVNC only**: Cloud relay for remote access, better performance

If both are needed (LAN + remote), ensure RealVNC's X error handling is non-fatal.

#### Fix 3: Add earlyoom or systemd-oomd
Prevent the OOM cascade that killed the session on Mar 24:
```nix
# In system-common.nix
services.earlyoom = {
  enable = true;
  freeMemThreshold = 5;  # Kill when <5% free
  freeSwapThreshold = 10;
};
```

#### Fix 4: Enable Xorg logging
```nix
# For better crash diagnosis
services.xserver.logFile = "/var/log/Xorg.0.log";
```

---

## Bug 2: LightDM Rejects Correct Password After Reboot

### Root Cause: systemd Ordering Cycle

A **critical systemd dependency cycle** is preventing PAM authentication from working on some boots.

#### The Cycle
```
create-swapfile.service
  → before: swapfile.swap
  → wantedBy: multi-user.target (inherits After=basic.target)
  → after: local-fs.target

This creates:
suid-sgid-wrappers.service → run-wrappers.mount → swap.target → swapfile.swap
  → create-swapfile.service → basic.target → sockets.target → sysinit.target
  → suid-sgid-wrappers.service  (CYCLE!)
```

#### What Happens

systemd detects this cycle and **deletes critical services** to break it. Across the 3 reboots on Mar 25:

**Boot -2 (19:51)**: systemd deleted `suid-sgid-wrappers.service` to break the cycle
- `/run/wrappers/bin/unix_chkpwd` was **never created**
- PAM error: `helper binary execve failed: No such file or directory`
- Every password attempt fails: `pam_unix(lightdm:auth): authentication failure`
- Also broke: `user@78.service` (lightdm user), `polkit-agent-helper.socket`

**Boot -1 (19:52)**: systemd deleted `avahi-daemon.socket`, `systemd-update-utmp`, `systemd-tmpfiles-setup`, and many other services
- Massive cascade of broken services
- Still no working auth

**Boot 0 (19:54)**: systemd deleted `swap.target` instead
- This left `suid-sgid-wrappers.service` intact
- `/run/wrappers/bin/unix_chkpwd` was created at 19:54:53
- Login succeeded at 19:55:20
- Trade-off: **swap is not active** on this boot (but swapfile existed, so it might have been activated later)

#### Evidence from Logs

```
Mar 25 19:51:13 (systemd)[1293]: pam_unix(systemd-user:account): helper binary execve failed: No such file or directory
Mar 25 19:51:13 (systemd)[1292]: user@78.service: Failed to set up PAM session: Operation not permitted
Mar 25 19:51:48 lightdm[1347]: pam_unix(lightdm:auth): authentication failure; user=shantanu
```

```
Mar 25 19:51:09 systemd[1]: sockets.target: Found ordering cycle: polkit-agent-helper.socket → sysinit.target → suid-sgid-wrappers.service → run-wrappers.mount → swap.target → swapfile.swap → create-swapfile.service → basic.target → sockets.target
Mar 25 19:51:09 systemd[1]: create-swapfile.service: Job suid-sgid-wrappers.service/start deleted to break ordering cycle
```

### The Fix

The `create-swapfile` service dependencies are wrong. It uses `wantedBy = [ "multi-user.target" ]` which drags it into the `basic.target → sockets.target → sysinit.target` chain, creating a cycle with `suid-sgid-wrappers.service` through `run-wrappers.mount` and `swap.target`.

**Fix in `system-common.nix`** — Change the service to avoid the cycle:
```nix
systemd.services.create-swapfile = {
  description = "Create swap file if it doesn't exist";
  wantedBy = [ "swapfile.swap" ];  # Only needed before swap activation
  before = [ "swapfile.swap" ];
  after = [ "local-fs.target" ];
  unitConfig = {
    RequiresMountsFor = "/";
    DefaultDependencies = false;  # Prevent automatic After=basic.target
  };
  serviceConfig = {
    Type = "oneshot";
    RemainAfterExit = true;
    # ... (rest unchanged)
  };
};
```

Key changes:
1. **`DefaultDependencies = false`** — Prevents systemd from adding implicit `After=basic.target` which is what creates the cycle through `sockets.target → sysinit.target → suid-sgid-wrappers.service`
2. **`wantedBy = [ "swapfile.swap" ]`** — Only triggers when swap is being activated, not pulled in by multi-user.target's dependency chain
3. **`RemainAfterExit = true`** — So systemd knows the one-shot completed

**Alternative simpler fix**: Since the swapfile already exists on this system, you could remove the `create-swapfile` service entirely and just keep the `swapDevices` declaration. The service is only needed for first-time setup.

### Additional Note: gkr-pam Errors

Every login attempt shows: `gkr-pam: unable to locate daemon control file`

This is the GNOME Keyring PAM module failing because gnome-keyring-daemon isn't running at login time. While not critical (login still works when unix_chkpwd is available), it means the keyring won't auto-unlock on login. This is expected when not using a full GNOME session.

---

## Summary of Actions Needed

| Priority | Action | Bug | Effort |
|----------|--------|-----|--------|
| **CRITICAL** | Fix `create-swapfile` service dependencies to eliminate systemd ordering cycle | Bug 2 | NixOS config change + deploy |
| **HIGH** | Enable earlyoom/systemd-oomd to prevent OOM session crashes | Bug 1 | NixOS config change + deploy |
| **MEDIUM** | Fix temp widget in `rc.lua:323` — stops error spam every 30s | Bug 1 contributor | 1-line fix |
| **MEDIUM** | Decide: run only one VNC server (x11vnc OR RealVNC), not both | Bug 1 contributor | Config change |
| **LOW** | Enable Xorg logging for better crash diagnosis | Both | NixOS config change |
| **LOW** | Investigate memory consumption patterns (what's eating 28GB+16GB?) | Bug 1 | Monitoring |

---

## References

- Boot logs: `journalctl -b -2`, `-b -1`, `-b 0` (Mar 25 reboots)
- Session crash logs: `journalctl -b -4 --since "2026-03-24 00:26"` and `-b -3 --since "2026-03-25 19:45"`
- NixOS config: `~/.local/share/chezmoi/system_nixos/machines/shared/system-common.nix` (swapfile service at line ~173)
- AwesomeWM config: `~/.config/awesome/rc.lua` (temp widget at line 321-326)
- Desktop config: `~/.local/share/chezmoi/system_nixos/machines/personal/desktop-beelink.nix` (VNC services)
