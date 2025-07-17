#!/usr/bin/env bash

# Notification script for polybar
# Shows dunst notification count and controls with D-Bus timeout protection

case "$1" in
    --toggle-dnd)
        # Toggle Do Not Disturb with timeout to prevent hanging
        if timeout 2 dunstctl is-paused 2>/dev/null; then
            timeout 2 dunstctl set-paused false 2>/dev/null
            timeout 2 notify-send "Notifications" "Enabled" -i notification-symbolic 2>/dev/null &
        else
            timeout 2 dunstctl set-paused true 2>/dev/null
            timeout 2 notify-send "Notifications" "Paused (DND Mode)" -i notification-symbolic 2>/dev/null &
        fi
        ;;
    --clear)
        # Clear all notifications with timeout
        timeout 2 dunstctl close-all 2>/dev/null
        ;;
    *)
        # Show notification status with timeout and fallback
        if command -v dunstctl >/dev/null 2>&1; then
            if timeout 1 dunstctl is-paused 2>/dev/null; then
                echo "%{F#6e738d}%{A1:~/.config/polybar/scripts/notifications.sh --toggle-dnd:}  %{A}"
            else
                count=$(timeout 1 dunstctl count displayed 2>/dev/null || echo "0")
                if [ "$count" -gt 0 ] 2>/dev/null; then
                    echo "%{F#f5a97f}%{A1:~/.config/polybar/scripts/notifications.sh --clear:}  $count%{A}"
                else
                    echo "%{F#a6da95}%{A1:~/.config/polybar/scripts/notifications.sh --toggle-dnd:}  %{A}"
                fi
            fi
        else
            # Fallback when dunst is not available
            echo "%{F#a6da95}  %{A}"
        fi
        ;;
esac
