#!/usr/bin/env bash

# Enhanced memory information script

# Get memory info
memory_info=$(free -h)
memory_used=$(echo "$memory_info" | awk 'NR==2{print $3}')
memory_total=$(echo "$memory_info" | awk 'NR==2{print $2}')
memory_available=$(echo "$memory_info" | awk 'NR==2{print $7}')
memory_percent=$(echo "$memory_info" | awk 'NR==2{printf "%.1f", $3/$2 * 100}')

# Get swap info
swap_used=$(echo "$memory_info" | awk 'NR==3{print $3}')
swap_total=$(echo "$memory_info" | awk 'NR==3{print $2}')

# Get top memory processes
top_processes=$(ps aux --sort=-%mem | head -6 | tail -5 | awk '{printf "%-15s %5s%%\n", $11, $4}')

notify-send "Memory Information" \
"RAM Usage: $memory_used / $memory_total (${memory_percent}%)
Available: $memory_available
Swap: $swap_used / $swap_total

Top Memory Processes:
$top_processes

Full Memory Details:
$memory_info"
