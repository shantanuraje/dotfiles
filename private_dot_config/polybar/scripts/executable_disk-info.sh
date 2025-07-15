#!/usr/bin/env bash

# Enhanced disk information script

# Get disk usage for all mounted filesystems
disk_info=$(df -h --output=source,size,used,avail,pcent,target | grep -E "^/dev")

# Get root filesystem specific info
root_usage=$(df -h / | awk 'NR==2{print $3 "/" $2 " (" $5 ")"}')
root_available=$(df -h / | awk 'NR==2{print $4}')

# Get disk I/O stats if available
io_stats=""
if command -v iostat &> /dev/null; then
    io_stats=$(iostat -d 1 1 2>/dev/null | tail -n +4 | head -3)
fi

# Get filesystem types
fs_types=$(mount | grep "^/dev" | awk '{print $1 " -> " $5}' | head -5)

notify-send "Disk Information" \
"Root Usage: $root_usage
Available: $root_available

All Mounted Disks:
$disk_info

Filesystem Types:
$fs_types"
