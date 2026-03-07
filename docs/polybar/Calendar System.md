# Calendar & Clock System

> Eww-based calendar popup with Catppuccin Macchiato theming

## Overview

The calendar system uses **eww** (ElKowar's Wacky Widgets) to display a themed GTK calendar popup from the Polybar date module. This replaced an earlier rofi-based implementation that had rendering issues.

## Architecture

```
Polybar date click → eww open/close calendar-popup
                          ↓
                    ~/.config/eww/
                    ├── eww.yuck   (widget structure + variables)
                    └── eww.scss   (Catppuccin Macchiato styling)
```

## Polybar Integration

```ini
[module/date]
type = internal/date
; Left click toggles eww calendar popup
click-left = bash -c 'eww active-windows | grep -q calendar-popup && eww close calendar-popup || eww open calendar-popup'
; Right click shows quick notification
click-right = bash ~/.config/polybar/scripts/calendar-info.sh notification
```

| Action | Result |
|--------|--------|
| **Left Click** | Toggle eww calendar popup |
| **Right Click** | Quick notification via notify-send |

## Eww Calendar Popup

### Content
- **Header**: Large time display, full date, week/day-of-year info
- **Calendar**: Native GTK calendar widget (proper grid, click navigation, day highlighting)
- **World Clocks**: UTC, EST, GMT, IST, JST
- **System**: Uptime

### Variables (polled)
```yuck
(defpoll time-hour :interval "1s" "date '+%I:%M %p'")
(defpoll time-date :interval "60s" "date '+%A, %B %-d, %Y'")
(defpoll tz-utc :interval "60s" "TZ=UTC date '+%H:%M'")
; ... other timezone polls
```

### Theming
Styled with SCSS using exact Catppuccin Macchiato palette:
- `$base: #24273a` — popup background
- `$mantle: #1e2030` — header background
- `$mauve: #c6a0f6` — border, accent, today highlight
- `$teal: #8bd5ca` — section titles
- Font: JetBrains Mono Nerd Font

### Window Properties
```yuck
(defwindow calendar-popup
  :monitor 0
  :geometry (geometry :x "0%" :y "8px" :width "340px" :anchor "top center")
  :stacking "overlay"
  :focusable true)
```

## NixOS Dependency

Eww must be installed via NixOS:
```nix
# In system_nixos/machines/shared/system-common.nix
environment.systemPackages = [ eww ];
```

## Legacy: Rofi Calendar (deprecated)

The script `calendar-info.sh` still exists for the `notification` mode (right-click). The rofi calendar popup mode had issues:
- Pipe from subshell `while` loop lost data
- Monospace `cal` output looked cramped in rofi list entries
- Not a real calendar widget — just text lines in a dmenu

## Troubleshooting

```bash
# Test eww directly
eww open calendar-popup
eww close calendar-popup

# Check eww logs
eww logs

# Verify eww config
eww inspector
```

## Related Documentation

- [[Polybar Overview]] — Main polybar documentation
- [[Window Management]] — Window management modules
