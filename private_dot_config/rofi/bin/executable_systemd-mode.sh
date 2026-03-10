#!/usr/bin/env bash

# Systemd Service Manager - rofi script mode
# View and manage user systemd services
# Add to unified palette: rofi -modi "services:systemd-mode.sh" -show services

if [ -z "$1" ]; then
    echo -en "\0prompt\x1fServices\n"
    echo -en "\0markup-rows\x1ftrue\n"

    # User services
    echo '<span color="#8aadf4">━━ User Services ━━━━━━━━━━</span>'
    systemctl --user list-units --type=service --no-pager --plain --no-legend 2>/dev/null | \
    while read -r unit load active sub rest; do
        if [[ "$sub" == "running" ]]; then
            echo "<span color='#a6da95'>●</span> $unit"
        else
            echo "<span color='#ed8796'>●</span> $unit <span color='#6e738d'>[$sub]</span>"
        fi
    done

    echo '<span color="#c6a0f6">━━ Actions ━━━━━━━━━━━━━━━━</span>'
    echo '󰒓  Reload systemd daemon'

else
    ACTION="$1"

    # Skip headers
    [[ "$ACTION" == *"━━"* ]] && exit 0

    if [[ "$ACTION" == *"Reload"* ]]; then
        systemctl --user daemon-reload
        dunstify -u low "systemd" "User daemon reloaded"
        exit 0
    fi

    # Extract unit name (strip the colored dot prefix)
    UNIT=$(echo "$ACTION" | sed 's/^. //' | awk '{print $1}')

    # Show sub-menu for this service
    echo -en "\0prompt\x1f$UNIT\n"
    echo "󰑙  Restart $UNIT"
    echo "󰓛  Stop $UNIT"
    echo "󰐊  Start $UNIT"
    echo "󰋼  Status $UNIT"
    echo "󰈔  Journal $UNIT"

    case "$ACTION" in
        *"Restart"*)
            systemctl --user restart "$UNIT" && dunstify -u low "systemd" "$UNIT restarted" ;;
        *"Stop"*)
            systemctl --user stop "$UNIT" && dunstify -u low "systemd" "$UNIT stopped" ;;
        *"Start"*)
            systemctl --user start "$UNIT" && dunstify -u low "systemd" "$UNIT started" ;;
        *"Status"*)
            echo "require('awful').spawn('kitty -e bash -c \"systemctl --user status $UNIT; read -p \\\"Press enter...\\\"\"')" | awesome-client ;;
        *"Journal"*)
            echo "require('awful').spawn('kitty -e bash -c \"journalctl --user -u $UNIT -f\"')" | awesome-client ;;
    esac
fi
