#!/usr/bin/env bash

# WM Command Palette for VNC users
# Opens a rofi menu with window management actions using awesome-client
# No Super/Mod4 key needed — all actions are mouse-clickable

THEME="$HOME/.config/rofi/config/app-launcher.rasi"

# Build menu entries: "icon  label" format
# Grouped by category with headers
MENU=$(cat <<'EOF'
 Close Window
󰖲 Toggle Floating
󰊓 Toggle Fullscreen
󰁌 Toggle Maximize
󰖰 Minimize Window
󰶐 Restore Minimized
 Open Terminal
 File Manager
 App Launcher
󰙀 Next Layout
󰙁 Previous Layout
󰍉 Window Switcher
 Workspace 1
 Workspace 2
 Workspace 3
 Workspace 4
 Workspace 5
 Workspace 6
 Workspace 7
 Workspace 8
 Workspace 9
 Workspace 10
󰁔 Move to Workspace 1
󰁔 Move to Workspace 2
󰁔 Move to Workspace 3
󰁔 Move to Workspace 4
󰁔 Move to Workspace 5
 Reload AwesomeWM
EOF
)

CHOICE=$(echo "$MENU" | rofi -dmenu -i -p "WM Actions" -theme "$THEME" 2>/dev/null)

[ -z "$CHOICE" ] && exit 0

case "$CHOICE" in
    *"Close Window"*)
        echo 'if client.focus then client.focus:kill() end' | awesome-client
        ;;
    *"Toggle Floating"*)
        echo 'if client.focus then client.focus.floating = not client.focus.floating end' | awesome-client
        ;;
    *"Toggle Fullscreen"*)
        echo 'if client.focus then client.focus.fullscreen = not client.focus.fullscreen; client.focus:raise() end' | awesome-client
        ;;
    *"Toggle Maximize"*)
        echo 'if client.focus then client.focus.maximized = not client.focus.maximized; client.focus:raise() end' | awesome-client
        ;;
    *"Minimize Window"*)
        echo 'if client.focus then client.focus.minimized = true end' | awesome-client
        ;;
    *"Restore Minimized"*)
        echo 'local c = require("awful").client.restore(); if c then c:emit_signal("request::activate", "key.unminimize", {raise = true}) end' | awesome-client
        ;;
    *"Open Terminal"*)
        echo 'require("awful").spawn("kitty")' | awesome-client
        ;;
    *"File Manager"*)
        echo 'require("awful").spawn("nautilus")' | awesome-client
        ;;
    *"App Launcher"*)
        rofi -show drun -theme "$THEME"
        ;;
    *"Next Layout"*)
        echo 'require("awful").layout.inc(1)' | awesome-client
        ;;
    *"Previous Layout"*)
        echo 'require("awful").layout.inc(-1)' | awesome-client
        ;;
    *"Window Switcher"*)
        bash ~/.config/rofi/bin/window-switcher-advanced.sh all
        ;;
    *"Move to Workspace "*)
        NUM=$(echo "$CHOICE" | grep -o '[0-9]*$')
        echo "local awful = require('awful'); local c = client.focus; if c then local tag = c.screen.tags[${NUM}]; if tag then c:move_to_tag(tag); tag:view_only() end end" | awesome-client
        ;;
    *"Workspace "*)
        NUM=$(echo "$CHOICE" | grep -o '[0-9]*$')
        echo "local awful = require('awful'); local s = awful.screen.focused(); local tag = s.tags[${NUM}]; if tag then tag:view_only() end" | awesome-client
        ;;
    *"Reload AwesomeWM"*)
        echo 'awesome.restart()' | awesome-client
        ;;
esac
