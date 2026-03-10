#!/usr/bin/env bash

# Screenshot helper — called detached from rofi (via awesome-client spawn)
# Usage: screenshot-helper.sh <mode> [delay]
#   mode: full | area | window
#   delay: seconds to wait before capture (optional)

SCREENSHOT_DIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

MODE="$1"
DELAY="$2"

time=$(date +%Y-%m-%d-%I-%M-%S)
geometry=$(xrandr | head -n1 | cut -d',' -f2 | tr -d '[:blank:],current')
file="${SCREENSHOT_DIR}/Screenshot_${time}_${geometry}.png"
icon="$HOME/.config/dunst/icons/collections.svg"
timer_icon="$HOME/.config/dunst/icons/timer.svg"

# Countdown if delay specified
if [[ -n "$DELAY" && "$DELAY" -gt 0 ]]; then
    for sec in $(seq "$DELAY" -1 1); do
        dunstify -t 1000 --replace=699 -i "$timer_icon" "Taking shot in: $sec"
        sleep 1
    done
    sleep 0.5
fi

# Small delay to ensure rofi is fully closed
sleep 0.2

case "$MODE" in
    full)   maim -u -f png | tee "$file" | xclip -selection clipboard -t image/png ;;
    area)   maim -u -f png -s -b 2 -c 0.35,0.55,0.85,0.25 | tee "$file" | xclip -selection clipboard -t image/png ;;
    window) maim -u -f png -i "$(xdotool getactivewindow)" | tee "$file" | xclip -selection clipboard -t image/png ;;
esac

[[ -f "$file" && -s "$file" ]] && dunstify -u low --replace=699 -i "$icon" "Screenshot saved & copied"
