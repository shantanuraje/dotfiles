#!/usr/bin/env bash

# Layout indicator for polybar
# Displays current AwesomeWM layout and supports cycling via arguments
# Usage:
#   layout-indicator.sh          - Display current layout name
#   layout-indicator.sh next     - Cycle to next layout
#   layout-indicator.sh prev     - Cycle to previous layout

get_layout() {
    local raw
    raw=$(echo 'local awful = require("awful"); return awful.layout.getname(awful.layout.get(awful.screen.focused()))' | awesome-client 2>/dev/null)
    # awesome-client returns: string "layoutname"
    echo "$raw" | sed 's/.*string "\(.*\)"/\1/' | tr -d ' \n'
}

# Map layout names to short display labels with icons
format_layout() {
    case "$1" in
        tile)         echo "󰙀 tile" ;;
        tileleft)     echo "󰙁 tileL" ;;
        tiletop)      echo "󰙂 tileT" ;;
        tilebottom)   echo "󰙃 tileB" ;;
        fairv)        echo "󰕗 fairV" ;;
        fairh)        echo "󰕘 fairH" ;;
        spiral)       echo "󰾰 spiral" ;;
        dwindle)      echo "󰾰 dwindle" ;;
        max)          echo "󰁌 max" ;;
        fullscreen)   echo "󰊓 full" ;;
        magnifier)    echo "󰍉 magnify" ;;
        floating)     echo "󰖲 float" ;;
        cornernw)     echo "󰘕 cornerNW" ;;
        cornerne)     echo "󰘕 cornerNE" ;;
        cornersw)     echo "󰘕 cornerSW" ;;
        cornerse)     echo "󰘕 cornerSE" ;;
        *)            echo "󰕫 $1" ;;
    esac
}

case "${1:-}" in
    next)
        echo 'require("awful").layout.inc(1)' | awesome-client 2>/dev/null
        ;;
    prev)
        echo 'require("awful").layout.inc(-1)' | awesome-client 2>/dev/null
        ;;
    *)
        layout=$(get_layout)
        if [ -n "$layout" ]; then
            format_layout "$layout"
        else
            echo "󰕫 --"
        fi
        ;;
esac
