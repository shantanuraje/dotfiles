#!/usr/bin/env bash

# WM Actions - rofi script mode
# Used as a custom mode in the unified command palette:
#   rofi -modi "actions:wm-actions-mode.sh" -show actions
#
# In script mode, rofi calls this script:
#   - With no args: output menu items (one per line)
#   - With $1 = selected item: execute the action

# Screenshot helper script — spawned detached via awesome so rofi releases its grab first
SCREENSHOT_HELPER="$HOME/.config/rofi/bin/screenshot-helper.sh"

if [ -z "$1" ]; then
    # No argument — output menu items
    # Script mode uses \0key\x1fvalue for metadata (must use echo -e for real escapes)
    echo -en "\0markup-rows\x1ftrue\n"
    echo -en "\0prompt\x1fActions\n"

    # Window management
    echo '<span color="#ed8796">━━ Window ━━━━━━━━━━━━━━━━</span>'
    echo '󰅖  Close Window'
    echo '󰖲  Toggle Floating'
    echo '󰊓  Toggle Fullscreen'
    echo '󰁌  Toggle Maximize'
    echo '󰖰  Minimize Window'
    echo '󰶐  Restore Minimized'

    # Navigation & Layout
    echo '<span color="#8aadf4">━━ Navigate ━━━━━━━━━━━━━━</span>'
    echo '󰙀  Next Layout'
    echo '󰙁  Previous Layout'
    echo '󰞷  Open Terminal'
    echo '󰉋  File Manager'

    # Screenshots
    echo '<span color="#f5a97f">━━ Screenshot ━━━━━━━━━━━━</span>'
    echo '󰍹  Capture Desktop'
    echo '󰆞  Capture Area'
    echo '󰖯  Capture Window'
    echo '󰔝  Capture in 3s'
    echo '󰔜  Capture in 10s'

    # System
    echo '<span color="#c6a0f6">━━ System ━━━━━━━━━━━━━━━━</span>'
    echo '󰑓  Reload AwesomeWM'
else
    # Argument provided — execute the matching action
    ACTION="$1"

    # Skip header lines
    [[ "$ACTION" == *"━━"* ]] && exit 0

    case "$ACTION" in
        *"Close Window"*)
            echo 'if client.focus then client.focus:kill() end' | awesome-client ;;
        *"Toggle Floating"*)
            echo 'if client.focus then client.focus.floating = not client.focus.floating end' | awesome-client ;;
        *"Toggle Fullscreen"*)
            echo 'if client.focus then client.focus.fullscreen = not client.focus.fullscreen; client.focus:raise() end' | awesome-client ;;
        *"Toggle Maximize"*)
            echo 'if client.focus then client.focus.maximized = not client.focus.maximized; client.focus:raise() end' | awesome-client ;;
        *"Minimize Window"*)
            echo 'if client.focus then client.focus.minimized = true end' | awesome-client ;;
        *"Restore Minimized"*)
            echo 'local c = require("awful").client.restore(); if c then c:emit_signal("request::activate", "key.unminimize", {raise = true}) end' | awesome-client ;;
        *"Next Layout"*)
            echo 'require("awful").layout.inc(1)' | awesome-client ;;
        *"Previous Layout"*)
            echo 'require("awful").layout.inc(-1)' | awesome-client ;;
        *"Open Terminal"*)
            echo 'require("awful").spawn("kitty")' | awesome-client ;;
        *"File Manager"*)
            echo 'require("awful").spawn("nautilus")' | awesome-client ;;
        *"Capture Desktop"*)
            echo "require('awful').spawn.with_shell('$SCREENSHOT_HELPER full')" | awesome-client ;;
        *"Capture Area"*)
            echo "require('awful').spawn.with_shell('$SCREENSHOT_HELPER area')" | awesome-client ;;
        *"Capture Window"*)
            echo "require('awful').spawn.with_shell('$SCREENSHOT_HELPER window')" | awesome-client ;;
        *"Capture in 3s"*)
            echo "require('awful').spawn.with_shell('$SCREENSHOT_HELPER full 3')" | awesome-client ;;
        *"Capture in 10s"*)
            echo "require('awful').spawn.with_shell('$SCREENSHOT_HELPER full 10')" | awesome-client ;;
        *"Reload AwesomeWM"*)
            echo 'awesome.restart()' | awesome-client ;;
    esac
fi
