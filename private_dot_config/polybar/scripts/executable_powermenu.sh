#!/usr/bin/env bash

# Power menu script for polybar
# Shows options for logout, reboot, shutdown

case "$1" in
    --popup)
        # Show rofi power menu
        options="⏻ Shutdown\n Reboot\n⏽ Logout\n Lock"
        chosen=$(echo -e "$options" | rofi -dmenu -i -p "Power Menu" -theme ~/.config/rofi/config/powermenu.rasi)
        
        case $chosen in
            "⏻ Shutdown")
                systemctl poweroff
                ;;
            " Reboot")
                systemctl reboot
                ;;
            "⏽ Logout")
                echo 'awesome.quit()' | awesome-client
                ;;
            " Lock")
                i3lock -c 1e2030
                ;;
        esac
        ;;
    *)
        echo "%{A1:~/.config/polybar/scripts/powermenu.sh --popup:} ⏻ %{A}"
        ;;
esac
