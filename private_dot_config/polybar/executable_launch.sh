#!/usr/bin/env bash

# Terminate already running bar instances
pkill -f polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch polybar using the config location
nohup polybar main -c ~/.config/polybar/config.ini &>/dev/null &

echo "Polybar launched..."
