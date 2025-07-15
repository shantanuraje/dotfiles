#!/usr/bin/env bash

# Enhanced CPU information script

cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
cpu_model=$(cat /proc/cpuinfo | grep "model name" | head -1 | cut -d':' -f2- | xargs)
cpu_cores=$(nproc)
cpu_freq=$(cat /proc/cpuinfo | grep "cpu MHz" | head -1 | cut -d':' -f2 | xargs | cut -d'.' -f1)

# Get temperature if available
temp=""
if command -v sensors &> /dev/null; then
    temp=$(sensors 2>/dev/null | grep -E "Core 0|Package" | head -1 | awk '{print $3}' | sed 's/+//g' | sed 's/°C.*//g')
    if [[ -n "$temp" ]]; then
        temp=" | Temp: ${temp}°C"
    fi
fi

# Get load averages
load=$(cat /proc/loadavg | awk '{print $1, $2, $3}')

notify-send "CPU Information" \
"Processor: $cpu_model
Cores: $cpu_cores
Frequency: ${cpu_freq} MHz
Usage: ${cpu_usage}%${temp}
Load Average: $load

$(top -bn1 | head -12 | tail -7)"
