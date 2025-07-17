# Enhanced Window Management for Polybar

## Overview
This enhanced window management system provides comprehensive window restoration and navigation capabilities for your Awesome WM setup, solving the common issue of accessing minimized windows.

## Problem Solved
- **Issue**: When windows are minimized in Awesome WM, there's no easy way to restore them
- **Solution**: Multiple accessible methods to view, navigate, and restore windows across all workspaces

## Features

### 1. Enhanced Workspace Display
- **Visual Indicators**: Workspaces show minimized window indicators (󰖲) when they contain minimized windows
- **Interactive Actions**: 
  - **Left-click**: Switch to workspace
  - **Right-click**: Show window menu for that workspace (if it has windows)
- **Smart Indicators**: Current workspace highlighted, occupied workspaces shown in normal color, empty workspaces dimmed

### 2. Always-Available Window Manager Module
- **Persistent Icon**: 󰕰 icon is always visible for quick window access
- **Dynamic Display**: Shows count of minimized windows in parentheses when available: `󰕰 (2)`
- **Multiple Access Methods**:
  - **Left-click**: Show all windows from all workspaces
  - **Middle-click**: Show windows from current workspace only
  - **Right-click**: Show minimized windows only

### 3. Comprehensive Window Menus
- **All Windows Menu**: Browse and restore any window from any workspace
- **Minimized Only Menu**: Quick access to restore minimized windows
- **Current Workspace Menu**: Focus on current workspace windows
- **Per-Workspace Menu**: Right-click any workspace to see its windows

### 4. Smart Window Information
- **Workspace Indicators**: `[1]`, `[2]`, etc. show which workspace contains each window
- **Status Icons**: 
  - `󰖯` - Visible window
  - `󰖲` - Minimized window
  - `󰀦` - Urgent window
- **Window Restoration**: Automatically switches to the correct workspace and restores/focuses the window

## Visual Indicators

| Icon | Meaning |
|------|---------|
| `󰖯` | Visible window |
| `󰖲` | Minimized window |
| `󰀦` | Urgent window |
| `[1]` | Workspace number indicator |
| `󰕰` | Window manager icon |
| `󰕰 (2)` | Window manager with 2 minimized windows |

## Usage

### Polybar Integration
The modules are automatically integrated into your polybar configuration:

1. **Enhanced Workspaces**: Click to switch, right-click for window menu
2. **Window Manager**: Always-visible icon with multiple click actions
3. **Tooltips**: Hover over icons for usage instructions

### Click Actions Summary
- **Workspace Numbers**: Left-click to switch, right-click for window menu
- **Window Manager Icon**: 
  - Left-click: All windows menu
  - Middle-click: Current workspace menu
  - Right-click: Minimized windows menu

### Manual Commands
```bash
# Show all windows across all workspaces
~/.config/polybar/scripts/window-manager.sh main

# Show only minimized windows
~/.config/polybar/scripts/window-manager.sh minimized

# Show current workspace windows
~/.config/polybar/scripts/window-manager.sh current

# Get count of minimized windows
~/.config/polybar/scripts/window-manager.sh count

# Display mode (for polybar)
~/.config/polybar/scripts/window-manager.sh display

# Show workspace-specific menu
~/.config/polybar/scripts/awesome-workspaces.sh menu-1

# Quick launcher
~/.config/polybar/scripts/window-launcher.sh all-windows
```

## Implementation Details

### Files Created/Modified
- `executable_awesome-workspaces.sh` - Enhanced workspace display with window menus
- `executable_window-manager.sh` - Comprehensive window management system
- `executable_workspace-windows.sh` - Workspace-specific window management
- `executable_window-launcher.sh` - Quick launcher utility
- `config.ini` - Updated polybar configuration with new modules

### Configuration Changes
```ini
# New modules in polybar config
modules-left = awesome-workspaces window-manager separator ...

[module/window-manager]
type = custom/script
exec = ~/.config/polybar/scripts/window-manager.sh display
# Multiple click actions for different window views
```

## Keybinding Integration

Add these to your Awesome WM `rc.lua` for keyboard shortcuts:

```lua
-- Window management shortcuts
awful.key({ modkey }, "w", function() 
    awful.spawn("~/.config/polybar/scripts/window-manager.sh main")
end, {description = "show all windows", group = "client"}),

awful.key({ modkey, "Shift" }, "w", function() 
    awful.spawn("~/.config/polybar/scripts/window-manager.sh minimized")
end, {description = "show minimized windows", group = "client"}),

awful.key({ modkey, "Control" }, "w", function() 
    awful.spawn("~/.config/polybar/scripts/window-manager.sh current")
end, {description = "show current workspace windows", group = "client"}),
```

## Rofi Integration

The window menus use rofi with custom styling that matches your Catppuccin theme:
- **Responsive sizing**: Adapts to content and screen size
- **Color coding**: Status indicators use consistent colors
- **Keyboard navigation**: Full keyboard support for selection

## Troubleshooting

### Common Issues
1. **Icon not visible**: Ensure polybar is restarted after configuration changes
2. **Scripts not executable**: Run `chmod +x ~/.config/polybar/scripts/executable_*.sh`
3. **Rofi not opening**: Ensure rofi is installed and configured
4. **No windows showing**: Check that awesome-client is working: `echo 'return "test"' | awesome-client`
5. **Notifications not working**: Install libnotify-bin or dunst

### Debug Commands
```bash
# Test awesome-client connection
echo 'return "test"' | awesome-client

# Test window detection
echo 'local s = require("awful").screen.focused(); local count = 0; for tag_idx = 1, #s.tags do for _, c in ipairs(s.tags[tag_idx]:clients()) do count = count + 1; end; end; return tostring(count)' | awesome-client

# Test script execution
~/.config/polybar/scripts/window-manager.sh display
```

## Current Status ✅

### Working Features
- ✅ Always-visible window manager icon
- ✅ Multiple window access methods (all/current/minimized)
- ✅ Workspace-specific window menus
- ✅ Visual indicators for minimized windows
- ✅ Automatic window restoration with workspace switching
- ✅ Rofi integration with custom theming
- ✅ Proper chezmoi integration

### Resolved Issues
- ✅ Icon disappearing when no minimized windows
- ✅ Window restoration across workspaces
- ✅ Script permissions and deployment
- ✅ Configuration file formatting
- ✅ Window restoration race condition (windows staying minimized after menu selection)

This implementation provides a complete, user-friendly solution for window management in Awesome WM, making it easy to access and restore any window regardless of its state or workspace location.
