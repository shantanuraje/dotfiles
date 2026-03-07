# VNC Server Setup for AwesomeWM

## Overview

Remote desktop access on the Beelink system running AwesomeWM. Two VNC servers run simultaneously:

| Server | Port | Access | Use Case |
|--------|------|--------|----------|
| **x11vnc** | 5901 (LAN) | Direct TCP | LAN access, SSH tunnels |
| **RealVNC** | Cloud relay | RealVNC cloud | Android remote access |

## RealVNC Server (Primary for Android)

### NixOS Service

**File**: `system_nixos/machines/shared/system-common.nix`
```nix
systemd.services.vncserver-x11-serviced = {
  description = "RealVNC Server in Service Mode daemon";
  after = [ "network.target" "syslog.target" "display-manager.service" ];
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    Type = "simple";
    ExecStart = "${realvnc-server}/bin/vncserver-x11-serviced -fg";
    ExecStop = "${pkgs.coreutils}/bin/kill -TERM $MAINPID";
    KillMode = "control-group";
    KillSignal = "SIGTERM";
    TimeoutStopSec = "10";
    Restart = "on-failure";
    RestartSec = "5s";
  };
};
```

### Key Configuration

Config file: `/root/.vnc/config.d/vncserver-x11` (Service Mode, root-owned)

```bash
# Set parameters (requires sudo)
sudo vncserver-x11 -service -AlterShiftWithMods 0
sudo vncserver-x11 -service -<Param> <Value>

# Set VNC password
sudo vncpasswd -service

# Restart after config changes
sudo systemctl restart vncserver-x11-serviced
```

### Critical Settings

| Parameter | Value | Why |
|-----------|-------|-----|
| `AlterShiftWithMods` | `0` | **Must disable.** Default (1) mangles Ctrl+key combos on Android. Breaks Ctrl+C/V/etc. |
| `AcceptKeyEvents` | `1` | Allow keyboard input (default) |

### Known Limitations — Android VNC Viewer

**Super/Mod4 key cannot be sent from Android VNC viewers.** This is a platform limitation — Android intercepts the Super key before any app can use it.

**Workarounds implemented:**
- Polybar WM Actions button (󰣆) — rofi command palette with all WM operations
- Polybar launcher (󰍉) — mouse-based app/window access
- Polybar layout indicator — click to cycle layouts
- Polybar window-actions — click-based close/float/fullscreen/move

**Ctrl+Alt combos were tested but also proved unreliable** over RealVNC Android — the viewer doesn't forward them consistently. These were removed from rc.lua.

**Why not change modkey to Mod1 (Alt)?** Analyzed and rejected — would break ~50 application shortcuts (readline Alt+B/F word navigation, Chrome Alt+1-9 tabs, VSCode Alt+Click multi-cursor, all GTK menu accelerators, etc.). See session notes.

### Clean Shutdown Fix

The systemd service includes `KillMode=control-group` and `TimeoutStopSec=10` to ensure the RealVNC cloud relay receives a proper disconnect on reboot. Without this, stale cloud sessions would persist until the server came back up.

## x11vnc Server (LAN Access)

### NixOS Service

**File**: `system_nixos/machines/personal/desktop-beelink.nix`
```nix
systemd.services.x11vnc = {
  description = "x11vnc - shared X11 session VNC server";
  serviceConfig = {
    ExecStart = "${pkgs.x11vnc}/bin/x11vnc -display :0 -auth $AUTH_FILE -rfbport 5901 -forever -loop -noxdamage -repeat -shared -rfbauth /home/shantanu/.vnc/passwd";
  };
};
```

### Parameters
- `-display :0` — shares main X11 session
- `-rfbport 5901` — LAN port
- `-forever -loop` — persist and restart
- `-noxdamage` — compositor compatibility
- `-repeat` — keyboard repeat
- `-shared` — allow multiple viewers

### Setup
```bash
# Set VNC password
mkdir -p ~/.vnc
x11vnc -storepasswd ~/.vnc/passwd

# Connect (from another machine)
vncviewer 192.168.x.x:5901

# Or via SSH tunnel
ssh -L 5901:localhost:5901 shantanu@beelink-ser8-desktop
vncviewer localhost:5901
```

## Troubleshooting

### Keyboard Issues
- **Ctrl+key not working over RealVNC Android**: Set `AlterShiftWithMods=0` (see above)
- **Super/Mod4 key not working**: Use Polybar WM Actions button (󰣆) instead — this is a platform limitation, not fixable
- **xmodmap interference**: `xorg.xmodmap` is intentionally disabled in `system-common.nix` to prevent VNC keyboard conflicts

### Stale RealVNC Cloud Sessions
- **Symptom**: After reboot, old session lingers in RealVNC cloud
- **Fix**: `KillMode=control-group` + `TimeoutStopSec=10` in systemd service (applied)
- **Manual**: `sudo systemctl restart vncserver-x11-serviced`

### Connection Issues
```bash
# Check x11vnc
pgrep -f x11vnc
journalctl -u x11vnc

# Check RealVNC
sudo systemctl status vncserver-x11-serviced
sudo journalctl -u vncserver-x11-serviced
```

### Systray Icons Missing
AwesomeWM auto-claims `_NET_SYSTEM_TRAY_S0`. The autostart in rc.lua releases it before Polybar launches:
```lua
awful.spawn.with_shell("xprop -root -remove _NET_SYSTEM_TRAY_S0 2>/dev/null; ~/.config/polybar/launch.sh")
```

## Security
- x11vnc: password + firewall (port 5901 open only on Beelink)
- RealVNC: cloud relay with end-to-end encryption, no direct TCP port
- SSH tunnels recommended for x11vnc remote access

## Related Documentation
- [[../polybar/Window Management]] — Mouse-based VNC controls
- [[../polybar/Calendar System]] — Eww calendar popup
