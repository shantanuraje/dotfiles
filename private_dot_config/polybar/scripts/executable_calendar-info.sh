#!/usr/bin/env bash

# Enhanced Calendar and Clock popup for polybar
# Displays a beautiful calendar with clock information using rofi

# Colors matching Catppuccin Macchiato theme
COLOR_BG="#1e2030"
COLOR_FG="#cad3f5"
COLOR_ACCENT="#8bd5ca"
COLOR_SECONDARY="#8aadf4"
COLOR_HIGHLIGHT="#f5bde6"
COLOR_MUTED="#6e738d"

# Function to get current date and time information
get_date_info() {
    echo "$(date '+%A, %B %d, %Y')"
}

get_time_info() {
    echo "$(date '+%I:%M:%S %p')"
}

get_timezone_info() {
    echo "$(date '+%Z %z')"
}

get_week_info() {
    echo "Week $(date '+%W') of $(date '+%Y') | Day $(date '+%j') of $(date '+%Y')"
}

get_moon_phase() {
    # Simple moon phase calculation (approximate)
    local day=$(date '+%d')
    local month=$(date '+%m')
    local year=$(date '+%Y')
    
    # Simplified moon phase - this is approximate
    local phase_days=$(( (day + month * 30 + (year - 2000) * 365) % 29 ))
    
    case $phase_days in
        0|1|2) echo "🌑 New Moon" ;;
        3|4|5|6) echo "🌒 Waxing Crescent" ;;
        7|8|9) echo "🌓 First Quarter" ;;
        10|11|12|13) echo "🌔 Waxing Gibbous" ;;
        14|15|16) echo "🌕 Full Moon" ;;
        17|18|19|20) echo "🌖 Waning Gibbous" ;;
        21|22|23) echo "🌗 Third Quarter" ;;
        *) echo "🌘 Waning Crescent" ;;
    esac
}

# Function to create a formatted calendar
get_calendar() {
    # Get current month calendar with highlighting
    local current_day=$(date '+%d')
    local calendar_output
    
    # Remove leading zeros from day for comparison
    current_day=$(echo $current_day | sed 's/^0*//')
    
    # Get calendar and process it
    calendar_output=$(cal -m | sed '1d' | sed '2s/^/    /')
    
    # Highlight current day (simple approach)
    # This is a basic implementation - you might want to enhance it
    echo "$calendar_output"
}

# Function to get upcoming events (placeholder - you can integrate with your calendar system)
get_upcoming_events() {
    echo "📅 No events configured"
    echo "   Set up calendar integration in"
    echo "   ~/.config/polybar/scripts/calendar-info.sh"
}

# Function to show calendar popup
show_calendar_popup() {
    local current_date=$(get_date_info)
    local current_time=$(get_time_info)
    local timezone=$(get_timezone_info)
    local week_info=$(get_week_info)
    local moon_phase=$(get_moon_phase)
    local calendar=$(get_calendar)
    local events=$(get_upcoming_events)
    
    # Create the popup content
    local popup_content="🗓️  $current_date
🕐 $current_time
🌍 $timezone
📊 $week_info
$moon_phase

📅 Calendar:
$calendar

📝 Upcoming Events:
$events

💡 Tips:
• Click date again to refresh
• Integrate with your calendar app
• Customize in calendar-info.sh"
    
    # Show rofi popup with calendar information
    echo "$popup_content" | rofi \
        -dmenu \
        -i \
        -p "📅 Calendar & Clock" \
        -theme-str "window { width: 600px; height: 500px; }" \
        -theme-str "listview { lines: 20; columns: 1; fixed-height: true; }" \
        -theme-str "element { padding: 4px; border-radius: 4px; }" \
        -theme-str "element selected { background-color: $COLOR_ACCENT; text-color: $COLOR_BG; }" \
        -theme-str "textbox { padding: 8px; margin: 4px; }" \
        -theme-str "inputbar { padding: 8px; margin: 4px; }" \
        -theme-str "prompt { padding: 8px; }" \
        -no-custom \
        -format '' \
        >/dev/null 2>&1
}

# Function to show compact calendar notification
show_calendar_notification() {
    local current_date=$(get_date_info)
    local current_time=$(get_time_info)
    local week_info=$(get_week_info)
    local calendar=$(cal -m | head -n 8)
    
    notify-send "📅 Calendar" "$current_date
$current_time
$week_info

$calendar" -t 5000 -i "calendar"
}

# Function to show clock popup
show_clock_popup() {
    local current_time=$(get_time_info)
    local timezone=$(get_timezone_info)
    local date_info=$(get_date_info)
    
    # Create a simple clock display
    local clock_content="🕐 $current_time
🌍 $timezone
📅 $date_info

⏰ Time Zones:
🌍 UTC: $(TZ=UTC date '+%H:%M %Z')
🇺🇸 EST: $(TZ=America/New_York date '+%H:%M %Z')
🇬🇧 GMT: $(TZ=Europe/London date '+%H:%M %Z')
🇯🇵 JST: $(TZ=Asia/Tokyo date '+%H:%M %Z')

⏱️ System Info:
💻 Uptime: $(uptime -p)
🔋 Load: $(uptime | awk -F'load average:' '{print $2}')

Press Enter to close"
    
    echo "$clock_content" | rofi \
        -dmenu \
        -i \
        -p "🕐 World Clock" \
        -theme-str "window { width: 500px; height: 400px; }" \
        -theme-str "listview { lines: 15; columns: 1; fixed-height: true; }" \
        -theme-str "element { padding: 4px; }" \
        -theme-str "element selected { background-color: $COLOR_SECONDARY; text-color: $COLOR_BG; }" \
        -no-custom \
        -format '' \
        >/dev/null 2>&1
}

# Main logic
case "${1:-calendar}" in
    "calendar"|"popup")
        show_calendar_popup &
        ;;
    "notification"|"notify")
        show_calendar_notification &
        ;;
    "clock")
        show_clock_popup &
        ;;
    "help")
        echo "Calendar & Clock Script"
        echo "Usage: $0 [calendar|notification|clock|help]"
        echo ""
        echo "Commands:"
        echo "  calendar     - Show calendar popup (default)"
        echo "  notification - Show calendar notification"
        echo "  clock        - Show world clock popup"
        echo "  help         - Show this help"
        ;;
    *)
        show_calendar_popup &
        ;;
esac