#!/usr/bin/env bash

# Workspace-specific window manager for polybar
# This script provides window management across all workspaces

# Function to get all windows from all workspaces
get_all_workspace_windows() {
    echo '
    local s = require("awful").screen.focused()
    local result = {}
    for tag_idx = 1, #s.tags do
        for i, c in ipairs(s.tags[tag_idx]:clients()) do
            local status = c.minimized and "minimized" or "visible"
            local name = c.name or c.class or "Unknown"
            local id = tostring(c.window)
            table.insert(result, string.format("%d|%s|%s|%s|%d", tag_idx, status, name, id, i))
        end
    end
    return table.concat(result, "\n")
    ' | awesome-client 2>/dev/null | sed 's/.*string "\(.*\)"/\1/' | sed 's/\\n/\n/g'
}

# Function to get windows from specific workspace
get_workspace_windows() {
    local workspace=$1
    echo "
    local workspace_num = $workspace
    local s = require('awful').screen.focused()
    local tag = s.tags[workspace_num]
    local windows = {}
    
    if tag then
        for i, c in ipairs(tag:clients()) do
            local status = c.minimized and 'minimized' or 'visible'
            local name = c.name or c.class or 'Unknown'
            local id = tostring(c.window)
            table.insert(windows, string.format('%s|%s|%s|%d', status, name, id, i))
        end
    end
    return table.concat(windows, '\n')
    " | awesome-client 2>/dev/null | sed 's/.*string "\(.*\)"/\1/' | sed 's/\\n/\n/g'
}

# Function to restore window in specific workspace
restore_window_in_workspace() {
    local workspace=$1
    local window_index=$2
    echo "
    local workspace_num = $workspace
    local window_idx = $window_index
    local s = require('awful').screen.focused()
    local tag = s.tags[workspace_num]
    
    if tag then
        local client = tag:clients()[window_idx]
        if client then
            -- Switch to the workspace first
            tag:view_only()
            -- Then restore and focus the window
            client.minimized = false
            client:raise()
            require('awful').client.focus.byidx(0, client)
        end
    end
    " | awesome-client >/dev/null 2>&1
}

# Function to show all windows menu
show_all_windows_menu() {
    local windows_info
    windows_info=$(get_all_workspace_windows)
    
    if [ -z "$windows_info" ] || [ "$windows_info" = "" ]; then
        notify-send "Window Manager" "No windows found in any workspace" -t 2000 -i "dialog-information"
        exit 0
    fi
    
    # Prepare rofi menu entries
    local menu_entries=""
    local window_data=()
    local line_num=0
    
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            IFS='|' read -ra WINDOW <<< "$line"
            local workspace="${WINDOW[0]}"
            local status="${WINDOW[1]}"
            local name="${WINDOW[2]}"
            local window_id="${WINDOW[3]}"
            local index="${WINDOW[4]}"
            
            # Truncate long window names
            if [ ${#name} -gt 40 ]; then
                name="${name:0:37}..."
            fi
            
            # Add status and workspace indicator
            if [ "$status" = "minimized" ]; then
                menu_entries+="[$workspace] 󰖲 $name\n"
            else
                menu_entries+="[$workspace] 󰖯 $name\n"
            fi
            
            window_data[$line_num]="$workspace:$index"
            ((line_num++))
        fi
    done <<< "$windows_info"
    
    if [ -z "$menu_entries" ]; then
        notify-send "Window Manager" "No windows to display" -t 2000 -i "dialog-information"
        exit 0
    fi
    
    # Show rofi menu with custom theme
    local choice
    choice=$(echo -e "$menu_entries" | rofi \
        -dmenu \
        -i \
        -p "All Windows" \
        -theme-str 'window {width: 80%; height: 60%;}' \
        -theme-str 'listview {lines: 12;}' \
        -theme-str 'element {padding: 10px;}' \
        -no-custom \
        -format 'i')
    
    if [ -n "$choice" ]; then
        local selected_data=${window_data[$choice]}
        if [ -n "$selected_data" ]; then
            IFS=':' read -ra RESTORE_INFO <<< "$selected_data"
            local workspace="${RESTORE_INFO[0]}"
            local index="${RESTORE_INFO[1]}"
            restore_window_in_workspace "$workspace" "$index"
        fi
    fi
}

# Function to show workspace-specific window menu
show_workspace_window_menu() {
    local workspace=$1
    local windows_info
    windows_info=$(get_workspace_windows "$workspace")
    
    if [ -z "$windows_info" ] || [ "$windows_info" = "" ]; then
        notify-send "Workspace $workspace" "No windows in this workspace" -t 2000 -i "dialog-information"
        exit 0
    fi
    
    # Prepare rofi menu entries
    local menu_entries=""
    local window_indices=()
    local line_num=0
    
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            IFS='|' read -ra WINDOW <<< "$line"
            local status="${WINDOW[0]}"
            local name="${WINDOW[1]}"
            local window_id="${WINDOW[2]}"
            local index="${WINDOW[3]}"
            
            # Truncate long window names
            if [ ${#name} -gt 50 ]; then
                name="${name:0:47}..."
            fi
            
            # Add status indicator
            if [ "$status" = "minimized" ]; then
                menu_entries+="󰖲 $name\n"
            else
                menu_entries+="󰖯 $name\n"
            fi
            
            window_indices[$line_num]=$index
            ((line_num++))
        fi
    done <<< "$windows_info"
    
    if [ -z "$menu_entries" ]; then
        notify-send "Workspace $workspace" "No windows to display" -t 2000 -i "dialog-information"
        exit 0
    fi
    
    # Show rofi menu with custom theme
    local choice
    choice=$(echo -e "$menu_entries" | rofi \
        -dmenu \
        -i \
        -p "Workspace $workspace Windows" \
        -theme-str 'window {width: 70%; height: 50%;}' \
        -theme-str 'listview {lines: 10;}' \
        -theme-str 'element {padding: 8px;}' \
        -no-custom \
        -format 'i')
    
    if [ -n "$choice" ]; then
        local selected_index=${window_indices[$choice]}
        if [ -n "$selected_index" ]; then
            restore_window_in_workspace "$workspace" "$selected_index"
        fi
    fi
}

# Main logic
case "${1:-all}" in
    "all")
        show_all_windows_menu &
        ;;
    "workspace")
        if [ -n "$2" ]; then
            show_workspace_window_menu "$2" &
        else
            echo "Usage: $0 workspace <workspace_number>"
            exit 1
        fi
        ;;
    *)
        echo "Usage: $0 [all|workspace <num>]"
        exit 1
        ;;
esac
