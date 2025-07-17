# Polybar System Overview

> Modern, feature-rich status bar implementation with AwesomeWM integration

## 🎯 Overview

This polybar configuration replaces the default AwesomeWM wibar with a modern, highly functional status bar featuring the Catppuccin Macchiato theme, interactive modules, and comprehensive system monitoring.

## ✨ Key Features

### 🎨 **Visual Design**
- **Catppuccin Macchiato** color scheme throughout
- **Modern Typography** - JetBrains Mono Nerd Font with icon support
- **Rounded Corners** and consistent spacing
- **Responsive Design** - Adapts to different screen sizes

### 🖥️ **Interactive Modules**
- **[[Window Management]]** - Enhanced window restoration and navigation
- **[[Calendar System]]** - Interactive calendar and clock popups
- **Workspace Integration** - Seamless AwesomeWM workspace management
- **System Controls** - Volume, power, notifications

### 📊 **System Monitoring**
- **CPU Usage** - Real-time CPU percentage with core indicators
- **Memory Usage** - RAM usage with detailed tooltips
- **Temperature** - System temperature with warning colors
- **Network Status** - Connection status and IP display
- **Storage** - Disk usage monitoring

## 🗂️ Configuration Structure

```
private_dot_config/polybar/
├── config.ini                    # Main polybar configuration
├── executable_launch.sh          # Polybar startup script
├── scripts/                      # Interactive scripts
│   ├── executable_calendar-info.sh      # Calendar and clock system
│   ├── executable_window-manager.sh     # Window management
│   ├── executable_awesome-workspaces.sh # Workspace integration
│   └── executable_*.sh                  # Other utility scripts
└── docs/                         # Documentation (moved to /docs/polybar/)
```

## 🔧 Module Configuration

### **Left Section**
- **Workspaces** - AwesomeWM workspace indicators with click-to-switch
- **Window Manager** - Always-visible window restoration access
- **System Stats** - CPU, memory, temperature monitoring

### **Center Section**
- **Date/Time** - Interactive calendar with multiple click actions
- **Uptime** - System uptime display

### **Right Section**
- **Audio** - Volume control with pavucontrol integration
- **Network** - Connection status and IP address
- **Notifications** - Notification management
- **System Tray** - Standard application tray

## 🎮 Interactive Features

### **Calendar System**
- **Left Click** - Full calendar popup with monthly view
- **Middle Click** - World clock with multiple time zones
- **Right Click** - Quick notification with current info

### **Window Management**
- **Left Click** - All windows from all workspaces
- **Middle Click** - Current workspace windows only
- **Right Click** - Minimized windows only

### **Workspace Integration**
- **Click Numbers** - Switch to workspace
- **Right Click** - Show workspace-specific window menu
- **Visual Indicators** - Active, occupied, and empty workspace states

## 🎨 Theming

### **Color Scheme (Catppuccin Macchiato)**
```ini
background = #1e2030
foreground = #cad3f5
primary = #8bd5ca
alert = #ed8796
disabled = #6e738d
```

### **Typography**
- **Primary Font** - JetBrains Mono Nerd Font
- **Icons** - Font Awesome 6 + Material Design Icons
- **Sizing** - Responsive sizing based on screen DPI

## 🔧 Installation & Setup

### **Prerequisites**
- AwesomeWM window manager
- Polybar installed via NixOS configuration
- Required fonts (automatically installed)

### **Activation**
```bash
# Launch polybar (handled automatically by AwesomeWM)
polybar main -c ~/.config/polybar/config.ini

# Test configuration
polybar --config-test ~/.config/polybar/config.ini
```

### **Integration with AwesomeWM**
The polybar integrates seamlessly with AwesomeWM:
- Replaces default wibar
- Maintains all workspace functionality
- Adds enhanced window management
- Provides system monitoring

## 🔍 Advanced Features

### **Rofi Integration**
- Calendar popups use rofi for consistent theming
- Window menus match system-wide rofi configuration
- Keyboard navigation supported

### **Notification System**
- Dunst integration for notification management
- Do Not Disturb mode toggle
- Clear all notifications functionality

### **Media Controls**
- Playerctl integration for media control
- Current track display
- Play/pause/next controls

## 🛠️ Customization

### **Adding New Modules**
1. Create script in `scripts/` directory
2. Add module definition to `config.ini`
3. Include in appropriate modules section

### **Theming Modifications**
- Colors defined in `[colors]` section
- Font configuration in `[bar/main]`
- Module-specific styling in individual module sections

### **Script Development**
- Follow existing script patterns
- Use consistent error handling
- Include debug logging
- Document functionality

## 📊 Performance

### **Resource Usage**
- **Memory** - ~15-20MB typical usage
- **CPU** - <1% during normal operation
- **Updates** - Configurable intervals per module

### **Optimization**
- Efficient update intervals
- Minimal external dependencies
- Cached data where appropriate

## 🐛 Troubleshooting

### **Common Issues**
- **Polybar not starting** - Check AwesomeWM integration
- **Modules not updating** - Verify script permissions
- **Font issues** - Ensure fonts are installed
- **Click actions not working** - Restart polybar

### **Debug Commands**
```bash
# Test configuration
polybar --config-test ~/.config/polybar/config.ini

# Debug mode
polybar main -c ~/.config/polybar/config.ini -l debug

# Check logs
tail -f /tmp/polybar.log
```

## 🔗 Related Documentation

- **[[Window Management]]** - Detailed window management features
- **[[Calendar System]]** - Calendar and clock implementation
- **[[Configuration]]** - Technical configuration reference
- **[[../system/NixOS Configuration]]** - System-level configuration

---

*This overview provides a comprehensive look at the polybar system. For specific features, see the linked documentation pages.*
