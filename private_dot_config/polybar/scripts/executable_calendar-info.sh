#!/usr/bin/env bash

# Themed calendar and clock popup for polybar
# Uses rofi with Catppuccin Macchiato calendar theme

export DISPLAY=${DISPLAY:-:0}

THEME="$HOME/.config/rofi/config/calendar.rasi"

# Build all calendar content into a variable, then pipe once to rofi
show_calendar_popup() {
    local current_day
    current_day=$(date '+%-d')
    local content=""

    # Header
    content+="  $(date '+%A, %B %-d, %Y')"$'\n'
    content+="󰅐  $(date '+%I:%M:%S %p  %Z')"$'\n'
    content+="󰇧  Week $(date '+%W')  |  Day $(date '+%-j') of $(date '+%Y')"$'\n'
    content+=""$'\n'

    # Calendar title
    content+="            $(cal -m | head -1)"$'\n'

    # Day-of-week header - widened
    content+="     Mo    Tu    We    Th    Fr    Sa    Su"$'\n'

    # Calendar rows - widen by splitting into 3-char fields
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            local widened=""
            for i in 0 1 2 3 4 5 6; do
                local field="${line:$((i * 3)):2}"
                if [ "$i" -lt 6 ]; then
                    widened+=$(printf "%-6s" "$field")
                else
                    widened+="$field"
                fi
            done
            # Mark today with brackets
            local formatted
            formatted=$(echo "$widened" | sed "s/\b${current_day}\b/[${current_day}]/")
            content+="     $formatted"$'\n'
        fi
    done < <(cal -m | tail -n +3)

    content+=""$'\n'

    # Time zones
    content+="  Time Zones"$'\n'
    content+="    UTC   $(TZ=UTC date '+%H:%M')"$'\n'
    content+="    EST   $(TZ=America/New_York date '+%H:%M')"$'\n'
    content+="    GMT   $(TZ=Europe/London date '+%H:%M')"$'\n'
    content+="    IST   $(TZ=Asia/Kolkata date '+%H:%M')"$'\n'
    content+="    JST   $(TZ=Asia/Tokyo date '+%H:%M')"$'\n'

    content+=""$'\n'

    # Uptime
    local up
    up=$(uptime | sed 's/.*up\s*//' | sed 's/,\s*[0-9]* user.*//')
    content+="󰌽  up $up"$'\n'

    echo -n "$content" | rofi \
        -dmenu \
        -p "$(date '+%b %-d')" \
        -theme "$THEME" \
        -no-custom \
        -format 'i' >/dev/null 2>&1
}

show_calendar_notification() {
    local calendar
    calendar=$(cal -m | head -n 8)
    notify-send "$(date '+%A, %B %-d')" "$(date '+%I:%M %p  %Z')\nWeek $(date '+%W') | Day $(date '+%-j')\n\n$calendar" -t 5000 -i "calendar"
}

show_clock_popup() {
    local up
    up=$(uptime | sed 's/.*up\s*//' | sed 's/,\s*[0-9]* user.*//')
    local content=""
    content+="󰅐  $(date '+%I:%M:%S %p')"$'\n'
    content+="  $(date '+%Z %z')"$'\n'
    content+="  $(date '+%A, %B %-d, %Y')"$'\n'
    content+=""$'\n'
    content+="  Time Zones"$'\n'
    content+="    UTC   $(TZ=UTC date '+%H:%M')"$'\n'
    content+="    EST   $(TZ=America/New_York date '+%H:%M')"$'\n'
    content+="    GMT   $(TZ=Europe/London date '+%H:%M')"$'\n'
    content+="    IST   $(TZ=Asia/Kolkata date '+%H:%M')"$'\n'
    content+="    JST   $(TZ=Asia/Tokyo date '+%H:%M')"$'\n'
    content+=""$'\n'
    content+="󰌽  up $up"$'\n'
    content+="󰍛  Load:$(uptime | awk -F'load average:' '{print $2}')"$'\n'

    echo -n "$content" | rofi \
        -dmenu \
        -p "$(date '+%H:%M')" \
        -theme "$THEME" \
        -no-custom \
        -format 'i' >/dev/null 2>&1
}

case "${1:-calendar}" in
    "calendar"|"popup")
        show_calendar_popup
        ;;
    "notification"|"notify")
        show_calendar_notification
        ;;
    "clock")
        show_clock_popup
        ;;
    *)
        show_calendar_popup
        ;;
esac
