#!/usr/bin/env bash

# Polybar launch script with proper process management
# Based on common solutions for AwesomeWM integration

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a /tmp/polybar.log
}

# Terminate already running bar instances
log "Terminating existing polybar instances..."
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do 
    log "Waiting for polybar to terminate..."
    sleep 1
done

# Small delay to ensure clean shutdown
sleep 1

# Detect connected monitors
MONITORS=$(xrandr --query | grep " connected" | cut -d" " -f1)
log "Detected monitors: $MONITORS"

# Launch polybar on each connected monitor
for monitor in $MONITORS; do
    log "Launching polybar on monitor: $monitor"

    # Get monitor resolution to detect orientation
    MONITOR_INFO=$(xrandr --query | grep "^$monitor connected" | grep -oP '\d+x\d+')
    WIDTH=$(echo $MONITOR_INFO | cut -d'x' -f1)
    HEIGHT=$(echo $MONITOR_INFO | cut -d'x' -f2)

    # Determine config based on orientation
    if [ "$HEIGHT" -gt "$WIDTH" ]; then
        # Vertical/Portrait monitor
        CONFIG="~/.config/polybar/config-vertical.ini"
        log "Monitor $monitor is vertical (${WIDTH}x${HEIGHT}), using vertical config"
    else
        # Horizontal/Landscape monitor
        CONFIG="~/.config/polybar/config.ini"
        log "Monitor $monitor is horizontal (${WIDTH}x${HEIGHT}), using standard config"
    fi

    MONITOR=$monitor polybar main -c $CONFIG 2>&1 | tee -a /tmp/polybar.log &

    # Get the PID and disown the process
    POLYBAR_PID=$!
    disown

    log "Polybar launched on $monitor with PID: $POLYBAR_PID"
done
