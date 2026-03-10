#!/usr/bin/env bash

# Media Control - rofi script mode
# Controls media playback via playerctl
# Add to unified palette: rofi -modi "media:media-control-mode.sh" -show media

if [ -z "$1" ]; then
    echo -en "\0prompt\x1fMedia\n"
    echo -en "\0markup-rows\x1ftrue\n"

    # Current track info
    STATUS=$(playerctl status 2>/dev/null || echo "Stopped")
    ARTIST=$(playerctl metadata artist 2>/dev/null)
    TITLE=$(playerctl metadata title 2>/dev/null)

    if [[ -n "$TITLE" ]]; then
        echo "<span color='#cad3f5'>$TITLE</span> <span color='#6e738d'>—</span> <span color='#8087a2'>$ARTIST</span> <span color='#494d64'>[$STATUS]</span>"
    else
        echo "<span color='#6e738d'>No media playing</span>"
    fi

    if [[ "$STATUS" == "Playing" ]]; then
        echo '⏸  Pause'
    else
        echo '▶  Play'
    fi
    echo '⏭  Next Track'
    echo '⏮  Previous Track'
    echo '🔊  Volume Up'
    echo '🔉  Volume Down'
    echo '⏹  Stop'
else
    case "$1" in
        *"Play"*|*"Pause"*) playerctl play-pause ;;
        *"Next"*)           playerctl next ;;
        *"Previous"*)       playerctl previous ;;
        *"Volume Up"*)      pamixer -i 5 ;;
        *"Volume Down"*)    pamixer -d 5 ;;
        *"Stop"*)           playerctl stop ;;
    esac
fi
