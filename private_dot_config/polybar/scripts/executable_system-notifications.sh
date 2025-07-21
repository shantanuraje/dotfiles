#!/usr/bin/env bash

# Intelligent System Notifications Script
# Provides smart notifications for various system events and conditions
# Part of the unified notification system with dunst and Catppuccin theming

# Configuration
SCRIPT_NAME="system-notifications"
CHECK_INTERVAL=60
TEMP_DIR="/tmp/${SCRIPT_NAME}"
LOCKFILE="${TEMP_DIR}/daemon.lock"

# Thresholds and settings
CPU_THRESHOLD=85
MEMORY_THRESHOLD=85
DISK_THRESHOLD=90
TEMP_THRESHOLD=75
LOAD_THRESHOLD=4.0

# Notification settings
NOTIFICATION_APP="system-monitor"
NOTIFICATION_TIMEOUT=5000

# Colors (Catppuccin Macchiato)
COLOR_NORMAL="#a6da95"   # green
COLOR_WARNING="#eed49f"  # yellow  
COLOR_CRITICAL="#ed8796" # red
COLOR_INFO="#8aadf4"     # blue

# Icons (Nerd Font)
ICON_CPU=""
ICON_MEMORY=""
ICON_DISK=""
ICON_TEMP=""
ICON_NETWORK=""
ICON_USB=""
ICON_UPDATE=""
ICON_WARNING=""
ICON_INFO=""

# Create temp directory
mkdir -p "$TEMP_DIR"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "${TEMP_DIR}/notifications.log"
}

# Send notification with theming
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

# Check if notification was recently sent (prevents spam)
can_notify() {
    local event_type="$1"
    local cooldown="${2:-300}" # 5 minutes default
    local marker_file="${TEMP_DIR}/last_${event_type}"
    
    if [[ -f "$marker_file" ]]; then
        local last_time=$(cat "$marker_file")
        local current_time=$(date +%s)
        local time_diff=$((current_time - last_time))
        
        if [[ $time_diff -lt $cooldown ]]; then
            return 1
        fi
    fi
    
    echo "$(date +%s)" > "$marker_file"
    return 0
}

# System Health Monitoring
check_cpu_usage() {
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
    cpu_usage=${cpu_usage%.*} # Remove decimal
    
    if [[ $cpu_usage -gt $CPU_THRESHOLD ]] && can_notify "cpu_high" 300; then
        send_notification \
            "High CPU Usage" \
            "CPU usage is ${cpu_usage}% (threshold: ${CPU_THRESHOLD}%)" \
            "normal" \
            "$ICON_CPU"
    fi
}

check_memory_usage() {
    local mem_info=$(free | grep '^Mem:')
    local total=$(echo $mem_info | awk '{print $2}')
    local used=$(echo $mem_info | awk '{print $3}')
    local usage=$((used * 100 / total))
    
    if [[ $usage -gt $MEMORY_THRESHOLD ]] && can_notify "memory_high" 300; then
        send_notification \
            "High Memory Usage" \
            "Memory usage is ${usage}% (threshold: ${MEMORY_THRESHOLD}%)" \
            "normal" \
            "$ICON_MEMORY"
    fi
}

check_disk_usage() {
    while read -r line; do
        local usage=$(echo "$line" | awk '{print $5}' | sed 's/%//')
        local mount=$(echo "$line" | awk '{print $6}')
        
        # Skip special mounts
        if [[ "$mount" =~ ^/(dev|proc|sys|run) ]]; then
            continue
        fi
        
        if [[ $usage -gt $DISK_THRESHOLD ]] && can_notify "disk_${mount//\//_}" 3600; then
            send_notification \
                "Low Disk Space" \
                "Disk ${mount} is ${usage}% full (threshold: ${DISK_THRESHOLD}%)" \
                "normal" \
                "$ICON_DISK"
        fi
    done < <(df -h | grep -E '^/dev/')
}

check_temperature() {
    if command -v sensors >/dev/null 2>&1; then
        local max_temp=0
        while read -r temp; do
            temp=${temp%.*} # Remove decimal
            if [[ $temp -gt $max_temp ]]; then
                max_temp=$temp
            fi
        done < <(sensors | grep -E 'Core|temp' | grep -oE '[0-9]+\.[0-9]+°C' | sed 's/°C//' || echo "0")
        
        if [[ $max_temp -gt $TEMP_THRESHOLD ]] && can_notify "temp_high" 300; then
            send_notification \
                "High Temperature" \
                "System temperature is ${max_temp}°C (threshold: ${TEMP_THRESHOLD}°C)" \
                "normal" \
                "$ICON_TEMP"
        fi
    fi
}

# Network monitoring
check_network_changes() {
    local current_ip=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' || echo "disconnected")
    local last_ip_file="${TEMP_DIR}/last_ip"
    local last_ip=""
    
    if [[ -f "$last_ip_file" ]]; then
        last_ip=$(cat "$last_ip_file")
    fi
    
    echo "$current_ip" > "$last_ip_file"
    
    if [[ "$last_ip" != "$current_ip" && -n "$last_ip" ]]; then
        if [[ "$current_ip" == "disconnected" ]]; then
            send_notification \
                "Network Disconnected" \
                "Lost network connectivity" \
                "normal" \
                "$ICON_NETWORK"
        else
            send_notification \
                "Network Connected" \
                "Connected with IP: $current_ip" \
                "low" \
                "$ICON_NETWORK"
        fi
    fi
}

# USB device monitoring
check_usb_devices() {
    local current_usb=$(lsusb | sort)
    local last_usb_file="${TEMP_DIR}/last_usb"
    local last_usb=""
    
    if [[ -f "$last_usb_file" ]]; then
        last_usb=$(cat "$last_usb_file")
    fi
    
    echo "$current_usb" > "$last_usb_file"
    
    if [[ "$last_usb" != "$current_usb" && -n "$last_usb" ]]; then
        # Find differences
        local added=$(comm -13 <(echo "$last_usb") <(echo "$current_usb"))
        local removed=$(comm -23 <(echo "$last_usb") <(echo "$current_usb"))
        
        if [[ -n "$added" ]]; then
            local device_name=$(echo "$added" | head -1 | awk -F': ' '{print $2}' | cut -c1-50)
            send_notification \
                "USB Device Connected" \
                "Device: $device_name" \
                "low" \
                "$ICON_USB"
        fi
        
        if [[ -n "$removed" ]]; then
            local device_name=$(echo "$removed" | head -1 | awk -F': ' '{print $2}' | cut -c1-50)
            send_notification \
                "USB Device Disconnected" \
                "Device: $device_name" \
                "low" \
                "$ICON_USB"
        fi
    fi
}

# Package updates check
check_updates() {
    # Only check once per day
    if ! can_notify "updates_check" 86400; then
        return
    fi
    
    if command -v nix >/dev/null 2>&1; then
        # For NixOS, check if flake.lock is outdated
        local flake_lock="/etc/nixos/flake.lock"
        if [[ -f "$flake_lock" ]]; then
            local days_old=$(find "$flake_lock" -mtime +7 | wc -l)
            if [[ $days_old -gt 0 ]]; then
                send_notification \
                    "System Updates Available" \
                    "NixOS flake inputs are more than 7 days old. Consider updating." \
                    "low" \
                    "$ICON_UPDATE"
            fi
        fi
    fi
}

# Focus/Break reminders for productivity
check_focus_reminders() {
    local current_hour=$(date +%H)
    local current_minute=$(date +%M)
    
    # Work hours break reminders (9 AM to 6 PM)
    if [[ $current_hour -ge 9 && $current_hour -lt 18 ]]; then
        # Every hour at 50 minutes (10 min before the hour)
        if [[ $current_minute -eq 50 ]] && can_notify "break_reminder" 3000; then
            send_notification \
                "Break Reminder" \
                "You've been working for a while. Consider taking a short break!" \
                "low" \
                "$ICON_INFO"
        fi
    fi
}

# System maintenance reminders
check_maintenance_reminders() {
    # Weekly reminder on Sundays
    if [[ $(date +%u) -eq 7 ]] && can_notify "maintenance_weekly" 604800; then
        send_notification \
            "Weekly Maintenance" \
            "Consider running system cleanup and updates" \
            "low" \
            "$ICON_INFO"
    fi
}

# Main monitoring function
run_system_checks() {
    log "Running system checks..."
    
    check_cpu_usage
    check_memory_usage  
    check_disk_usage
    check_temperature
    check_network_changes
    check_usb_devices
    check_updates
    check_focus_reminders
    check_maintenance_reminders
    
    log "System checks completed"
}

# Daemon mode
daemon_mode() {
    log "Starting system notifications daemon (PID: $$)"
    echo "$$" > "$LOCKFILE"
    
    # Initial startup notification
    send_notification \
        "System Monitor Started" \
        "Intelligent system notifications are now active" \
        "low" \
        "$ICON_INFO"
    
    while true; do
        run_system_checks
        sleep "$CHECK_INTERVAL"
    done
}

# Stop daemon
stop_daemon() {
    if [[ -f "$LOCKFILE" ]]; then
        local pid=$(cat "$LOCKFILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            echo "System notifications daemon stopped"
            log "Daemon stopped"
        else
            echo "Daemon not running"
        fi
        rm -f "$LOCKFILE"
    else
        echo "Daemon not running"
    fi
}

# Show status
show_status() {
    echo "System Notifications Monitor"
    echo "============================"
    
    if [[ -f "$LOCKFILE" ]]; then
        local pid=$(cat "$LOCKFILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "Status: Running (PID: $pid)"
        else
            echo "Status: Not running (stale lock file)"
        fi
    else
        echo "Status: Not running"
    fi
    
    echo ""
    echo "Configuration:"
    echo "  CPU threshold: ${CPU_THRESHOLD}%"
    echo "  Memory threshold: ${MEMORY_THRESHOLD}%"
    echo "  Disk threshold: ${DISK_THRESHOLD}%"
    echo "  Temperature threshold: ${TEMP_THRESHOLD}°C"
    echo "  Check interval: ${CHECK_INTERVAL}s"
    
    if [[ -f "${TEMP_DIR}/notifications.log" ]]; then
        echo ""
        echo "Recent notifications:"
        tail -5 "${TEMP_DIR}/notifications.log"
    fi
}

# Command line interface
case "${1:-daemon}" in
    "daemon"|"start")
        if [[ -f "$LOCKFILE" ]] && kill -0 "$(cat "$LOCKFILE")" 2>/dev/null; then
            echo "Daemon already running"
            exit 1
        fi
        daemon_mode
        ;;
    "stop")
        stop_daemon
        ;;
    "status")
        show_status
        ;;
    "check")
        run_system_checks
        ;;
    "test")
        send_notification \
            "Test Notification" \
            "System notifications are working correctly" \
            "normal" \
            "$ICON_INFO"
        ;;
    "--help"|"-h"|"help")
        echo "Intelligent System Notifications"
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  daemon, start    Start monitoring daemon (default)"
        echo "  stop            Stop running daemon"
        echo "  status          Show daemon status and configuration"
        echo "  check           Run single check cycle"
        echo "  test            Send test notification"
        echo "  help            Show this help message"
        echo ""
        echo "Features:"
        echo "  • CPU, memory, disk, temperature monitoring"
        echo "  • Network connectivity changes"
        echo "  • USB device connect/disconnect"
        echo "  • System update reminders"
        echo "  • Focus/break reminders"
        echo "  • Maintenance reminders"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac