# Calendar & Clock System

> Interactive calendar and clock popups with rofi integration

## 🎯 Overview

The calendar and clock system provides beautiful, interactive popups accessible through the polybar date module, offering calendar views, world clock information, and quick notifications with consistent Catppuccin Macchiato theming.

## ✨ Key Features

### 📅 **Calendar Popup**
- **Monthly View** - Current month calendar with date highlighting
- **Date Information** - Current date, time, timezone, and week info
- **Moon Phase** - Approximate moon phase calculation
- **Event Placeholder** - Ready for calendar integration
- **Usage Tips** - Built-in customization guidance

### 🌍 **World Clock**
- **Multiple Time Zones** - UTC, EST, GMT, JST support
- **System Information** - Uptime and load average
- **Local Time** - Current timezone with detailed formatting
- **Clean Layout** - Organized, easy-to-read display

### 🔔 **Quick Notifications**
- **Compact Format** - Essential information only
- **Fast Access** - Instant display without blocking
- **System Integration** - Uses notify-send for consistency

## 🎮 Interactive Access

### **Date Module Click Actions**
| Action | Result |
|--------|--------|
| **Left Click** | Full calendar popup with monthly view |
| **Middle Click** | World clock with time zones |
| **Right Click** | Quick notification with current info |
| **Hover** | Tooltip with usage instructions |

### **Popup Features**
- **Rofi Integration** - Consistent theming with system
- **Keyboard Navigation** - Full keyboard support
- **Escape to Close** - Standard close behavior
- **No Selection Required** - Information display only

## 🗂️ Implementation Structure

### **Script Organization**
```
scripts/
├── executable_calendar-info.sh   # Main calendar system
├── executable_calendar-debug.sh  # Debug utility (testing)
└── other scripts...
```

### **Polybar Configuration**
```ini
[module/date]
type = internal/date
interval = 1
date = %a %b %d
time = %I:%M %p
click-left = bash ~/.config/polybar/scripts/calendar-info.sh calendar
click-middle = bash ~/.config/polybar/scripts/calendar-info.sh clock
click-right = bash ~/.config/polybar/scripts/calendar-info.sh notification
```

## 🎨 Visual Design

### **Calendar Popup Content**
```
🗓️  Thursday, July 17, 2025
🕐 02:30:45 PM
🌍 EDT -0400
📊 Week 29 of 2025 | Day 198 of 2025
🌕 Full Moon

📅 Calendar:
     July 2025
Mo Tu We Th Fr Sa Su
    1  2  3  4  5  6
 7  8  9 10 11 12 13
14 15 16 17 18 19 20
21 22 23 24 25 26 27
28 29 30 31

📝 Upcoming Events:
📅 No events configured
   Set up calendar integration in
   ~/.config/polybar/scripts/calendar-info.sh

💡 Tips:
• Click date again to refresh
• Integrate with your calendar app
• Customize in calendar-info.sh
```

### **World Clock Content**
```
🕐 02:30:45 PM
🌍 EDT -0400
📅 Thursday, July 17, 2025

⏰ Time Zones:
🌍 UTC: 18:30 UTC
🇺🇸 EST: 14:30 EST
🇬🇧 GMT: 19:30 BST
🇯🇵 JST: 03:30 JST

⏱️ System Info:
💻 Uptime: up 2 days, 5 hours, 30 minutes
🔋 Load: 0.15, 0.12, 0.08

Press Enter to close
```

## 🔧 Technical Implementation

### **Core Functions**
```bash
# Date and time information
get_date_info()     # Full date formatting
get_time_info()     # Time with seconds
get_timezone_info() # Timezone abbreviation and offset
get_week_info()     # Week and day of year

# Calendar features
get_calendar()      # Monthly calendar view
get_moon_phase()    # Approximate moon phase
get_upcoming_events() # Event placeholder

# Display functions
show_calendar_popup()     # Main calendar display
show_clock_popup()        # World clock display
show_calendar_notification() # Quick notification
```

### **Rofi Integration**
```bash
# Calendar popup configuration
echo "$popup_content" | rofi \
    -dmenu -i \
    -p "📅 Calendar & Clock" \
    -theme-str 'window {width: 600px; height: 500px;}' \
    -theme-str 'listview {lines: 20;}' \
    -theme-str 'element {padding: 8px; border-radius: 4px;}' \
    -theme-str 'element selected {background-color: #8bd5ca; text-color: #1e2030;}' \
    -no-custom -format 'i'
```

### **Environment Handling**
```bash
# Ensure display is available
export DISPLAY=${DISPLAY:-:0}

# Debug logging
echo "Calendar script called with argument: $1" >> /tmp/calendar-debug.log
echo "DISPLAY: $DISPLAY" >> /tmp/calendar-debug.log
```

## 📊 Information Display

### **Date Information**
- **Full Date** - "Thursday, July 17, 2025"
- **Time** - "02:30:45 PM" with seconds
- **Timezone** - "EDT -0400" with abbreviation and offset
- **Week Info** - "Week 29 of 2025 | Day 198 of 2025"

### **Calendar Features**
- **Monthly View** - Standard calendar layout
- **Current Day** - Highlighted in calendar (basic implementation)
- **Navigation** - Visual month/year display
- **Week Start** - Monday-based week format

### **Moon Phase Calculation**
```bash
# Approximate moon phase
local phase_days=$(( (day + month * 30 + (year - 2000) * 365) % 29 ))
case $phase_days in
    0|1|2) echo "🌑 New Moon" ;;
    3|4|5|6) echo "🌒 Waxing Crescent" ;;
    # ... other phases
esac
```

## 🎨 Theming & Styling

### **Catppuccin Macchiato Colors**
```bash
COLOR_BG="#1e2030"        # Background
COLOR_FG="#cad3f5"        # Foreground
COLOR_ACCENT="#8bd5ca"    # Accent (cyan)
COLOR_SECONDARY="#8aadf4" # Secondary (blue)
COLOR_HIGHLIGHT="#f5bde6" # Highlight (pink)
```

### **Rofi Styling**
- **Window Size** - 600x500px for calendar, 500x400px for clock
- **Element Padding** - 8px with 4px border radius
- **Selection Color** - Matches accent color
- **Consistent Theme** - Matches system rofi configuration

## 🔧 Configuration Options

### **Script Usage**
```bash
# Available commands
./calendar-info.sh calendar     # Show calendar popup (default)
./calendar-info.sh clock        # Show world clock
./calendar-info.sh notification # Show quick notification
./calendar-info.sh help         # Show usage information
```

### **Customization Points**
- **Time Zones** - Edit `show_clock_popup()` function
- **Calendar Format** - Modify `get_calendar()` function
- **Event Integration** - Implement `get_upcoming_events()`
- **Styling** - Adjust rofi theme-str parameters

## 🛠️ Troubleshooting

### **Common Issues**

#### **Popups Not Appearing**
- **Cause** - Display environment or rofi configuration
- **Solution** - Check `DISPLAY` variable and rofi functionality
- **Test** - Run `echo "test" | rofi -dmenu` directly

#### **Script Not Called**
- **Cause** - Polybar click actions not registered
- **Solution** - Restart polybar completely
- **Debug** - Check `/tmp/calendar-debug.log`

#### **Formatting Issues**
- **Cause** - Date command or emoji rendering
- **Solution** - Check system locale and font support
- **Test** - Run individual functions manually

### **Debug Commands**
```bash
# Test script directly
bash ~/.config/polybar/scripts/calendar-info.sh calendar

# Check debug log
tail -f /tmp/calendar-debug.log

# Test rofi integration
cat /tmp/rofi-debug.log

# Verify display
echo $DISPLAY
```

## 🔮 Future Enhancements

### **Planned Features**
- **Calendar Navigation** - Previous/next month buttons
- **Event Integration** - Google Calendar, iCal support
- **Current Day Highlighting** - Better visual indication
- **Holiday Information** - Holiday display and recognition

### **Visual Improvements**
- **Calendar Themes** - Multiple visual styles
- **Animation** - Smooth transitions
- **Weather Integration** - Weather information display
- **Customizable Layout** - User-configurable displays

### **Integration Features**
- **Keyboard Shortcuts** - Direct access keys
- **Reminder System** - Notification scheduling
- **Task Integration** - Todo list connection
- **Multi-Calendar** - Multiple calendar sources

## 🔗 Related Documentation

- **[[Polybar Overview]]** - Main polybar system documentation
- **[[Window Management]]** - Window management features
- **[[Configuration]]** - Technical configuration reference
- **[[../system/NixOS Configuration]]** - System-level setup

---

*The calendar and clock system provides beautiful, functional date and time access with multiple interaction modes and consistent theming.*
