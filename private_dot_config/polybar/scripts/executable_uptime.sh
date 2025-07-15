#!/usr/bin/env bash

# Robust uptime script for Polybar
# Handles different uptime formats and formats time without seconds

uptime_raw=$(uptime)

# Extract uptime in a more robust way and format properly
if [[ $uptime_raw =~ up[[:space:]]+([0-9]+):([0-9]+) ]]; then
    # Format: "up 3:18" - show as hours:minutes
    hours="${BASH_REMATCH[1]}"
    minutes="${BASH_REMATCH[2]}"
    echo "${hours}h ${minutes}m"
elif [[ $uptime_raw =~ up[[:space:]]+([0-9]+)[[:space:]]days?,?[[:space:]]+([0-9]+):([0-9]+) ]]; then
    # Format: "up 2 days, 3:18" - show days and hours:minutes
    days="${BASH_REMATCH[1]}"
    hours="${BASH_REMATCH[2]}"
    minutes="${BASH_REMATCH[3]}"
    echo "${days}d ${hours}h ${minutes}m"
elif [[ $uptime_raw =~ up[[:space:]]+([0-9]+)[[:space:]]days? ]]; then
    # Format: "up 5 days" (no hours/minutes)
    echo "${BASH_REMATCH[1]}d"
elif [[ $uptime_raw =~ up[[:space:]]+([0-9]+)[[:space:]]min ]]; then
    # Format: "up 45 min"
    echo "${BASH_REMATCH[1]}m"
else
    # Fallback: try to extract and format time using awk
    result=$(echo "$uptime_raw" | awk '{
        for(i=1; i<=NF; i++) {
            if($i ~ /^[0-9]+:[0-9]+$/) {
                split($i, time_parts, ":")
                printf "%sh %sm", time_parts[1], time_parts[2]
                exit
            }
        }
    }')
    
    if [ -n "$result" ]; then
        echo "$result"
    else
        # Final fallback - just show "up"
        echo "up"
    fi
fi
