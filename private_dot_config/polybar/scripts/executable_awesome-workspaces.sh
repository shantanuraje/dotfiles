#!/usr/bin/env bash

# Enhanced Awesome workspaces integration for polybar
# This script shows current workspace and allows clicking to switch
# Supports workspace switching, window restoration, and window menu per workspace

# Function to get current workspace info from awesome
get_current_workspace() {
    echo 'return require("awful").screen.focused().selected_tag.index' | awesome-client 2>/dev/null | sed 's/.*: //' | tr -d ' \n'
}

# Function to get detailed workspace info (total clients, minimized clients)
get_workspace_info() {
    echo '
    local s = require("awful").screen.focused()
    local result = {}
    for i = 1, #s.tags do
        local total_clients = #s.tags[i]:clients()
        local minimized_clients = 0
        for _, c in ipairs(s.tags[i]:clients()) do
            if c.minimized then
                minimized_clients = minimized_clients + 1
            end
        end
        table.insert(result, string.format("%d:%d", total_clients, minimized_clients))
    end
    return table.concat(result, ",")
    ' | awesome-client 2>/dev/null | sed 's/.*: //' | tr -d ' \n'
}

# Function to show workspace window menu
show_workspace_menu() {
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
    
    # First, switch to the workspace
    echo "require('awful').screen.focused().tags[$workspace]:view_only()" | awesome-client >/dev/null 2>&1
    
    # Small delay to ensure workspace switch
    sleep 0.1
    
    # Then restore the window on the current (newly switched) workspace
    echo "
    local tag = require('awful').screen.focused().selected_tag
    if tag then
        local client = tag:clients()[$window_index]
        if client then
            client.minimized = false
            client:raise()
            require('awful').client.focus.byidx(0, client)
        end
    end
    " | awesome-client >/dev/null 2>&1
}

# Function to show rofi menu for workspace windows
show_workspace_window_menu() {
    local workspace=$1
    local windows_info
    windows_info=$(show_workspace_menu "$workspace")
    
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

# Handle click events
if [ -n "$1" ]; then
    case "$1" in
        menu-*)
            # Right-click menu for workspace windows
            workspace_num=${1#menu-}
            show_workspace_window_menu "$workspace_num" &
            ;;
        1|2|3|4|5|6|7|8|9)
            # Left-click to switch workspace
            echo "require('awful').screen.focused().tags[$1]:view_only()" | awesome-client >/dev/null 2>&1
            ;;
    esac
    exit 0
fi

# Get current workspace (1-based)
current=$(get_current_workspace)

# Get detailed workspace info (total:minimized)
workspace_info=$(get_workspace_info)

# If we can't get workspace info, show a fallback
if [ -z "$current" ] || [ -z "$workspace_info" ]; then
    echo "%{A1:~/.config/polybar/scripts/awesome-workspaces.sh 1:} 1 %{A}%{A1:~/.config/polybar/scripts/awesome-workspaces.sh 2:} 2 %{A}%{A1:~/.config/polybar/scripts/awesome-workspaces.sh 3:} 3 %{A}%{A1:~/.config/polybar/scripts/awesome-workspaces.sh 4:} 4 %{A}%{A1:~/.config/polybar/scripts/awesome-workspaces.sh 5:} 5 %{A}"
    exit 0
fi

# Split workspace info by comma
IFS=',' read -ra WORKSPACE_INFO <<< "$workspace_info"

# Build output with proper formatting
output=""
for i in {1..5}; do
    # Get workspace info for this workspace (arrays are 0-indexed)
    array_index=$((i - 1))
    if [ $array_index -lt ${#WORKSPACE_INFO[@]} ]; then
        workspace_data=${WORKSPACE_INFO[$array_index]}
        IFS=':' read -ra COUNTS <<< "$workspace_data"
        total_clients=${COUNTS[0]}
        minimized_clients=${COUNTS[1]}
    else
        total_clients=0
        minimized_clients=0
    fi
    
    # Format workspace based on status
    if [ "$i" = "$current" ]; then
        # Current workspace - highlighted with background
        if [ "$minimized_clients" -gt 0 ] 2>/dev/null; then
            workspace_display="%{F#1e2030}%{B#8bd5ca} $i󰖲 %{B-}%{F-}"
        else
            workspace_display="%{F#1e2030}%{B#8bd5ca} $i %{B-}%{F-}"
        fi
    elif [ "$total_clients" -gt 0 ] 2>/dev/null; then
        # Has clients - show with indicator
        if [ "$minimized_clients" -gt 0 ] 2>/dev/null; then
            workspace_display="%{F#cad3f5} $i󰖲 %{F-}"
        else
            workspace_display="%{F#cad3f5} $i %{F-}"
        fi
    else
        # Empty workspace - dimmed
        workspace_display="%{F#6e738d} $i %{F-}"
    fi
    
    # Add click actions (left-click to switch, right-click for menu)
    if [ "$total_clients" -gt 0 ] 2>/dev/null; then
        output+="%{A1:~/.config/polybar/scripts/awesome-workspaces.sh $i:}%{A3:~/.config/polybar/scripts/awesome-workspaces.sh menu-$i:}$workspace_display%{A}%{A}"
    else
        output+="%{A1:~/.config/polybar/scripts/awesome-workspaces.sh $i:}$workspace_display%{A}"
    fi
done

echo "$output"
