# VNC & Remote Access Setup

## Overview

This system runs two VNC servers for remote desktop access, managed as NixOS systemd services that start at boot. Both are available at the LightDM login screen (X11 greeter).

| Server | Purpose | Port | Auth | Config Location |
|--------|---------|------|------|-----------------|
| **x11vnc** | LAN direct connections | 5901 | `~/.vnc/passwd` | `desktop-beelink.nix` |
| **RealVNC** | Cloud relay (RealVNC Connect) | Cloud only | RealVNC account | `/root/.vnc/config.d/vncserver-x11` |

## Architecture

```
Boot → LightDM (X11 greeter) → Both VNC servers attach to :0
                              → User logs in → AwesomeWM (X11)
                              → VNC stays connected throughout
```

- **LightDM** replaced GDM because GNOME 49+ dropped the X11 greeter (Wayland-only), making VNC capture impossible at the login screen
- **x11vnc** uses LightDM's Xauthority at `/var/run/lightdm/root/:0`
- **RealVNC** connects via cloud relay (no direct TCP port needed, works through firewalls/NAT)

## Configuration Files

| File | What it configures |
|------|-------------------|
| `system_nixos/machines/personal/desktop-beelink.nix` | x11vnc systemd service, firewall port 5901 |
| `system_nixos/machines/shared/system-common.nix` | RealVNC systemd service, LightDM config |
| `system_nixos/realvnc-server.nix` | RealVNC server Nix package (includes GTK2 for tray icon) |
| `/root/.vnc/config.d/vncserver-x11` | RealVNC runtime config (Authentication, AlterShiftWithMods) |

## Service Management

### x11vnc

```bash
# Check status
systemctl status x11vnc

# Restart
sudo systemctl restart x11vnc

# View logs
journalctl -u x11vnc --no-pager --since "10 min ago"

# Check if listening
ss -tlnp | grep 5901
```

### RealVNC Server

```bash
# Check status
systemctl status vncserver-x11-serviced

# Restart (no duplicate instances — systemd manages lifecycle)
sudo systemctl restart vncserver-x11-serviced

# View logs
journalctl -u vncserver-x11-serviced --no-pager --since "10 min ago"

# Check running config
sudo vncserver-x11 -service -getconfig

# View config file
sudo cat /root/.vnc/config.d/vncserver-x11

# Change a setting (writes to config file)
sudo vncserver-x11 -service -<Param> <Value>

# Set/change VNC password
sudo vncpasswd -service
```

### LightDM (Display Manager)

```bash
# Check status
systemctl status display-manager

# Restart (will log everyone out!)
sudo systemctl restart display-manager

# View logs
journalctl -u display-manager --no-pager --since "10 min ago"

# Check config
cat /etc/lightdm/lightdm.conf
```

## Setup Guide

### x11vnc Password

```bash
# Create/change VNC password
x11vnc -storepasswd ~/.vnc/passwd
```

### RealVNC Initial Setup

1. Sign in to RealVNC account:
   ```bash
   sudo vncserver-x11 -service -Authentication VncAuth
   ```
   This opens a UI where you can sign in with your RealVNC account.

2. Set VNC password:
   ```bash
   sudo vncpasswd -service
   ```

3. Configure settings:
   ```bash
   # Disable AlterShiftWithMods (recommended for keyboard compatibility)
   sudo bash -c 'echo "AlterShiftWithMods=0" >> /root/.vnc/config.d/vncserver-x11'
   ```

4. Restart service:
   ```bash
   sudo systemctl restart vncserver-x11-serviced
   ```

### RealVNC Config File Format

`/root/.vnc/config.d/vncserver-x11` — key=value, one per line:
```
Authentication=VncAuth
Password=<obfuscated hash>
AlterShiftWithMods=0
EnableAnalytics=1
```

**Important**: The supervisor daemon (`vncserver-x11-serviced`) does NOT accept VNC parameters on the command line. It only accepts `-fg`. All VNC config must go in the config file or be set via `sudo vncserver-x11 -service -<Param> <Value>`.

## Troubleshooting

### x11vnc not starting

**Symptom**: `systemctl status x11vnc` shows failed, ExecStart exits with error.

**Check auth file**:
```bash
ls -la /var/run/lightdm/root/:0
```
If missing, LightDM hasn't started X yet. Check display-manager service.

**Check if display :0 exists**:
```bash
DISPLAY=:0 XAUTHORITY=/var/run/lightdm/root/:0 xset q
```

**Check password file**:
```bash
ls -la ~/.vnc/passwd
```
If missing, create it: `x11vnc -storepasswd ~/.vnc/passwd`

### RealVNC not connecting

**Symptom**: Service is running but can't connect via RealVNC Viewer.

1. **Check service is active**:
   ```bash
   systemctl status vncserver-x11-serviced
   ps aux | grep vncserver-x11-core
   ```
   If `vncserver-x11-core` is NOT in the process list, the core server crashed.

2. **Check for GTK2 crash** (tray icon killing core server):
   ```bash
   journalctl -u vncserver-x11-serviced --since "5 min ago" | grep -i "gtk_init\|broken pipe"
   ```
   Fix: ensure `gtk2-x11` is in `realvnc-server.nix` buildInputs.

3. **Check config file exists and has password**:
   ```bash
   sudo cat /root/.vnc/config.d/vncserver-x11
   ```
   Must have `Authentication=VncAuth` and `Password=<hash>`. If password is missing, run `sudo vncpasswd -service`.

4. **Config directory missing**:
   ```bash
   ls -la /root/.vnc/config.d/
   ```
   If missing, the ExecStartPre should create it. Check: `sudo mkdir -p /root/.vnc/config.d`

### VNC available after login but not at login screen

**Cause**: Display manager greeter runs Wayland (VNC can't capture Wayland).

**Fix**: Use LightDM (X11 greeter), not GDM. This is already configured. Verify:
```bash
grep "lightdm" /etc/lightdm/lightdm.conf
```

If GDM is running instead of LightDM, check that `services.displayManager.gdm.enable = lib.mkForce false` is set (GNOME module auto-enables GDM).

### Black screen with cursor after login (LightDM)

**Cause 1**: Duplicate `[Seat:*]` section in lightdm.conf — use `extraSeatDefaults` not `extraConfig` for seat-level settings.

**Cause 2**: Default session not set or invalid.
```bash
grep "user-session" /etc/lightdm/lightdm.conf
```
Must be `none+awesome` (not just `awesome`). Valid session names: `gnome`, `none+awesome`, `hyprland`, `hyprland-uwsm`.

**Cause 3**: GDM still active (GNOME module auto-enables it):
```bash
systemctl status gdm
```
Fix: `services.displayManager.gdm.enable = lib.mkForce false` in system-common.nix.

### Boot hangs / stuck at black screen

**GDM + wayland=false**: GNOME 49+ dropped X11 greeter target. Setting `gdm.wayland = false` causes crash loop:
```
Failed to start unit gnome-session-x11@gnome-login.target: Unit not found
```
**Fix**: Don't use `gdm.wayland = false`. Use LightDM instead.

**DRM timeouts**: If you see `[drm] REG_WAIT timeout` in `journalctl -b`, this is a GPU driver issue often triggered by display manager conflicts. Boot into a previous generation from the boot menu and fix the config.

### Systray icons not showing in Polybar

**Symptom**: `polybar.log` shows `Lost systray selection, deactivating...`

**Cause**: AwesomeWM auto-claims the X11 systray selection.

**Fix**: Release it before polybar starts (already configured in rc.lua):
```bash
xprop -root -remove _NET_SYSTEM_TRAY_S0
```

### LightDM wallpaper not showing

**Cause**: Symlink to wallpaper in user's home dir — LightDM user can't traverse `/home/shantanu` (700 permissions).

**Fix**: Copy the file instead of symlinking (already configured):
```bash
# Check if wallpaper was copied
ls -la /var/run/lightdm-wallpaper.jpg

# Test readability as lightdm user
sudo -u lightdm cat /var/run/lightdm-wallpaper.jpg > /dev/null && echo OK || echo FAIL
```

## Session History & Decisions

### Why LightDM instead of GDM?
GNOME 49.2 dropped the X11 greeter target (`gnome-session-x11@gnome-login.target`). GDM's greeter now only runs on Wayland. Setting `gdm.wayland = false` causes a crash loop. LightDM's greeter always runs on X11, making it compatible with VNC capture.

### Why not SDDM?
SDDM was considered (better theming, Qt Virtual Keyboard) but LightDM was chosen for its predictable auth file path (`/var/run/lightdm/root/:0` vs SDDM's dynamic `/var/run/sddm/*`), better NixOS integration (default DM), and simpler x11vnc setup.

### Why cloud-only for RealVNC?
RealVNC's free/home tier only supports cloud relay connections, not direct TCP. Port 5902 was removed from the firewall since direct connections aren't available on this license tier.

### RealVNC supervisor vs core architecture
- `vncserver-x11-serviced` = supervisor daemon (only accepts `-fg`, no VNC params)
- `vncserver-x11-core` = actual VNC server (reads config from `/root/.vnc/config.d/vncserver-x11`)
- `vncserver-x11 -service` = CLI tool for setting config (writes to the config file)

The supervisor spawns the core process. VNC parameters passed to the supervisor are silently ignored. Always configure via the config file or `vncserver-x11 -service -<Param> <Value>`.

### Font Awesome 6 → 7 upgrade
nixpkgs upgraded Font Awesome from v6 to v7. Font family names changed (`Font Awesome 6 Free` → `Font Awesome 7 Free`). Polybar configs were updated accordingly. Icon codepoints may have changed between versions — check [Font Awesome migration guide](https://docs.fontawesome.com/web/setup/upgrade/) if specific icons are missing.
