#!/usr/bin/env bash

# Enhanced window switcher for polybar with Alt+Tab integration
# This provides both polybar menu and Alt+Tab cycling functionality

# Function to get window information from awesome
get_windows() {
    echo '
    local windows = {}
    local tag = require("awful").screen.focused().selected_tag
    if tag then
        for i, c in ipairs(tag:clients()) do
            local status = c.minimized and "minimized" or "visible"
            local name = c.name or c.class or "Unknown"
            local id = tostring(c.window)
            table.insert(windows, string.format("%s|%s|%s|%d", status, name, id, i))
        end
    end
    return table.concat(windows, "\n")
    ' | awesome-client 2>/dev/null | sed 's/.*string "\(.*\)"/\1/' | sed 's/\\n/\n/g'
}

# Function to get count of minimized windows
get_minimized_count() {
    echo '
    local count = 0
    local tag = require("awful").screen.focused().selected_tag
    if tag then
        for _, c in ipairs(tag:clients()) do
            if c.minimized then
                count = count + 1
            end
        end
    end
    return tostring(count)
    ' | awesome-client 2>/dev/null | sed 's/.*string "\(.*\)"/\1/'
}

# Function to get all windows for Alt+Tab
get_all_windows() {
    echo '
    local windows = {}
    local tag = require("awful").screen.focused().selected_tag
    if tag then
        for i, c in ipairs(tag:clients()) do
            if not c.minimized then
                local name = c.name or c.class or "Unknown"
                local id = tostring(c.window)
                local is_focused = client.focus == c and "focused" or "unfocused"
                table.insert(windows, string.format("%s|%s|%s|%d", is_focused, name, id, i))
            end
        end
    end
    return table.concat(windows, "\n")
    ' | awesome-client 2>/dev/null | sed 's/.*string "\(.*\)"/\1/' | sed 's/\\n/\n/g'
}

# Function to restore a window by index
restore_window() {
    local index=$1
    echo "
    local tag = require('awful').screen.focused().selected_tag
    if tag then
        local client = tag:clients()[$index]
        if client then
            client.minimized = false
            client:raise()
            require('awful').client.focus.byidx(0, client)
        end
    end
    " | awesome-client >/dev/null 2>&1
}

# Function to focus window by index (for Alt+Tab)
focus_window() {
    local index=$1
    echo "
    local tag = require('awful').screen.focused().selected_tag
    if tag then
        local client = tag:clients()[$index]
        if client and not client.minimized then
            client:raise()
            require('awful').client.focus.byidx(0, client)
        end
    end
    " | awesome-client >/dev/null 2>&1
}

# Function to show rofi window menu for polybar click
show_window_menu() {
    local windows_info
    windows_info=$(get_windows)
    
    if [ -z "$windows_info" ] || [ "$windows_info" = "" ]; then
        notify-send "Window Menu" "No windows in current workspace" -t 2000
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
                menu_entries+=" $name\n"
            else
                menu_entries+=" $name\n"
            fi
            
            window_indices[$line_num]=$index
            ((line_num++))
        fi
    done <<< "$windows_info"
    
    if [ -z "$menu_entries" ]; then
        notify-send "Window Menu" "No windows to display" -t 2000
        exit 0
    fi
    
    # Show rofi menu with custom theme
    local choice
    choice=$(echo -e "$menu_entries" | rofi \
        -dmenu \
        -i \
        -p "Windows" \
        -theme-str 'window {width: 60%; height: 40%;}' \
        -theme-str 'listview {lines: 8;}' \
        -theme-str 'element {padding: 8px;}' \
        -no-custom \
        -format 'i')
    
    if [ -n "$choice" ]; then
        local selected_index=${window_indices[$choice]}
        if [ -n "$selected_index" ]; then
            restore_window "$selected_index"
        fi
    fi
}

# Function to show Alt+Tab style switcher
show_alt_tab_switcher() {
    local windows_info
    windows_info=$(get_all_windows)
    
    if [ -z "$windows_info" ] || [ "$windows_info" = "" ]; then
        notify-send "Alt+Tab" "No visible windows in current workspace" -t 1000
        exit 0
    fi
    
    # Prepare rofi menu entries
    local menu_entries=""
    local window_indices=()
    local line_num=0
    local current_focused=""
    
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            IFS='|' read -ra WINDOW <<< "$line"
            local focus_status="${WINDOW[0]}"
            local name="${WINDOW[1]}"
            local window_id="${WINDOW[2]}"
            local index="${WINDOW[3]}"
            
            # Truncate long window names
            if [ ${#name} -gt 40 ]; then
                name="${name:0:37}..."
            fi
            
            # Mark focused window
            if [ "$focus_status" = "focused" ]; then
                menu_entries+=" $name\n"
                current_focused=$line_num
            else
                menu_entries+=" $name\n"
            fi
            
            window_indices[$line_num]=$index
            ((line_num++))
        fi
    done <<< "$windows_info"
    
    if [ -z "$menu_entries" ]; then
        exit 0
    fi
    
    # Show rofi in Alt+Tab mode (faster, more compact)
    local choice
    choice=$(echo -e "$menu_entries" | rofi \
        -dmenu \
        -i \
        -p "Alt+Tab" \
        -theme-str 'window {width: 50%; height: 30%;}' \
        -theme-str 'listview {lines: 6; scrollbar: false;}' \
        -theme-str 'element {padding: 4px;}' \
        -theme-str 'inputbar {enabled: false;}' \
        -selected-row "${current_focused:-0}" \
        -no-custom \
        -format 'i')
    
    if [ -n "$choice" ]; then
        local selected_index=${window_indices[$choice]}
        if [ -n "$selected_index" ]; then
            focus_window "$selected_index"
        fi
    fi
}

# Main logic
case "${1:-display}" in
    "click")
        show_window_menu &
        ;;
    "alt-tab")
        show_alt_tab_switcher &
        ;;
    "display"|*)
        # Count minimized windows and display appropriate icon
        minimized_count=$(get_minimized_count)
        
        if [ -n "$minimized_count" ] && [ "$minimized_count" -gt 0 ]; then
            echo "($minimized_count)"
        else
            echo ""
        fi
        ;;
esac
