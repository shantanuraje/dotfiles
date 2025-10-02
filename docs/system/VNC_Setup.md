# VNC Server Setup for AwesomeWM

## Overview

This guide documents the VNC server setup for remote desktop access on the Beelink system running AwesomeWM. The configuration uses x11vnc to share the existing X11 session rather than creating a separate virtual desktop.

## Configuration Details

### NixOS Configuration

The x11vnc package is installed specifically on the Beelink system:

**File**: `system_nixos/machines/personal/desktop-beelink.nix`
```nix
environment.systemPackages = with pkgs; [
  # VNC server for remote access
  x11vnc
];

# Open firewall port for VNC (for LAN access)
networking.firewall.allowedTCPPorts = [ 5901 ];
```

### AwesomeWM Integration

VNC server starts automatically when AwesomeWM launches:

**File**: `private_dot_config/awesome/rc.lua` (lines 67-71)
```lua
local system_cmds = {
    "picom --config ~/.config/picom/picom.conf",
    "bash ~/.config/awesome/wallpaper-rotate.sh",
    "dunst",
    "pkill x11vnc; x11vnc -display :0 -rfbport 5901 -forever -loop -noxdamage -repeat -rfbauth ~/.vnc/passwd",
}
```

### VNC Server Parameters

- **Port**: 5901
- **Display**: :0 (main X11 display)
- **Binding**: All interfaces (accessible on LAN)
- **Authentication**: Password file at `~/.vnc/passwd`
- **Options**:
  - `pkill x11vnc`: Kill any existing x11vnc instances before starting
  - `-forever`: Keep running after client disconnects
  - `-loop`: Restart if it crashes
  - `-noxdamage`: Better compatibility with compositors
  - `-repeat`: Allow keyboard repeat

## Initial Setup

### 1. Set VNC Password

Before first use, create a VNC password:

```bash
mkdir -p ~/.vnc
x11vnc -storepasswd ~/.vnc/passwd
```

### 2. Deploy Configuration

```bash
# Test NixOS configuration
bash ~/.local/share/chezmoi/system_scripts/test-deploy-nixos.sh

# Deploy NixOS changes
bash ~/.local/share/chezmoi/system_scripts/deploy-nixos.sh

# Apply dotfiles changes
chezmoi apply
```

### 3. Restart AwesomeWM

Either log out and back in, or press `Super + Ctrl + r` to reload AwesomeWM.

## Usage

### Local Network Access (Direct Connection)

When connecting from another machine on the same network:

1. **Enable firewall port** in `desktop-beelink.nix`:
   ```nix
   networking.firewall.allowedTCPPorts = [ 5901 ];
   ```

2. **Find the Beelink's IP address**:
   ```bash
   # On the Beelink machine
   ip addr | grep inet
   # Look for your LAN IP (usually 192.168.x.x or 10.x.x.x)
   ```

3. **Connect from Samsung laptop**:
   
   **Using Remmina**:
   - Open Remmina
   - Click "+" for new connection
   - Protocol: VNC
   - Server: `192.168.x.x:5901` (replace with actual IP)
   - Name: `Beelink Desktop`
   - Enter VNC password when prompted
   
   **Using TigerVNC**:
   ```bash
   vncviewer 192.168.x.x:5901
   ```

### Remote Access (SSH Tunnel - More Secure)

For accessing from outside your network or for extra security:

1. **Create SSH tunnel** from Samsung laptop:
   ```bash
   ssh -L 5901:localhost:5901 shantanu@beelink-ser8-desktop
   ```

2. **Connect VNC viewer** to localhost:
   ```bash
   # In another terminal
   vncviewer localhost:5901
   ```

## Troubleshooting

### Check if VNC is running

```bash
pgrep -f x11vnc
```

### View VNC server logs

```bash
# Check AwesomeWM logs for startup issues
journalctl --user -u awesome

# Run x11vnc manually to see errors
pkill x11vnc; x11vnc -display :0 -rfbport 5901 -forever -loop -noxdamage -repeat -rfbauth ~/.vnc/passwd
```

### Common Issues

1. **"Authentication failed"**
   - Recreate password: `x11vnc -storepasswd ~/.vnc/passwd`

2. **"Connection refused"**
   - Ensure x11vnc is running
   - Check firewall settings
   - Verify SSH tunnel is active

3. **Black screen**
   - Ensure you're using the correct display (:0)
   - Check if compositor (picom) is running

4. **Keyboard issues (e.g., Shift+Tab not working)**
   - Common with Android VNC clients (especially bVNC)
   - Known issue: Having `xorg.xmodmap` package installed can interfere with x11vnc keyboard handling
   - Some key combinations (like Super+Enter) may not work properly with Android clients
   - Consider using alternative key bindings or input methods in your VNC client

## Security Considerations

1. **Localhost binding**: VNC only accepts connections from localhost, requiring SSH tunnel for remote access
2. **Password authentication**: Always use a strong VNC password
3. **Firewall**: Keep port 5901 closed unless specifically needed
4. **SSH**: Use key-based SSH authentication for tunnel creation

## Alternative Configurations

### Using TigerVNC (Virtual Desktop)

If you prefer a separate virtual desktop instead of sharing the main session:

```bash
# Install tigervnc instead of x11vnc
# Start with: tigervncserver -localhost -geometry 1920x1080 -depth 24 :1
# Connect to display :1 instead of :0
```

### Systemd Service

For system-wide VNC service (instead of AwesomeWM autostart):

```bash
# Create: ~/.config/systemd/user/x11vnc.service
[Unit]
Description=x11vnc VNC Server
After=graphical-session.target

[Service]
Type=simple
ExecStart=/bin/sh -c 'pkill x11vnc; /run/current-system/sw/bin/x11vnc -display :0 -auth guess -forever -loop -noxdamage -repeat -rfbauth %h/.vnc/passwd -rfbport 5901'
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target

# Enable with: systemctl --user enable --now x11vnc
```

## Related Documentation

- [AwesomeWM Configuration](../awesome/README.md)
- [NixOS Configuration](./NixOS%20Configuration.md)
- [System Security](../WORK_MACHINE_SAFETY.md)