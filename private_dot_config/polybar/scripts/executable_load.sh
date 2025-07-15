#!/usr/bin/env bash

# Enhanced load average script with tooltip support

# Get load averages
LOAD=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
LOAD_1=$(echo $LOAD | awk '{print $1}')
LOAD_5=$(echo $LOAD | awk '{print $2}')
LOAD_15=$(echo $LOAD | awk '{print $3}')

# Get number of CPU cores
CORES=$(nproc)

# Calculate load percentage (load/cores * 100)
LOAD_PERCENT=$(echo "$LOAD_1 $CORES" | awk '{printf "%.1f", ($1/$2)*100}')

# Output format for polybar
echo "$LOAD"

# For tooltip (when called with --tooltip)
if [[ "$1" == "--tooltip" ]]; then
    echo "Load Average: $LOAD_1 (1m) | $LOAD_5 (5m) | $LOAD_15 (15m)"
    echo "CPU Cores: $CORES"
    echo "Load Percentage: ${LOAD_PERCENT}%"
    echo ""
    echo "Running Processes: $(ps aux | wc -l)"
fi
