#!/usr/bin/env bash

# Media player script for polybar using playerctl

get_player_status() {
    if command -v playerctl >/dev/null 2>&1; then
        player_status=$(playerctl status 2>/dev/null)
        if [ $? -eq 0 ]; then
            case $player_status in
                "Playing")
                    artist=$(playerctl metadata artist 2>/dev/null)
                    title=$(playerctl metadata title 2>/dev/null)
                    if [ -n "$artist" ] && [ -n "$title" ]; then
                        # Truncate long text
                        display_text="$artist - $title"
                        if [ ${#display_text} -gt 50 ]; then
                            display_text="${display_text:0:47}..."
                        fi
                        echo "%{F#a6da95}%{A1:playerctl play-pause:}%{A3:playerctl next:}  $display_text%{A}%{A}"
                    else
                        echo "%{F#a6da95}%{A1:playerctl play-pause:}%{A3:playerctl next:}  Playing%{A}%{A}"
                    fi
                    ;;
                "Paused")
                    echo "%{F#6e738d}%{A1:playerctl play-pause:}%{A3:playerctl next:}  Paused%{A}%{A}"
                    ;;
                *)
                    echo ""
                    ;;
            esac
        else
            echo ""
        fi
    else
        echo ""
    fi
}

case "$1" in
    --play-pause)
        playerctl play-pause
        ;;
    --next)
        playerctl next
        ;;
    --previous)
        playerctl previous
        ;;
    *)
        get_player_status
        ;;
esac
