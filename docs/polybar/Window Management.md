# Window Management System

> VNC-friendly mouse-driven window management for AwesomeWM + Polybar

## Overview

The window management system provides mouse-based window controls accessible via Polybar buttons, designed for VNC remote access where Mod4 (Super) key is unavailable. All actions use `awesome-client` directly — no keyboard shortcuts required.

## Polybar Modules

### Launcher (󰍉)
App and window access with clear separation.

```ini
[module/launcher]
type = custom/text
content = "󰍉"
click-left = rofi -show drun    # Available programs only
click-right = rofi -show window # Open windows only
```

| Action | Result |
|--------|--------|
| **Left Click** | App launcher (programs) |
| **Right Click** | Window switcher (open windows) |

### WM Actions (󰣆)
Command palette for all window management — the VNC power tool.

```ini
[module/wm-actions]
type = custom/text
content = "󰣆"
click-left = ~/.config/polybar/scripts/wm-actions.sh
```

Opens a rofi menu with categorized actions:
- **Window actions**: Close, Maximize, Minimize, Fullscreen, Float, Restore
- **Navigation**: Switch to Workspace 1-10
- **Move**: Move focused window to Workspace 1-5
- **Launch**: Terminal, File Manager, App Launcher
- **Layout**: Next/Previous layout, Window Switcher
- **System**: Reload AwesomeWM

All actions use `awesome-client` — no Super key needed.

### Layout Indicator (󰙀 tile)
Shows and cycles current AwesomeWM layout.

```ini
[module/layout]
type = custom/script
exec = ~/.config/polybar/scripts/layout-indicator.sh
click-left = next layout
click-right = previous layout
scroll-up/down = cycle layouts
```

### Window Actions (focused window title)
Shows focused window title with direct actions.

```ini
[module/window-actions]
type = custom/script
exec = ~/.config/polybar/scripts/window-actions.sh
click-left = close window
click-right = toggle floating
click-middle = toggle fullscreen
scroll-up = move to next workspace
scroll-down = move to previous workspace
```

## Modules-Left Layout

```
launcher wm-actions | workspaces | layout | window-title | filesystem memory cpu temp
```

## Scripts

```
scripts/
├── executable_wm-actions.sh        # WM command palette (rofi + awesome-client)
├── executable_layout-indicator.sh   # Layout display + cycling
├── executable_window-actions.sh     # Window title + actions
├── executable_window-manager.sh     # Legacy window restoration (still available)
└── executable_awesome-workspaces.sh # Workspace indicators
```

## VNC Remote Access Notes

- **Android VNC viewers cannot send Super/Mod4 key** — this is a platform limitation
- **Ctrl+Alt combos also unreliable** over RealVNC Android viewer
- **Solution**: All essential WM operations accessible via mouse through Polybar buttons
- The WM Actions command palette (󰣆) provides access to every operation a keyboard shortcut would
- Physical keyboard users can still use all Mod4 shortcuts as normal

## Removed Modules

- `window-manager` / `window-manager-count` — replaced by `wm-actions` command palette
- VNC Ctrl+Alt keybindings in rc.lua — removed (unreliable over RealVNC Android)

## Related Documentation

- [[Polybar Overview]] — Main polybar documentation
- [[Calendar System]] — Eww calendar popup
- [[../system/VNC_Setup]] — VNC server configuration
