# Polybar Configuration

A feature-rich polybar setup with Catppuccin Macchiato theme, designed to replace the default AwesomeWM wibar with enhanced functionality and modern aesthetics.

## Features

### 🎨 **Visual Design**
- **Catppuccin Macchiato** color scheme throughout
- **Rounded corners** and modern styling
- **JetBrains Mono Nerd Font** with icon support
- **Consistent spacing** and padding

### 📊 **System Monitoring**
- **CPU Usage** - Real-time CPU percentage with icon
- **Memory Usage** - RAM usage percentage with icon  
- **Temperature** - System temperature with warning colors
- **Filesystem** - Disk usage for root partition
- **Network** - Connection status and IP address
- **Battery** - Battery percentage with charging animations

### 🖥️ **Workspace Management**
- **AwesomeWM Integration** - Shows current workspace
- **Click to Switch** - Click workspace numbers to switch
- **Window Menu** - Shows minimized windows and allows restoration
- **Visual Indicators**:
  - Current workspace: highlighted with background
  - Workspaces with windows: normal brightness  
  - Empty workspaces: dimmed
  - Window count: shows number of minimized windows

### 🔊 **Audio & Media**
- **Volume Control** - Shows current volume, click to open pavucontrol
- **Media Player** - Current playing song with controls
  - Left click: play/pause
  - Right click: next track
  - Shows artist and title (truncated if long)

### 🔔 **Notifications**
- **Notification Counter** - Shows number of active notifications
- **Do Not Disturb** - Toggle DND mode
- **Clear All** - Click to clear all notifications
- **Visual States**:
  - Green: notifications enabled, none pending
  - Orange: notifications enabled, some pending
  - Gray: DND mode active

### ⚡ **System Controls**
- **Power Menu** - Shutdown, reboot, logout, lock options
- **System Updates** - Shows available updates (NixOS)
- **System Tray** - Standard system tray for other applications

### 📅 **Date & Time**
- **Full Date** - Day, month, date format
- **12-hour Time** - With AM/PM indicator
- **Custom formatting** with calendar icon

## File Structure

```
~/.config/polybar/
├── config.ini                 # Main polybar configuration
├── launch.sh                  # Launch script (kills existing, starts new)
└── scripts/
    ├── awesome-workspaces.sh   # AwesomeWM workspace integration
    ├── window-switcher.sh      # Enhanced window management with Alt+Tab
    ├── awesome-keybindings.lua # AwesomeWM keybinding examples
    ├── powermenu.sh           # Power menu with rofi
    ├── updates.sh             # System updates checker
    ├── notifications.sh       # Dunst notification control
    └── media.sh              # Media player integration
```

## Usage

### Starting Polybar
```bash
# Automatic start (integrated with AwesomeWM autostart)
# Manual start
~/.config/polybar/launch.sh
```

### AwesomeWM Integration
Polybar automatically replaces the default AwesomeWM wibar:
- The wibar creation is commented out in `rc.lua`
- Polybar is added to the autostart applications
- Workspace switching integrates with AwesomeWM tags

### Module Interactions

#### Workspace Module
- **Left click workspace number**: Switch to that workspace
- **Visual feedback**: Current workspace highlighted

#### Window Menu Module
- **Left click**: Open rofi menu with all windows in current workspace
- **Right click**: Open Alt+Tab style switcher for visible windows
- **Window selection**: Click to restore and focus minimized windows
- **Alt+Tab Integration**: Can be bound to Alt+Tab in AwesomeWM
- **Visual indicators**: 
  - Shows window icon ()
  - Displays count of minimized windows in parentheses
  - Menu shows  for minimized,  for visible windows
  - Alt+Tab mode shows  for focused,  for unfocused windows

#### Volume Module  
- **Right click**: Open pavucontrol for detailed audio control

#### Media Module
- **Left click**: Toggle play/pause
- **Right click**: Next track

#### Notifications Module
- **Left click**: Toggle Do Not Disturb mode
- **When notifications present**: Click to clear all

#### Power Menu
- **Left click**: Open rofi power menu with options:
  - Shutdown
  - Reboot  
  - Logout
  - Lock screen

#### Updates Module
- **Left click**: Open terminal with update command ready

## Customization

### Colors
Edit `[colors]` section in `config.ini` to modify the color scheme:
```ini
[colors]
background = #1e2030       # Main background
primary = #8bd5ca          # Accent color
foreground = #cad3f5       # Text color
alert = #ed8796            # Warning/error color
```

### Modules
Add or remove modules by editing the `modules-left`, `modules-center`, and `modules-right` lines in `config.ini`.

### Bar Position
Change bar position by modifying:
```ini
[bar/main]
bottom = false  # Set to true for bottom bar
```

### Fonts
Modify fonts in the `font-*` entries:
```ini
font-0 = "JetBrains Mono Nerd Font:size=10;2"
font-1 = "Font Awesome 6 Free:style=Solid:size=10;2"
```

## Dependencies

Required packages (already included in NixOS config):
- `polybar`
- `font-awesome` 
- `material-design-icons`
- `jetbrains-mono` (Nerd Font variant)
- `playerctl` (for media control)
- `dunst` (for notifications)
- `rofi` (for power menu)
- `pavucontrol` (for volume control)

## Troubleshooting

### Polybar not starting
Check if polybar is installed and the launch script is executable:
```bash
which polybar
ls -la ~/.config/polybar/launch.sh
```

### Workspace switching not working
Ensure AwesomeWM is running and awesome-client is available:
```bash
which awesome-client
echo 'return "test"' | awesome-client
```

### Icons not displaying
Install the required fonts:
```bash
# On NixOS, ensure these are in your configuration.nix:
fonts.packages = with pkgs; [
  font-awesome
  material-design-icons  
  jetbrains-mono
  nerd-fonts.jetbrains-mono
];
```

### Audio controls not working
Ensure PipeWire/PulseAudio is running:
```bash
systemctl --user status pipewire
which pavucontrol
```

## Integration with Themes

This polybar configuration is designed to work seamlessly with:
- **AwesomeWM** with Catppuccin Macchiato theme
- **Kitty terminal** with matching colors
- **Rofi** with Catppuccin theme
- **Dunst** notifications with matching colors

The entire desktop environment maintains visual consistency through the shared Catppuccin Macchiato color palette.
