#!/usr/bin/env bash

# Notification script for polybar
# Shows dunst notification count and controls

case "$1" in
    --toggle-dnd)
        # Toggle Do Not Disturb
        if dunstctl is-paused; then
            dunstctl set-paused false
            notify-send "Notifications" "Enabled" -i notification-symbolic
        else
            dunstctl set-paused true
            notify-send "Notifications" "Paused (DND Mode)" -i notification-symbolic
        fi
        ;;
    --clear)
        # Clear all notifications
        dunstctl close-all
        ;;
    *)
        # Show notification status
        if command -v dunstctl >/dev/null 2>&1; then
            if dunstctl is-paused; then
                echo "%{F#6e738d}%{A1:~/.config/polybar/scripts/notifications.sh --toggle-dnd:}  %{A}"
            else
                count=$(dunstctl count displayed)
                if [ "$count" -gt 0 ]; then
                    echo "%{F#f5a97f}%{A1:~/.config/polybar/scripts/notifications.sh --clear:}  $count%{A}"
                else
                    echo "%{F#a6da95}%{A1:~/.config/polybar/scripts/notifications.sh --toggle-dnd:}  %{A}"
                fi
            fi
        else
            echo ""
        fi
        ;;
esac
