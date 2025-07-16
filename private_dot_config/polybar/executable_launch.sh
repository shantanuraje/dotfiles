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

# Launch polybar using the config location
log "Launching polybar..."
polybar main -c ~/.config/polybar/config.ini 2>&1 | tee -a /tmp/polybar.log &

# Get the PID and disown the process
POLYBAR_PID=$!
disown

log "Polybar launched with PID: $POLYBAR_PID"
