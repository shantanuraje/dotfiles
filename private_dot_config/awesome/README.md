# AwesomeWM Configuration
*Replicating your Hyprland setup*

## 🎨 Features

Your AwesomeWM configuration perfectly matches your Hyprland setup:

### Visual Style
- **Catppuccin Macchiato** theme with exact color matching
- **10px rounded corners** (via picom)
- **Blur effects** and **shadows** (via picom)  
- **Cyan/green gradient borders** for active windows
- **Small gaps** (4px outer, matches Hyprland gaps)

### Applications & Tools
- **Terminal**: kitty
- **File Manager**: dolphin  
- **Launcher**: rofi
- **Wallpaper**: same forest_bridge.jpg
- **Notifications**: dunst

### Status Bar & Widgets
- **System info**: CPU, memory, temperature
- **Network & Bluetooth** indicators
- **Battery** status with charging indicators
- **Volume** controls with icons
- **Clock** with calendar popup
- **Package updates** counter

### Keybindings (Identical to Hyprland)
- **Super** as main modifier
- **Super + Return**: Terminal (kitty)
- **Super + E**: File manager (dolphin)
- **Super + Space**: App launcher (rofi)
- **Super + Q**: Close window
- **Super + V**: Toggle floating
- **Super + M**: Maximize/fullscreen
- **Super + H/J/K/L**: Navigate windows (vim-style)
- **Super + 1-0**: Switch workspaces
- **Super + Shift + 1-0**: Move window to workspace
- **Media keys**: Volume, brightness, playback controls

## 📁 File Structure

```
~/.config/awesome/
├── rc.lua                           # Main configuration
├── themes/catppuccin-macchiato/
│   └── theme.lua                    # Theme colors & styling
├── lain/                            # Widget library
├── freedesktop/                     # Application menu
├── install-packages.sh              # Package installer
├── packages-needed.md               # Required packages list
└── README.md                        # This file

~/.config/picom/
└── picom.conf                       # Compositor config (blur/shadows)
```

## 🚀 Quick Start

1. **Install packages**:
   ```bash
   cd ~/.config/awesome
   ./install-packages.sh
   ```

2. **Test configuration**:
   ```bash
   awesome -k -c ~/.config/awesome/rc.lua
   ```

3. **Switch to AwesomeWM**:
   - Log out
   - Select "Awesome" at login screen
   - Log in

## 🔧 Customization

### Change Theme Colors
Edit `~/.config/awesome/themes/catppuccin-macchiato/theme.lua`

### Modify Keybindings  
Edit the `globalkeys` section in `~/.config/awesome/rc.lua`

### Adjust Visual Effects
Edit `~/.config/picom/picom.conf` for blur/shadow settings

### Add/Remove Widgets
Modify the wibox setup section in `~/.config/awesome/rc.lua`

## 🔍 Differences from Hyprland

### What's the Same ✅
- All keybindings and shortcuts
- Visual appearance and colors
- Window management behavior
- Application launching
- Status bar information
- Blur, shadows, rounding effects

### What's Different 🔄
- **Window manager**: AwesomeWM instead of Hyprland
- **Compositor**: Picom instead of built-in Hyprland compositor
- **Status bar**: Native AwesomeWM wibar instead of Waybar
- **Protocol**: X11 instead of Wayland

## 🐛 Troubleshooting

### "attempt to compare nil with number" errors
This has been fixed in the configuration by adding proper nil checks to all widgets. If you still encounter this:
1. Restart AwesomeWM with `Mod4+Ctrl+R`
2. Check if the specific service (audio, battery, etc.) is available on your system

### Configuration doesn't load
```bash
awesome -k -c ~/.config/awesome/rc.lua
```

### Missing widgets/errors
Ensure lain library is installed:
```bash
ls ~/.config/awesome/lain/
```

### Blur/shadows not working
Check if picom is running:
```bash
pgrep picom
```

### Missing applications
Install missing packages from `packages-needed.md`

### Volume widget shows "N/A"
Install pamixer or pulseaudio:
```bash
# NixOS
nix-env -iA nixpkgs.pamixer
# Arch
sudo pacman -S pamixer
```

### Battery widget not working
Install acpi:
```bash
# NixOS  
nix-env -iA nixpkgs.acpi
# Arch
sudo pacman -S acpi
```

### Temperature widget shows "N/A"
Install lm-sensors:
```bash
# NixOS
nix-env -iA nixpkgs.lm_sensors
# Arch
sudo pacman -S lm_sensors
```

## 📚 Resources

- [AwesomeWM Documentation](https://awesomewm.org/doc/)
- [Lain Widgets](https://github.com/lcpz/lain)
- [Catppuccin Theme](https://github.com/catppuccin/catppuccin)
- [Picom Compositor](https://github.com/yshui/picom)

---

Your AwesomeWM setup is now configured to look and feel exactly like your Hyprland environment! 🎉