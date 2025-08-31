# Catppuccin Macchiato Window Switcher for Rofi

A custom Rofi window switcher theme and scripts that perfectly match your AwesomeWM, Polybar, and Kitty Catppuccin Macchiato theme.

## Features

- **Themed Interface**: Matches Catppuccin Macchiato color scheme
- **Multiple Modes**: 
  - All windows across workspaces
  - Current workspace only
  - Minimized windows only
- **Window Icons**: Automatically detects and displays application icons
- **Workspace Indicators**: Visual indicators for workspace location
- **AwesomeWM Integration**: Full integration with window manager

## Installation

The files are already in place. Just apply the chezmoi configuration:

```bash
chezmoi apply
```

## Usage

### Command Line

```bash
# Show all windows
~/.config/rofi/bin/window-switcher-advanced.sh all

# Show current workspace windows only
~/.config/rofi/bin/window-switcher-advanced.sh current

# Show minimized windows only
~/.config/rofi/bin/window-switcher-advanced.sh minimized

# Simple window switcher
~/.config/rofi/bin/window-switcher.sh
```

### AwesomeWM Key Bindings

Add these to your `rc.lua`:

```lua
-- Include the window switcher keys
local window_switcher_keys = require("keys.window-switcher")

-- Add to your global keys
globalkeys = gears.table.join(
    globalkeys,
    window_switcher_keys
)
```

Default keybindings:
- `Alt+Tab`: Show all windows
- `Super+Tab`: Show current workspace windows
- `Super+Shift+Tab`: Show minimized windows
- `Super+w`: Quick window switcher

## Color Scheme

The theme uses Catppuccin Macchiato colors:

- Background: `#24273a` (base)
- Accent: `#8bd5ca` (teal - matches AwesomeWM active border)
- Text: `#cad3f5`
- Selected: `#c6a0f6` (mauve)
- Urgent: `#ed8796` (red)
- Active: `#a6da95` (green)

## Dependencies

Required:
- `rofi` - The main application launcher

Optional (for enhanced features):
- `wmctrl` - Window manipulation
- `xprop` - Window property detection
- `xdotool` - Additional window control

Install dependencies:
```bash
# On NixOS (add to configuration.nix)
environment.systemPackages = with pkgs; [
  rofi
  wmctrl
  xorg.xprop
  xdotool
];

# On other systems
sudo apt install rofi wmctrl x11-utils xdotool  # Debian/Ubuntu
sudo pacman -S rofi wmctrl xorg-xprop xdotool   # Arch
```

## Testing

Run the test script to verify everything is working:

```bash
~/.config/rofi/bin/test-window-switcher.sh
```

## Customization

### Modifying Colors

Edit `~/.config/rofi/config/window.rasi` to change colors. The color definitions are at the top of the file.

### Changing Window Display Format

Edit the advanced switcher script to modify how windows are displayed. Look for the `FORMAT` section.

### Adding More Keybindings

Edit `~/.config/awesome/keys/window-switcher.lua` to add more keybindings.

## Troubleshooting

1. **No windows showing**: Make sure `wmctrl` is installed
2. **Icons not showing**: Check that your icon theme is properly set
3. **Theme not loading**: Verify the theme file path in the scripts

## Integration with Polybar

You can also trigger the window switcher from Polybar by adding a custom module:

```ini
[module/window-switcher]
type = custom/text
content = 
click-left = ~/.config/rofi/bin/window-switcher-advanced.sh all
click-right = ~/.config/rofi/bin/window-switcher-advanced.sh current
```