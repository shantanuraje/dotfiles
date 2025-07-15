#!/usr/bin/env bash

# Enhanced uptime script with tooltip support

uptime_raw=$(uptime)

# Extract uptime in a more robust way
get_uptime() {
    if [[ $uptime_raw =~ up[[:space:]]+([0-9]+:[0-9]+) ]]; then
        # Format: "up 3:18"
        echo "${BASH_REMATCH[1]}"
    elif [[ $uptime_raw =~ up[[:space:]]+([0-9]+)[[:space:]]days?,?[[:space:]]+([0-9]+:[0-9]+) ]]; then
        # Format: "up 2 days, 3:18"
        echo "${BASH_REMATCH[1]}d ${BASH_REMATCH[2]}"
    elif [[ $uptime_raw =~ up[[:space:]]+([0-9]+)[[:space:]]days? ]]; then
        # Format: "up 5 days" (no hours/minutes)
        echo "${BASH_REMATCH[1]}d"
    elif [[ $uptime_raw =~ up[[:space:]]+([0-9]+)[[:space:]]min ]]; then
        # Format: "up 45 min"
        echo "${BASH_REMATCH[1]}m"
    else
        # Fallback: try to extract time using awk
        echo "$uptime_raw" | awk '{
            for(i=1; i<=NF; i++) {
                if($i ~ /^[0-9]+:[0-9]+$/) {
                    print $i
                    exit
                }
            }
        }' | head -1
    fi
}

# Output main uptime
get_uptime

# For tooltip (when called with --tooltip)
if [[ "$1" == "--tooltip" ]]; then
    echo "Full Uptime: $uptime_raw"
    echo ""
    echo "Boot Time: $(who -b | awk '{print $3, $4}')"
    echo "Current Time: $(date)"
    echo "Users Logged In: $(who | wc -l)"
fi
