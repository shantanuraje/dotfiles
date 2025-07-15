#!/usr/bin/env bash

# Enhanced network information script

# Get active network interface
active_interface=$(ip route | grep default | awk '{print $5}' | head -1)

if [[ -n "$active_interface" ]]; then
    # Get interface details
    ip_address=$(ip addr show $active_interface | grep "inet " | awk '{print $2}' | cut -d'/' -f1)
    mac_address=$(ip addr show $active_interface | grep "link/ether" | awk '{print $2}')
    
    # Get link status
    link_status=$(cat /sys/class/net/$active_interface/operstate)
    
    # Get speed if available
    speed=""
    if [[ -f "/sys/class/net/$active_interface/speed" ]]; then
        speed_mbps=$(cat /sys/class/net/$active_interface/speed 2>/dev/null)
        if [[ "$speed_mbps" != "-1" ]] && [[ -n "$speed_mbps" ]]; then
            speed=" | Speed: ${speed_mbps} Mbps"
        fi
    fi
    
    # Get wireless info if it's a wireless interface
    wireless_info=""
    if [[ -d "/sys/class/net/$active_interface/wireless" ]]; then
        if command -v iwconfig &> /dev/null; then
            essid=$(iwconfig $active_interface 2>/dev/null | grep "ESSID" | cut -d'"' -f2)
            signal=$(iwconfig $active_interface 2>/dev/null | grep "Signal level" | awk '{print $4}' | cut -d'=' -f2)
            if [[ -n "$essid" ]]; then
                wireless_info="Network: $essid"
                if [[ -n "$signal" ]]; then
                    wireless_info="$wireless_info | Signal: $signal"
                fi
                wireless_info="$wireless_info\n"
            fi
        fi
    fi
    
    # Get network statistics
    rx_bytes=$(cat /sys/class/net/$active_interface/statistics/rx_bytes)
    tx_bytes=$(cat /sys/class/net/$active_interface/statistics/tx_bytes)
    rx_mb=$(echo "scale=1; $rx_bytes / 1024 / 1024" | bc 2>/dev/null || echo "N/A")
    tx_mb=$(echo "scale=1; $tx_bytes / 1024 / 1024" | bc 2>/dev/null || echo "N/A")
    
    notify-send "Network Information" \
"Interface: $active_interface
${wireless_info}IP Address: $ip_address
MAC Address: $mac_address
Status: $link_status${speed}

Data Transfer:
Downloaded: ${rx_mb} MB
Uploaded: ${tx_mb} MB

$(ip addr show $active_interface | head -10)"
else
    notify-send "Network Information" "No active network interface found"
fi
