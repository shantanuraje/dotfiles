# Polybar Configuration Reference

> Technical configuration reference for polybar setup

## 🎯 Overview

This document provides technical reference for the polybar configuration, including module definitions, styling options, and integration scripts.

## 📁 File Structure

```
private_dot_config/polybar/
├── config.ini                    # Main configuration file
├── executable_launch.sh          # Polybar startup script
├── README.md                     # User documentation
└── scripts/                      # Interactive scripts
    ├── executable_awesome-workspaces.sh
    ├── executable_calendar-info.sh
    ├── executable_window-manager.sh
    └── executable_*.sh
```

## 🎨 Color Scheme

### **Catppuccin Macchiato Colors**
```ini
[colors]
background = #1e2030
background-alt = #363a4f
foreground = #cad3f5
primary = #8bd5ca
alert = #ed8796
disabled = #6e738d

; Extended colors
cyan = #8bd5ca
green = #a6da95
yellow = #eed49f
orange = #f5a97f
red = #ed8796
pink = #f5bde6
purple = #c6a0f6
blue = #8aadf4
```

### **Color Usage**
- **Background**: Main bar background
- **Foreground**: Primary text color
- **Primary**: Accent color (cyan)
- **Alert**: Error/warning color (red)
- **Disabled**: Inactive elements (muted)

## 🔧 Bar Configuration

### **Main Bar Settings**
```ini
[bar/main]
monitor = ${env:MONITOR:}
width = 100%
height = 2.2%
radius = 6

bottom = false
fixed-center = true

background = ${colors.background}
foreground = ${colors.foreground}

border-size = 2pt
border-color = ${colors.background-alt}

padding-left = 1
padding-right = 1
module-margin = 1
```

### **Font Configuration**
```ini
font-0 = "JetBrains Mono Nerd Font:size=10;2"
font-1 = "Font Awesome 6 Free:style=Solid:size=10;2"
font-2 = "Font Awesome 6 Brands:size=10;2"
font-3 = "Material Design Icons:size=12;3"
```

## 📊 Module Configuration

### **Module Layout**
```ini
modules-left = awesome-workspaces window-manager window-manager-count separator filesystem memory cpu temperature
modules-center = date uptime
modules-right = load separator pulseaudio separator network separator notifications separator systray
```

### **Core Modules**

#### **Date Module**
```ini
[module/date]
type = internal/date
interval = 1

date = %a %b %d
time = %I:%M %p

format = <label>
format-prefix = "󰸗 "
format-prefix-foreground = ${colors.purple}
format-prefix-font = 2
label = %date% %time%

tooltip = true
tooltip-format = %A, %B %d, %Y | %I:%M:%S %p | Week %W of %Y | Day %j of %Y | Click: Left=Calendar, Middle=Clock, Right=Notification

click-left = bash ~/.config/polybar/scripts/calendar-info.sh calendar
click-middle = bash ~/.config/polybar/scripts/calendar-info.sh clock
click-right = bash ~/.config/polybar/scripts/calendar-info.sh notification
```

#### **Window Manager Module**
```ini
[module/window-manager]
type = custom/text
content = "󰕰"
content-foreground = ${colors.cyan}
content-font = 2
click-left = ~/.config/polybar/scripts/window-manager.sh main
click-middle = ~/.config/polybar/scripts/window-manager.sh current
click-right = ~/.config/polybar/scripts/window-manager.sh minimized
tooltip = "Window Manager: Left=All Windows, Middle=Current Workspace, Right=Minimized Only"
format-padding = 1

[module/window-manager-count]
type = custom/script
exec = ~/.config/polybar/scripts/window-manager.sh display
interval = 1
format = <label>
label = %output%
```

#### **Workspace Module**
```ini
[module/awesome-workspaces]
type = custom/script
exec = ~/.config/polybar/scripts/awesome-workspaces.sh
interval = 0.1
format = <label>
```

#### **System Monitoring**
```ini
[module/cpu]
type = internal/cpu
interval = 2
format = <label> <ramp-coreload>
format-prefix = "󰘚 "
format-prefix-foreground = ${colors.blue}
format-prefix-font = 2
label = %percentage:2%%

ramp-coreload-spacing = 1
ramp-coreload-0 = ▁
ramp-coreload-1 = ▂
ramp-coreload-2 = ▃
ramp-coreload-3 = ▄
ramp-coreload-4 = ▅
ramp-coreload-5 = ▆
ramp-coreload-6 = ▇
ramp-coreload-7 = █

[module/memory]
type = internal/memory
interval = 2
format = <label>
format-prefix = "󰍛 "
format-prefix-foreground = ${colors.green}
format-prefix-font = 2
label = %percentage_used:2%%

[module/temperature]
type = internal/temperature
thermal-zone = 0
base-temperature = 20
warn-temperature = 80
format = <ramp> <label>
format-warn = <ramp> <label-warn>
label = %temperature-c%
label-warn = %temperature-c%
label-warn-foreground = ${colors.alert}

ramp-0 = "🧊"
ramp-1 = "❄️"
ramp-2 = "🌡️"
ramp-3 = "🔥"
```

## 🔧 Script Integration

### **Script Execution**
```ini
; Script modules use custom/script type
[module/script-name]
type = custom/script
exec = ~/.config/polybar/scripts/script-name.sh
interval = 1
format = <label>
click-left = ~/.config/polybar/scripts/script-name.sh action
```

### **Interactive Scripts**
- **calendar-info.sh**: Calendar and clock popups
- **window-manager.sh**: Window management functionality
- **awesome-workspaces.sh**: Workspace integration
- **notifications.sh**: Notification management
- **media.sh**: Media player controls

## 🎨 Styling Options

### **Module Styling**
```ini
format = <label>
format-prefix = "icon "
format-prefix-foreground = ${colors.accent}
format-prefix-font = 2
label = %output%
label-foreground = ${colors.foreground}
label-font = 1
```

### **Tooltip Configuration**
```ini
tooltip = true
tooltip-format = Detailed information
exec-tooltip = script-for-dynamic-tooltip.sh
```

### **Click Actions**
```ini
click-left = command-or-script
click-middle = command-or-script
click-right = command-or-script
scroll-up = command-or-script
scroll-down = command-or-script
```

## 🔧 AwesomeWM Integration

### **Workspace Communication**
```lua
-- Get workspace information
echo 'return require("awful").screen.focused().selected_tag.index' | awesome-client

-- Switch workspace
echo 'require("awful").screen.focused().tags[1]:view_only()' | awesome-client

-- Get window information
echo 'return #require("awful").screen.focused().selected_tag:clients()' | awesome-client
```

### **Window Management**
```lua
-- Minimize window
echo 'require("awful").client.focused().minimized = true' | awesome-client

-- Restore window
echo 'require("awful").client.focused().minimized = false' | awesome-client

-- Focus window
echo 'require("awful").client.focus.byidx(0)' | awesome-client
```

## 🚀 Startup Configuration

### **Launch Script**
```bash
#!/usr/bin/env bash
# executable_launch.sh

# Kill existing polybar instances
killall -q polybar

# Wait for processes to shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch polybar
polybar main -c ~/.config/polybar/config.ini &
```

### **AwesomeWM Integration**
```lua
-- In awesome/rc.lua
awful.spawn.with_shell("~/.config/polybar/launch.sh")
```

## 🐛 Troubleshooting

### **Common Issues**

#### **Polybar Not Starting**
```bash
# Check configuration
polybar --config-test ~/.config/polybar/config.ini

# Debug launch
polybar main -c ~/.config/polybar/config.ini -l debug
```

#### **Modules Not Working**
```bash
# Check script permissions
chmod +x ~/.config/polybar/scripts/*.sh

# Test script directly
bash ~/.config/polybar/scripts/script-name.sh
```

#### **Font Issues**
```bash
# List available fonts
fc-list | grep "JetBrains Mono"

# Install missing fonts
# (handled by NixOS configuration)
```

### **Debug Commands**
```bash
# Check polybar process
ps aux | grep polybar

# Monitor logs
tail -f /tmp/polybar.log

# Test modules
polybar-msg cmd show
polybar-msg cmd hide
```

## 🔧 Customization

### **Adding New Modules**
1. Define module in `config.ini`
2. Create script in `scripts/` directory
3. Add to appropriate modules section
4. Test and debug

### **Modifying Colors**
1. Update `[colors]` section
2. Reference colors in modules: `${colors.name}`
3. Restart polybar to apply changes

### **Adjusting Layout**
1. Modify `modules-left`, `modules-center`, `modules-right`
2. Add/remove separator modules as needed
3. Adjust spacing and padding

## 🔗 Related Documentation

- **[[Polybar Overview]]** - General polybar documentation
- **[[Window Management]]** - Window management features
- **[[Calendar System]]** - Calendar and clock system
- **[[../system/NixOS Configuration]]** - System-level configuration

---

*This configuration reference provides technical details for customizing and maintaining the polybar setup.*
