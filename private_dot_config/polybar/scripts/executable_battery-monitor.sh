#!/usr/bin/env bash

# Battery Monitor Script for Polybar
# Provides battery status notifications and monitoring
# Part of the unified notification system with dunst

# Configuration - Auto-detect battery and adapter
BATTERY_PATH=""
ADAPTER_PATH=""

# Auto-detect battery path
for bat in /sys/class/power_supply/BAT*; do
    if [[ -d "$bat" ]]; then
        BATTERY_PATH="$bat"
        break
    fi
done

# Auto-detect adapter path  
for adp in /sys/class/power_supply/{ADP*,AC*,ACAD*}; do
    if [[ -d "$adp" ]]; then
        ADAPTER_PATH="$adp"
        break
    fi
done
NOTIFICATION_LOCKFILE="/tmp/battery_notification_lock"
CHECK_INTERVAL=30
LOW_BATTERY_THRESHOLD=15
CRITICAL_BATTERY_THRESHOLD=5

# Notification settings
NOTIFICATION_APP="battery-monitor"
NOTIFICATION_TIMEOUT=5000

# Colors for different states (Catppuccin Macchiato)
COLOR_NORMAL="#a6da95"  # green
COLOR_WARNING="#eed49f" # yellow
COLOR_CRITICAL="#ed8796" # red
COLOR_CHARGING="#8aadf4" # blue

# Icons (using Font Awesome icons for better compatibility)
ICON_CHARGING=""
ICON_DISCHARGING=""
ICON_FULL=""
ICON_LOW=""

get_battery_info() {
    if [[ -z "$BATTERY_PATH" || ! -d "$BATTERY_PATH" ]]; then
        echo "No battery found"
        return 1
    fi
    
    local capacity=$(cat "$BATTERY_PATH/capacity" 2>/dev/null || echo "0")
    local status=$(cat "$BATTERY_PATH/status" 2>/dev/null || echo "Unknown")
    local present=$(cat "$BATTERY_PATH/present" 2>/dev/null || echo "0")
    
    if [[ "$present" != "1" ]]; then
        echo "Battery not present"
        return 1
    fi
    
    echo "$capacity|$status"
}

get_adapter_status() {
    if [[ -n "$ADAPTER_PATH" && -f "$ADAPTER_PATH/online" ]]; then
        cat "$ADAPTER_PATH/online" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

send_notification() {
    local title="$1"
    local message="$2"
    local urgency="$3"
    local icon="$4"
    
    notify-send \
        --app-name="$NOTIFICATION_APP" \
        --urgency="$urgency" \
        --expire-time="$NOTIFICATION_TIMEOUT" \
        "$icon $title" \
        "$message"
}

check_battery_status() {
    local battery_info=$(get_battery_info)
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    local capacity=$(echo "$battery_info" | cut -d'|' -f1)
    local status=$(echo "$battery_info" | cut -d'|' -f2)
    local adapter_online=$(get_adapter_status)
    
    # Check for charging state changes
    local current_state="${status}_${adapter_online}"
    local last_state_file="/tmp/battery_last_state"
    local last_state=""
    
    if [[ -f "$last_state_file" ]]; then
        last_state=$(cat "$last_state_file")
    fi
    
    # Save current state
    echo "$current_state" > "$last_state_file"
    
    # Notify on state changes
    if [[ "$last_state" != "$current_state" && -n "$last_state" ]]; then
        case "$status" in
            "Charging")
                send_notification \
                    "Battery Charging" \
                    "Battery is now charging (${capacity}%)" \
                    "normal" \
                    "$ICON_CHARGING"
                ;;
            "Discharging")
                send_notification \
                    "Power Disconnected" \
                    "Running on battery power (${capacity}%)" \
                    "normal" \
                    "$ICON_DISCHARGING"
                ;;
            "Full")
                send_notification \
                    "Battery Full" \
                    "Battery is fully charged (${capacity}%)" \
                    "low" \
                    "$ICON_FULL"
                ;;
        esac
    fi
    
    # Critical battery warnings
    if [[ "$status" == "Discharging" ]]; then
        if [[ $capacity -le $CRITICAL_BATTERY_THRESHOLD ]]; then
            # Send critical notification every check (persistent warning)
            send_notification \
                "CRITICAL BATTERY" \
                "Battery critically low (${capacity}%)! Please connect charger immediately." \
                "critical" \
                "$ICON_LOW"
        elif [[ $capacity -le $LOW_BATTERY_THRESHOLD ]]; then
            # Send low battery warning only once per discharge cycle
            local low_notif_file="/tmp/battery_low_notified_${capacity}"
            if [[ ! -f "$low_notif_file" ]]; then
                send_notification \
                    "Low Battery Warning" \
                    "Battery is low (${capacity}%). Consider charging soon." \
                    "normal" \
                    "$ICON_LOW"
                # Create notification marker and clean up old ones
                touch "$low_notif_file"
                find /tmp -name "battery_low_notified_*" -mmin +60 -delete 2>/dev/null
            fi
        fi
    fi
}

show_battery_info() {
    local battery_info=$(get_battery_info)
    if [[ $? -ne 0 ]]; then
        echo "No battery information available"
        return 1
    fi
    
    local capacity=$(echo "$battery_info" | cut -d'|' -f1)
    local status=$(echo "$battery_info" | cut -d'|' -f2)
    local adapter_online=$(get_adapter_status)
    
    echo "Battery Status: $status"
    echo "Battery Level: ${capacity}%"
    echo "Adapter Connected: $([ "$adapter_online" = "1" ] && echo "Yes" || echo "No")"
    
    # Additional battery details if available
    if [[ -f "$BATTERY_PATH/voltage_now" ]] && [[ -f "$BATTERY_PATH/current_now" ]]; then
        local voltage=$(cat "$BATTERY_PATH/voltage_now")
        local current=$(cat "$BATTERY_PATH/current_now")
        local power=$((voltage * current / 1000000000000))
        echo "Power Consumption: ${power}W"
    fi
    
    if [[ -f "$BATTERY_PATH/time_to_empty_now" ]]; then
        local time_remaining=$(cat "$BATTERY_PATH/time_to_empty_now")
        if [[ $time_remaining -gt 0 ]]; then
            local hours=$((time_remaining / 3600))
            local minutes=$(((time_remaining % 3600) / 60))
            echo "Time Remaining: ${hours}h ${minutes}m"
        fi
    fi
}

daemon_mode() {
    echo "Starting battery monitor daemon..."
    echo "PID: $$" > "/tmp/battery_monitor.pid"
    
    while true; do
        check_battery_status
        sleep "$CHECK_INTERVAL"
    done
}

# Polybar display function
show_polybar_battery() {
    if [[ -z "$BATTERY_PATH" || ! -d "$BATTERY_PATH" ]]; then
        echo " No Battery"
        return 1
    fi
    
    local capacity=$(cat "$BATTERY_PATH/capacity" 2>/dev/null || echo "0")
    local status=$(cat "$BATTERY_PATH/status" 2>/dev/null || echo "Unknown")
    local icon=""
    
    # Select appropriate icon based on status and capacity
    case "$status" in
        "Charging")
            icon="$ICON_CHARGING"
            ;;
        "Discharging")
            if [[ $capacity -le 20 ]]; then
                icon="$ICON_LOW"
            else
                icon="$ICON_DISCHARGING"
            fi
            ;;
        "Full"|"Not charging")
            icon="$ICON_FULL"
            ;;
        *)
            icon="$ICON_DISCHARGING"
            ;;
    esac
    
    echo "${capacity}%"
}

case "${1:-polybar}" in
    "polybar"|"")
        show_polybar_battery
        ;;
    "daemon"|"monitor")
        daemon_mode
        ;;
    "status"|"info")
        show_battery_info
        ;;
    "check")
        check_battery_status
        ;;
    "stop")
        if [[ -f "/tmp/battery_monitor.pid" ]]; then
            local pid=$(cat "/tmp/battery_monitor.pid")
            if kill -0 "$pid" 2>/dev/null; then
                kill "$pid"
                echo "Battery monitor daemon stopped"
            else
                echo "Battery monitor daemon not running"
            fi
            rm -f "/tmp/battery_monitor.pid"
        else
            echo "Battery monitor daemon not running"
        fi
        ;;
    "--help"|"-h"|"help")
        echo "Battery Monitor Script"
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  polybar, (none)  Show battery status for polybar (default)"
        echo "  daemon, monitor  Run battery monitoring daemon"
        echo "  status, info     Show current battery information"
        echo "  check           Perform single battery status check"
        echo "  stop            Stop running daemon"
        echo "  help            Show this help message"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac