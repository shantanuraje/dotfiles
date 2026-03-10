#!/usr/bin/env bash

# Keyboard Shortcuts Helper - rofi script mode
# Shows AwesomeWM keybindings as a searchable cheat sheet
# Add to unified palette: rofi -modi "keys:keybindings-mode.sh" -show keys

if [ -z "$1" ]; then
    echo -en "\0prompt\x1fShortcuts\n"
    echo -en "\0markup-rows\x1ftrue\n"

    cat <<'KEYS'
<span color="#ed8796">━━ Window Management ━━━━━</span>
<span color="#8bd5ca">Mod+Shift+C</span>    Close window
<span color="#8bd5ca">Mod+F</span>          Toggle fullscreen
<span color="#8bd5ca">Mod+Space</span>      Toggle floating
<span color="#8bd5ca">Mod+N</span>          Minimize window
<span color="#8bd5ca">Mod+Ctrl+N</span>     Restore minimized
<span color="#8bd5ca">Mod+M</span>          Toggle maximize
<span color="#8bd5ca">Mod+J/K</span>        Focus next/prev client
<span color="#8bd5ca">Mod+Shift+J/K</span>  Swap client next/prev
<span color="#8aadf4">━━ Layout ━━━━━━━━━━━━━━━━</span>
<span color="#8bd5ca">Mod+L/H</span>        Resize master wider/narrower
<span color="#8bd5ca">Mod+Shift+H</span>    Increase master count
<span color="#8bd5ca">Mod+Shift+L</span>    Decrease master count
<span color="#8bd5ca">Mod+Tab</span>        Next layout
<span color="#8bd5ca">Mod+Shift+Tab</span>  Previous layout
<span color="#a6da95">━━ Workspaces ━━━━━━━━━━━━</span>
<span color="#8bd5ca">Mod+1-9</span>        Switch to workspace
<span color="#8bd5ca">Mod+Shift+1-9</span>  Move window to workspace
<span color="#8bd5ca">Mod+Ctrl+1-9</span>   Toggle workspace view
<span color="#f5a97f">━━ Launch & Palette ━━━━━━━</span>
<span color="#8bd5ca">Mod+Return</span>     Terminal (Kitty)
<span color="#8bd5ca">Mod+E</span>          File Manager
<span color="#8bd5ca">Mod+Space</span>      Command Palette (Apps)
<span color="#8bd5ca">Mod+P</span>          Command Palette (Actions)
<span color="#8bd5ca">Mod+V</span>          Clipboard history
<span color="#8bd5ca">Mod+Shift+E</span>   Emoji picker
<span color="#8bd5ca">Mod+Shift+N</span>   Quick note to Inbox
<span color="#8bd5ca">Mod+/</span>         This shortcuts help
<span color="#c6a0f6">━━ Screenshot ━━━━━━━━━━━━</span>
<span color="#8bd5ca">Print</span>          Fullscreen capture
<span color="#8bd5ca">Mod+Print</span>      Area selection
<span color="#8bd5ca">Mod+Shift+Print</span> Active window
<span color="#f5bde6">━━ Media ━━━━━━━━━━━━━━━━━</span>
<span color="#8bd5ca">XF86Audio↑/↓</span>   Volume up/down
<span color="#8bd5ca">XF86AudioMute</span>  Toggle mute
<span color="#8bd5ca">XF86AudioPlay</span>  Play/pause
<span color="#8bd5ca">XF86AudioNext</span>  Next track
<span color="#8bd5ca">XF86AudioPrev</span>  Previous track
<span color="#eed49f">━━ System ━━━━━━━━━━━━━━━━</span>
<span color="#8bd5ca">Mod+Ctrl+R</span>     Reload AwesomeWM
<span color="#8bd5ca">Mod+Shift+M</span>    Quit AwesomeWM
<span color="#8bd5ca">Mod+L</span>          Lock screen
<span color="#91d7e3">━━ Bash Aliases (Terminal) ━</span>
<span color="#8bd5ca">rr</span>             Command Palette (Actions)
<span color="#8bd5ca">ra</span>             App Launcher
<span color="#8bd5ca">rw</span>             Window Switcher
<span color="#8bd5ca">rc</span>             Clipboard History
<span color="#8bd5ca">rcalc</span>          Calculator
<span color="#8bd5ca">re</span>             Emoji Picker
<span color="#8bd5ca">rn</span>             Quick Note to Inbox
<span color="#8bd5ca">rf</span>             File Search
<span color="#8bd5ca">rm_</span>            Media Control
<span color="#8bd5ca">rs</span>             Systemd Services
<span color="#8bd5ca">rk</span>             Keybindings (this)
KEYS
fi

# Read-only — selecting a line does nothing
exit 0
