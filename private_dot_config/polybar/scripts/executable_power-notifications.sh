#!/usr/bin/env bash

# Power & Charger Notifications Script
# Advanced power management notifications with intelligent features
# Part of the unified notification system with dunst and Catppuccin theming

# Auto-detect power supply devices
BATTERY_PATH=""
ADAPTER_PATH=""

# Find battery
for bat in /sys/class/power_supply/BAT*; do
    if [[ -d "$bat" && -f "$bat/capacity" ]]; then
        BATTERY_PATH="$bat"
        break
    fi
done

# Find AC adapter
for adp in /sys/class/power_supply/{ADP*,AC*,ACAD*}; do
    if [[ -d "$adp" && -f "$adp/online" ]]; then
        ADAPTER_PATH="$adp"
        break
    fi
done

# Configuration
TEMP_DIR="/tmp/power-notifications"
LOCKFILE="${TEMP_DIR}/daemon.lock"
CHECK_INTERVAL=5  # More frequent for power events

# Power thresholds
LOW_BATTERY_THRESHOLD=20
CRITICAL_BATTERY_THRESHOLD=10
FULL_BATTERY_THRESHOLD=95
CHARGING_COMPLETE_THRESHOLD=100

# Notification settings
NOTIFICATION_APP="power-manager"
NOTIFICATION_TIMEOUT=5000

# Colors (Catppuccin Macchiato)
COLOR_NORMAL="#a6da95"   # green
COLOR_WARNING="#eed49f"  # yellow
COLOR_CRITICAL="#ed8796" # red
COLOR_CHARGING="#8aadf4" # blue

# Icons (Nerd Font)
ICON_BATTERY_FULL=""
ICON_BATTERY_GOOD=""
ICON_BATTERY_LOW=""
ICON_BATTERY_CRITICAL=""
ICON_CHARGING=""
ICON_AC_CONNECTED=""
ICON_AC_DISCONNECTED=""
ICON_POWER_SAVE=""

# Create temp directory
mkdir -p "$TEMP_DIR"

# Logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "${TEMP_DIR}/power.log"
}

# Send notification
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
    
    log "NOTIFICATION: [$urgency] $title - $message"
}

# Get battery information
get_battery_info() {
    if [[ -z "$BATTERY_PATH" || ! -d "$BATTERY_PATH" ]]; then
        return 1
    fi
    
    local capacity=$(cat "$BATTERY_PATH/capacity" 2>/dev/null || echo "0")
    local status=$(cat "$BATTERY_PATH/status" 2>/dev/null || echo "Unknown")
    local present=$(cat "$BATTERY_PATH/present" 2>/dev/null || echo "0")
    
    if [[ "$present" != "1" ]]; then
        return 1
    fi
    
    echo "$capacity|$status"
}

# Get AC adapter status
get_adapter_status() {
    if [[ -n "$ADAPTER_PATH" && -f "$ADAPTER_PATH/online" ]]; then
        cat "$ADAPTER_PATH/online" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Get battery icon based on level and status
get_battery_icon() {
    local capacity="$1"
    local status="$2"
    
    if [[ "$status" == "Charging" ]]; then
        echo "$ICON_CHARGING"
    elif [[ $capacity -ge 80 ]]; then
        echo "$ICON_BATTERY_FULL"
    elif [[ $capacity -ge 30 ]]; then
        echo "$ICON_BATTERY_GOOD"
    elif [[ $capacity -ge 15 ]]; then
        echo "$ICON_BATTERY_LOW"
    else
        echo "$ICON_BATTERY_CRITICAL"
    fi
}

# Estimate time remaining
estimate_time_remaining() {
    local capacity="$1"
    local status="$2"
    
    if [[ "$status" == "Discharging" && -f "$BATTERY_PATH/power_now" && -f "$BATTERY_PATH/energy_now" ]]; then
        local power_now=$(cat "$BATTERY_PATH/power_now" 2>/dev/null || echo "0")
        local energy_now=$(cat "$BATTERY_PATH/energy_now" 2>/dev/null || echo "0")
        
        if [[ $power_now -gt 0 ]]; then
            local hours_remaining=$((energy_now * 1000 / power_now))
            local hours=$((hours_remaining / 1000000))
            local minutes=$(((hours_remaining % 1000000) * 60 / 1000000))
            echo "${hours}h ${minutes}m"
            return
        fi
    fi
    
    # Fallback estimation based on capacity
    if [[ "$status" == "Discharging" ]]; then
        local estimated_hours=$((capacity / 15)) # Rough estimate: 15% per hour
        echo "~${estimated_hours}h"
    elif [[ "$status" == "Charging" ]]; then
        local remaining=$((100 - capacity))
        local estimated_hours=$((remaining / 25)) # Rough estimate: 25% per hour charging
        echo "~${estimated_hours}h"
    else
        echo "N/A"
    fi
}

# Check for power state changes and send intelligent notifications
check_power_status() {
    local battery_info=$(get_battery_info)
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    local capacity=$(echo "$battery_info" | cut -d'|' -f1)
    local status=$(echo "$battery_info" | cut -d'|' -f2)
    local adapter_online=$(get_adapter_status)
    
    # State tracking files
    local state_file="${TEMP_DIR}/power_state"
    local last_notification_file="${TEMP_DIR}/last_notification"
    local current_state="${status}_${adapter_online}_${capacity}"
    local last_state=""
    
    if [[ -f "$state_file" ]]; then
        last_state=$(cat "$state_file")
    fi
    
    # Save current state
    echo "$current_state" > "$state_file"
    
    # Skip if state hasn't changed and not a critical situation
    if [[ "$last_state" == "$current_state" ]]; then
        # Still send critical notifications even if state hasn't changed
        if [[ "$status" == "Discharging" && $capacity -le $CRITICAL_BATTERY_THRESHOLD ]]; then
            local last_critical=$(cat "$last_notification_file" 2>/dev/null || echo "0")
            local current_time=$(date +%s)
            local time_diff=$((current_time - last_critical))
            
            # Send critical notification every 2 minutes
            if [[ $time_diff -gt 120 ]]; then
                local time_remaining=$(estimate_time_remaining "$capacity" "$status")
                local battery_icon=$(get_battery_icon "$capacity" "$status")
                
                send_notification \
                    "CRITICAL BATTERY" \
                    "Battery at ${capacity}%! Estimated time: $time_remaining. Save work and connect charger immediately!" \
                    "critical" \
                    "$battery_icon"
                    
                echo "$current_time" > "$last_notification_file"
            fi
        fi
        return
    fi
    
    local battery_icon=$(get_battery_icon "$capacity" "$status")
    local time_remaining=$(estimate_time_remaining "$capacity" "$status")
    
    # Charger connection/disconnection notifications
    if [[ -n "$last_state" ]]; then
        local last_adapter=$(echo "$last_state" | cut -d'_' -f2)
        
        if [[ "$last_adapter" != "$adapter_online" ]]; then
            if [[ "$adapter_online" == "1" ]]; then
                # Charger connected
                if [[ "$status" == "Charging" ]]; then
                    send_notification \
                        "Charger Connected" \
                        "Battery at ${capacity}%. Estimated charge time: $time_remaining" \
                        "low" \
                        "$ICON_AC_CONNECTED"
                else
                    send_notification \
                        "AC Power Connected" \
                        "Running on AC power (battery not charging)" \
                        "low" \
                        "$ICON_AC_CONNECTED"
                fi
            else
                # Charger disconnected
                send_notification \
                    "Charger Disconnected" \
                    "Running on battery (${capacity}%). Estimated time: $time_remaining" \
                    "normal" \
                    "$ICON_AC_DISCONNECTED"
            fi
        fi
    fi
    
    # Battery status notifications
    case "$status" in
        "Charging")
            if [[ $capacity -ge $FULL_BATTERY_THRESHOLD ]]; then
                send_notification \
                    "Battery Almost Full" \
                    "Battery at ${capacity}%. Consider unplugging to preserve battery health." \
                    "low" \
                    "$battery_icon"
            fi
            ;;
        "Full")
            send_notification \
                "Battery Fully Charged" \
                "Battery is at 100%. You can unplug the charger." \
                "low" \
                "$battery_icon"
            ;;
        "Discharging")
            if [[ $capacity -le $CRITICAL_BATTERY_THRESHOLD ]]; then
                send_notification \
                    "CRITICAL BATTERY" \
                    "Battery at ${capacity}%! Estimated time: $time_remaining. Connect charger now!" \
                    "critical" \
                    "$battery_icon"
                echo "$(date +%s)" > "$last_notification_file"
            elif [[ $capacity -le $LOW_BATTERY_THRESHOLD ]]; then
                send_notification \
                    "Low Battery Warning" \
                    "Battery at ${capacity}%. Estimated time: $time_remaining. Consider charging soon." \
                    "normal" \
                    "$battery_icon"
            fi
            ;;
    esac
    
    # Power efficiency suggestions
    if [[ "$status" == "Discharging" && $capacity -le 30 ]]; then
        local suggestions=""
        if command -v powertop >/dev/null 2>&1; then
            suggestions="Consider enabling power saving mode"
        else
            suggestions="Lower screen brightness, close unused apps"
        fi
        
        if [[ $capacity -le 20 ]]; then
            send_notification \
                "Power Saving Tip" \
                "$suggestions to extend battery life" \
                "low" \
                "$ICON_POWER_SAVE"
        fi
    fi
}

# Daemon mode
daemon_mode() {
    log "Starting power notifications daemon (PID: $$)"
    echo "$$" > "$LOCKFILE"
    
    # Initial notification
    local battery_info=$(get_battery_info)
    if [[ $? -eq 0 ]]; then
        local capacity=$(echo "$battery_info" | cut -d'|' -f1)
        local status=$(echo "$battery_info" | cut -d'|' -f2)
        local battery_icon=$(get_battery_icon "$capacity" "$status")
        
        send_notification \
            "Power Monitor Started" \
            "Monitoring power events. Battery: ${capacity}% ($status)" \
            "low" \
            "$battery_icon"
    fi
    
    while true; do
        check_power_status
        sleep "$CHECK_INTERVAL"
    done
}

# Stop daemon
stop_daemon() {
    if [[ -f "$LOCKFILE" ]]; then
        local pid=$(cat "$LOCKFILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            echo "Power notifications daemon stopped"
            log "Daemon stopped"
        else
            echo "Daemon not running"
        fi
        rm -f "$LOCKFILE"
    else
        echo "Daemon not running"
    fi
}

# Show power status
show_power_status() {
    echo "Power & Battery Status"
    echo "====================="
    
    local battery_info=$(get_battery_info)
    if [[ $? -eq 0 ]]; then
        local capacity=$(echo "$battery_info" | cut -d'|' -f1)
        local status=$(echo "$battery_info" | cut -d'|' -f2)
        local adapter_online=$(get_adapter_status)
        local time_remaining=$(estimate_time_remaining "$capacity" "$status")
        
        echo "Battery Level: ${capacity}%"
        echo "Battery Status: $status"
        echo "AC Adapter: $([ "$adapter_online" = "1" ] && echo "Connected" || echo "Disconnected")"
        echo "Estimated Time: $time_remaining"
        
        if [[ -f "$BATTERY_PATH/voltage_now" && -f "$BATTERY_PATH/current_now" ]]; then
            local voltage=$(cat "$BATTERY_PATH/voltage_now" 2>/dev/null || echo "0")
            local current=$(cat "$BATTERY_PATH/current_now" 2>/dev/null || echo "0")
            if [[ $voltage -gt 0 && $current -gt 0 ]]; then
                local power=$((voltage * current / 1000000000000))
                echo "Power Draw: ${power}W"
            fi
        fi
    else
        echo "No battery detected"
    fi
    
    echo ""
    if [[ -f "$LOCKFILE" ]]; then
        local pid=$(cat "$LOCKFILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "Daemon Status: Running (PID: $pid)"
        else
            echo "Daemon Status: Not running (stale lock)"
        fi
    else
        echo "Daemon Status: Not running"
    fi
    
    echo ""
    echo "Configuration:"
    echo "  Low battery threshold: ${LOW_BATTERY_THRESHOLD}%"
    echo "  Critical threshold: ${CRITICAL_BATTERY_THRESHOLD}%"
    echo "  Check interval: ${CHECK_INTERVAL}s"
}

# Command line interface
case "${1:-daemon}" in
    "daemon"|"start")
        if [[ -f "$LOCKFILE" ]] && kill -0 "$(cat "$LOCKFILE")" 2>/dev/null; then
            echo "Power daemon already running"
            exit 1
        fi
        daemon_mode
        ;;
    "stop")
        stop_daemon
        ;;
    "status")
        show_power_status
        ;;
    "check")
        check_power_status
        ;;
    "test")
        local battery_info=$(get_battery_info)
        if [[ $? -eq 0 ]]; then
            local capacity=$(echo "$battery_info" | cut -d'|' -f1)
            local status=$(echo "$battery_info" | cut -d'|' -f2)
            local battery_icon=$(get_battery_icon "$capacity" "$status")
            
            send_notification \
                "Power Test" \
                "Battery: ${capacity}% ($status)" \
                "normal" \
                "$battery_icon"
        else
            send_notification \
                "Power Test" \
                "No battery detected" \
                "normal" \
                "$ICON_AC_CONNECTED"
        fi
        ;;
    "--help"|"-h"|"help")
        echo "Advanced Power & Charger Notifications"
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  daemon, start    Start power monitoring daemon (default)"
        echo "  stop            Stop running daemon"
        echo "  status          Show power status and daemon info"
        echo "  check           Run single power check"
        echo "  test            Send test notification"
        echo "  help            Show this help message"
        echo ""
        echo "Features:"
        echo "  • Charger connect/disconnect notifications"
        echo "  • Intelligent battery warnings with time estimates"
        echo "  • Battery health recommendations"
        echo "  • Power efficiency suggestions"
        echo "  • Critical battery protection"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac