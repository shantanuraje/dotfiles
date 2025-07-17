# Calendar and Clock Popup Documentation

## Overview
The date module in polybar now provides interactive calendar and clock popups with beautiful rofi-based interfaces that match your Catppuccin Macchiato theme.

## Features

### Multiple Click Actions
- **Left Click**: Opens a beautiful calendar popup showing the current month
- **Middle Click**: Opens a detailed clock popup with time zones and system info
- **Right Click**: Shows a quick notification with current date/time

### Calendar Popup
- **Monthly View**: Shows current month with highlighted today
- **Navigation**: Previous/Next month buttons
- **Week Numbers**: Displays week numbers for reference
- **Color Coded**: 
  - Today: Highlighted in cyan
  - Weekends: Highlighted in orange
  - Previous/Next month days: Dimmed
- **Theme**: Matches your Catppuccin Macchiato color scheme

### Clock Popup
- **Multiple Time Zones**: Shows local time plus UTC
- **System Information**: Includes uptime, load average, and system stats
- **Date Details**: Full date with day of year, week number
- **Color Coded**: Different colors for different types of information
- **Theme**: Consistent with your polybar theme

## Usage

### From Polybar
- Click the date/time display in your polybar
- Left click for calendar, middle click for clock, right click for notification
- Hover over the date module to see tooltip with click instructions

### Manual Commands
```bash
# Show calendar popup
~/.config/polybar/scripts/calendar-info.sh calendar

# Show clock popup
~/.config/polybar/scripts/calendar-info.sh clock

# Show notification
~/.config/polybar/scripts/calendar-info.sh notification
```

## Configuration

### Polybar Date Module
```ini
[module/date]
type = internal/date
interval = 1

date = %a %b %d
time = %I:%M %p

; Beautiful date/time with modern icon
format = <label>
format-prefix = "󰸗 "
format-prefix-foreground = ${colors.purple}
format-prefix-font = 2
label = %date% %time%
label-foreground = ${colors.foreground}
label-font = 1

; Hover tooltip with detailed date/time info
tooltip = true
tooltip-format = %A, %B %d, %Y | %I:%M:%S %p | Week %W of %Y | Day %j of %Y | Click: Left=Calendar, Middle=Clock, Right=Notification

; Interactive calendar with multiple actions
click-left = ~/.config/polybar/scripts/calendar-info.sh calendar
click-middle = ~/.config/polybar/scripts/calendar-info.sh clock
click-right = ~/.config/polybar/scripts/calendar-info.sh notification
```

### Color Scheme
The calendar and clock popups use your Catppuccin Macchiato colors:
- **Background**: `#1e2030`
- **Foreground**: `#cad3f5`
- **Accent**: `#8bd5ca` (cyan)
- **Warning**: `#f5a97f` (orange)
- **Error**: `#ed8796` (red)
- **Success**: `#a6da95` (green)

## Customization

### Calendar Appearance
You can modify the calendar script to change:
- Calendar layout and spacing
- Color scheme for different day types
- Additional information displayed
- Rofi theme and sizing

### Clock Information
The clock popup can be customized to show:
- Additional time zones
- More system information
- Different time formats
- Custom status information

## Dependencies
- `rofi` - For the popup interface
- `cal` - For calendar generation
- `date` - For date/time formatting
- `notify-send` - For notifications

## Files
- `executable_calendar-info.sh` - Main calendar and clock script
- `config.ini` - Polybar configuration with date module setup

## Troubleshooting

### Calendar Not Opening
- Check that rofi is installed and working
- Verify the script is executable: `chmod +x ~/.config/polybar/scripts/calendar-info.sh`
- Test the script directly: `~/.config/polybar/scripts/calendar-info.sh calendar`

### Click Not Working
- Ensure polybar is restarted after configuration changes
- Check that the click actions are properly configured in the date module
- Verify there are no syntax errors in the polybar config

### Styling Issues
- The popup uses rofi theming and should match your system theme
- Colors are hardcoded to match Catppuccin Macchiato
- Font sizing adapts to screen resolution

This provides a modern, beautiful calendar and clock interface that integrates seamlessly with your Awesome WM and polybar setup.
