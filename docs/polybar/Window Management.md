# Window Management System

> Enhanced window restoration and navigation for AwesomeWM

## 🎯 Overview

The window management system provides comprehensive window restoration and navigation capabilities, solving the common issue of accessing minimized windows in AwesomeWM with multiple interaction methods and visual indicators.

## ✨ Key Features

### 🔄 **Window Restoration**
- **Cross-Workspace Access** - View and restore windows from any workspace
- **Intelligent Switching** - Automatically switches to correct workspace
- **Two-Step Process** - Workspace switch followed by window restoration
- **Race Condition Protection** - Proper delays prevent timing issues

### 🎨 **Visual Indicators**
- **Persistent Icon** - Always-visible window manager access (󰕰)
- **Dynamic Counts** - Shows minimized window count: `󰕰 (2)`
- **Workspace Indicators** - Shows which workspace contains windows
- **Status Icons** - Visual representation of window states

### 🖱️ **Multiple Access Methods**
- **Main Menu** - All windows from all workspaces
- **Current Workspace** - Windows from current workspace only
- **Minimized Only** - Quick access to minimized windows
- **Per-Workspace** - Right-click workspace numbers

## 🗂️ Implementation Structure

### **Scripts**
```
scripts/
├── executable_window-manager.sh     # Main window management logic
├── executable_awesome-workspaces.sh # Workspace integration
└── executable_window-menu.sh        # Legacy window menu (deprecated)
```

### **Polybar Configuration**
```ini
[module/window-manager]
type = custom/text
content = "󰕰"
click-left = ~/.config/polybar/scripts/window-manager.sh main
click-middle = ~/.config/polybar/scripts/window-manager.sh current
click-right = ~/.config/polybar/scripts/window-manager.sh minimized

[module/window-manager-count]
type = custom/script
exec = ~/.config/polybar/scripts/window-manager.sh display
interval = 1
```

## 🎮 Interactive Features

### **Window Manager Icon**
| Action | Result |
|--------|--------|
| **Left Click** | Show all windows from all workspaces |
| **Middle Click** | Show windows from current workspace only |
| **Right Click** | Show minimized windows only |
| **Hover** | Tooltip with usage instructions |

### **Workspace Integration**
| Action | Result |
|--------|--------|
| **Click Number** | Switch to workspace |
| **Right Click** | Show workspace-specific window menu |
| **Visual State** | Current/occupied/empty indicators |

## 🔧 Technical Implementation

### **Window Detection**
```lua
-- AwesomeWM Lua integration
local s = require("awful").screen.focused()
for tag_idx = 1, #s.tags do
    for i, c in ipairs(s.tags[tag_idx]:clients()) do
        local status = c.minimized and "minimized" or "visible"
        local name = c.name or c.class or "Unknown"
        -- Process window information
    end
end
```

### **Two-Step Restoration Process**
1. **Workspace Switch** - `awful.tag.viewonly(target_workspace)`
2. **Delay** - `sleep 0.1` to prevent race conditions
3. **Window Restoration** - `client.minimized = false; client:raise()`

### **Rofi Integration**
```bash
# Window menu display
choice=$(echo -e "$menu_entries" | rofi \
    -dmenu -i \
    -p "󰕰 Window Manager" \
    -theme-str 'window {width: 85%; height: 65%;}' \
    -no-custom -format 'i')
```

## 📊 Window Information Display

### **Menu Format**
```
[1] 󰖯 Terminal - bash
[2] 󰖲 Firefox - GitHub
[3] 󰖯 Code - project.js
[1] 󰀦 Urgent Window
```

### **Status Icons**
| Icon | Meaning |
|------|---------|
| `󰖯` | Visible window |
| `󰖲` | Minimized window |
| `󰀦` | Urgent window |
| `[1]` | Workspace number |
| `󰕰` | Window manager access |

### **Window States**
- **Current Workspace** - Highlighted differently
- **Other Workspaces** - Normal display
- **Minimized** - Special icon and handling
- **Urgent** - Priority display with alert icon

## 🎨 Visual Design

### **Polybar Integration**
- **Persistent Visibility** - Icon always present
- **Dynamic Updates** - Count updates every second
- **Consistent Theming** - Matches Catppuccin Macchiato
- **Tooltip Support** - Hover for usage instructions

### **Rofi Styling**
- **Window Sizing** - 85% width, 65% height
- **Consistent Theme** - Matches system rofi configuration
- **Keyboard Navigation** - Full keyboard support
- **Selection Highlighting** - Clear visual feedback

## 🔧 Configuration Options

### **Update Intervals**
```ini
[module/window-manager-count]
interval = 1  # Update every second
```

### **Rofi Customization**
```bash
# Theme customization
-theme-str 'window {width: 85%; height: 65%;}'
-theme-str 'listview {lines: 15;}'
-theme-str 'element {padding: 12px; border-radius: 8px;}'
```

### **Workspace Behavior**
- **Auto-switch** - Automatically switch to window's workspace
- **Focus Management** - Proper window focusing after restoration
- **Notification Feedback** - User feedback for actions

## 🛠️ Troubleshooting

### **Common Issues**

#### **Windows Not Restoring**
- **Cause** - Race condition between workspace switch and window restoration
- **Solution** - Two-step process with proper delays implemented

#### **Count Not Updating**
- **Cause** - AwesomeWM client not responding
- **Solution** - Restart AwesomeWM or check awesome-client connection

#### **Rofi Not Displaying**
- **Cause** - Display environment issues
- **Solution** - Check `DISPLAY` variable and X11 connection

### **Debug Commands**
```bash
# Test window detection
echo 'return #require("awful").screen.focused().selected_tag:clients()' | awesome-client

# Test window restoration
~/.config/polybar/scripts/window-manager.sh main

# Check polybar logs
tail -f /tmp/polybar.log
```

## 🔮 Future Enhancements

### **Planned Features**
- **Window Thumbnails** - Preview windows in menu
- **Grouping** - Group windows by application
- **Search** - Search windows by name or class
- **Keyboard Shortcuts** - Direct keyboard access

### **Integration Improvements**
- **Better Notifications** - Enhanced user feedback
- **Animation** - Smooth transitions
- **Customization** - More configuration options

## 🔗 Related Documentation

- **[[Polybar Overview]]** - Main polybar system documentation
- **[[Calendar System]]** - Calendar and clock implementation
- **[[Configuration]]** - Technical configuration reference
- **[[../system/NixOS Configuration]]** - System-level setup

---

*This window management system provides robust, user-friendly window restoration with multiple access methods and visual feedback.*
