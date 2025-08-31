#!/usr/bin/env bash

# Universal window manager for polybar
# Provides multiple ways to access and restore windows across workspaces

# Colors for notifications
COLOR_SUCCESS="#8bd5ca"
COLOR_WARNING="#eed49f"
COLOR_ERROR="#ed8796"
COLOR_INFO="#8aadf4"

# Function to get current workspace
get_current_workspace() {
    echo 'return require("awful").screen.focused().selected_tag.index' | awesome-client 2>/dev/null | sed 's/.*: //' | tr -d ' \n'
}

# Function to get all windows from all workspaces with enhanced info
get_all_windows() {
    echo '
    local s = require("awful").screen.focused()
    local current_tag = s.selected_tag.index
    local result = {}
    
    for tag_idx = 1, #s.tags do
        for i, c in ipairs(s.tags[tag_idx]:clients()) do
            local status = c.minimized and "minimized" or "visible"
            local name = c.name or c.class or "Unknown"
            local id = tostring(c.window)
            local is_current = (tag_idx == current_tag) and "current" or "other"
            local urgent = c.urgent and "urgent" or "normal"
            table.insert(result, string.format("%d|%s|%s|%s|%s|%s|%d", tag_idx, status, name, id, is_current, urgent, i))
        end
    end
    return table.concat(result, "\n")
    ' | awesome-client 2>/dev/null | sed 's/.*string "\(.*\)"/\1/' | sed 's/\\n/\n/g'
}

# Function to get minimized windows count
get_minimized_count() {
    echo '
    local s = require("awful").screen.focused()
    local count = 0
    for tag_idx = 1, #s.tags do
        for _, c in ipairs(s.tags[tag_idx]:clients()) do
            if c.minimized then
                count = count + 1
            end
        end
    end
    return tostring(count)
    ' | awesome-client 2>/dev/null | sed 's/.*string "\(.*\)"/\1/'
}

# Function to restore window by window ID
restore_window() {
    local workspace=$1
    local window_id=$2
    
    # Log what we're trying to do
    echo "Restoring window: workspace=$workspace, window_id=$window_id" >> /tmp/window-manager-debug.log
    
    # Restore the window and switch to its workspace
    local result=$(echo "
    local awful = require('awful')
    local naughty = require('naughty')
    
    -- Find the client by window ID
    for s in screen do
        for _, tag in ipairs(s.tags) do
            for _, c in ipairs(tag:clients()) do
                if tostring(c.window) == '$window_id' then
                    naughty.notify({
                        title = 'Found Window',
                        text = string.format('Window: %s in workspace %d', 
                            c.name or 'Unknown', tag.index),
                        timeout = 2
                    })
                    -- Unminimize and activate
                    c.minimized = false
                    tag:view_only()
                    c:emit_signal('request::activate', 'window_manager', {raise = true})
                    awful.client.focus = c
                    c:raise()
                    return true
                end
            end
        end
    end
    
    naughty.notify({
        title = 'Error',
        text = string.format('Window with ID %s not found', '$window_id'),
        timeout = 2
    })
    return false
    " | awesome-client 2>&1)
    
    echo "Awesome-client result: $result" >> /tmp/window-manager-debug.log
}

# Function to show main window menu
show_main_menu() {
    local windows_info
    windows_info=$(get_all_windows)
    
    if [ -z "$windows_info" ] || [ "$windows_info" = "" ]; then
        notify-send "Window Manager" "No windows found" -t 2000 -i "dialog-information"
        return
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
            local is_current="${WINDOW[4]}"
            local urgent="${WINDOW[5]}"
            local index="${WINDOW[6]}"
            
            # Truncate long window names
            if [ ${#name} -gt 35 ]; then
                name="${name:0:32}..."
            fi
            
            # Build display string with indicators
            local display_line=""
            
            # Workspace indicator
            if [ "$is_current" = "current" ]; then
                display_line+="[$workspace] "
            else
                display_line+="[$workspace] "
            fi
            
            # Status indicator
            if [ "$status" = "minimized" ]; then
                display_line+="󰖲 "
            else
                display_line+="󰖯 "
            fi
            
            # Urgent indicator
            if [ "$urgent" = "urgent" ]; then
                display_line+="󰀦 "
            fi
            
            display_line+="$name"
            
            menu_entries+="$display_line\n"
            window_data[$line_num]="$workspace:$window_id"
            ((line_num++))
        fi
    done <<< "$windows_info"
    
    # Show rofi menu with our custom window theme
    local choice
    choice=$(echo -e "$menu_entries" | rofi \
        -dmenu \
        -i \
        -p "󰕰 Window Manager" \
        -theme ~/.config/rofi/config/window.rasi \
        -no-custom \
        -format 'i')
    
    if [ -n "$choice" ]; then
        local selected_data=${window_data[$choice]}
        if [ -n "$selected_data" ]; then
            IFS=':' read -ra RESTORE_INFO <<< "$selected_data"
            local workspace="${RESTORE_INFO[0]}"
            local window_id="${RESTORE_INFO[1]}"
            restore_window "$workspace" "$window_id"
            notify-send "Window Manager" "Switched to workspace $workspace" -t 1500 -i "dialog-information"
        fi
    fi
}

# Function to show minimized windows only
show_minimized_menu() {
    local windows_info
    windows_info=$(get_all_windows)
    
    if [ -z "$windows_info" ] || [ "$windows_info" = "" ]; then
        notify-send "Minimized Windows" "No minimized windows found" -t 2000 -i "dialog-information"
        return
    fi
    
    # Filter only minimized windows
    local menu_entries=""
    local window_data=()
    local line_num=0
    local found_minimized=false
    
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            IFS='|' read -ra WINDOW <<< "$line"
            local workspace="${WINDOW[0]}"
            local status="${WINDOW[1]}"
            local name="${WINDOW[2]}"
            local window_id="${WINDOW[3]}"
            local is_current="${WINDOW[4]}"
            local urgent="${WINDOW[5]}"
            local index="${WINDOW[6]}"
            
            # Only show minimized windows
            if [ "$status" = "minimized" ]; then
                found_minimized=true
                
                # Truncate long window names
                if [ ${#name} -gt 40 ]; then
                    name="${name:0:37}..."
                fi
                
                # Build display string
                local display_line="[$workspace] 󰖲 $name"
                
                # Add urgent indicator
                if [ "$urgent" = "urgent" ]; then
                    display_line="[$workspace] 󰖲 󰀦 $name"
                fi
                
                menu_entries+="$display_line\n"
                window_data[$line_num]="$workspace:$window_id"
                ((line_num++))
            fi
        fi
    done <<< "$windows_info"
    
    if [ "$found_minimized" = false ]; then
        notify-send "Minimized Windows" "No minimized windows found" -t 2000 -i "dialog-information"
        return
    fi
    
    # Show rofi menu for minimized windows
    local choice
    choice=$(echo -e "$menu_entries" | rofi \
        -dmenu \
        -i \
        -p "󰖲 Minimized Windows" \
        -theme ~/.config/rofi/config/window.rasi \
        -no-custom \
        -format 'i')
    
    if [ -n "$choice" ]; then
        local selected_data=${window_data[$choice]}
        if [ -n "$selected_data" ]; then
            IFS=':' read -ra RESTORE_INFO <<< "$selected_data"
            local workspace="${RESTORE_INFO[0]}"
            local window_id="${RESTORE_INFO[1]}"
            # Debug output
            notify-send "Debug" "Choice: $choice, Data: $selected_data, WS: $workspace, Window ID: $window_id" -t 3000
            restore_window "$workspace" "$window_id"
        else
            notify-send "Debug" "No data for choice: $choice" -t 3000
        fi
    fi
}

# Function to show current workspace windows
show_current_workspace_menu() {
    local current_workspace
    current_workspace=$(get_current_workspace)
    
    if [ -z "$current_workspace" ]; then
        notify-send "Error" "Could not determine current workspace" -t 2000 -i "dialog-error"
        return
    fi
    
    local windows_info
    windows_info=$(get_all_windows)
    
    if [ -z "$windows_info" ] || [ "$windows_info" = "" ]; then
        notify-send "Workspace $current_workspace" "No windows in current workspace" -t 2000 -i "dialog-information"
        return
    fi
    
    # Filter current workspace windows
    local menu_entries=""
    local window_data=()
    local line_num=0
    local found_current=false
    
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            IFS='|' read -ra WINDOW <<< "$line"
            local workspace="${WINDOW[0]}"
            local status="${WINDOW[1]}"
            local name="${WINDOW[2]}"
            local window_id="${WINDOW[3]}"
            local is_current="${WINDOW[4]}"
            local urgent="${WINDOW[5]}"
            local index="${WINDOW[6]}"
            
            # Only show current workspace windows
            if [ "$workspace" = "$current_workspace" ]; then
                found_current=true
                
                # Truncate long window names
                if [ ${#name} -gt 45 ]; then
                    name="${name:0:42}..."
                fi
                
                # Build display string
                local display_line=""
                if [ "$status" = "minimized" ]; then
                    display_line+="󰖲 "
                else
                    display_line+="󰖯 "
                fi
                
                if [ "$urgent" = "urgent" ]; then
                    display_line+="󰀦 "
                fi
                
                display_line+="$name"
                
                menu_entries+="$display_line\n"
                window_data[$line_num]="$workspace:$window_id"
                ((line_num++))
            fi
        fi
    done <<< "$windows_info"
    
    if [ "$found_current" = false ]; then
        notify-send "Workspace $current_workspace" "No windows in current workspace" -t 2000 -i "dialog-information"
        return
    fi
    
    # Show rofi menu for current workspace
    local choice
    choice=$(echo -e "$menu_entries" | rofi \
        -dmenu \
        -i \
        -p "󰧨 Workspace $current_workspace" \
        -theme ~/.config/rofi/config/window.rasi \
        -no-custom \
        -format 'i')
    
    if [ -n "$choice" ]; then
        local selected_data=${window_data[$choice]}
        if [ -n "$selected_data" ]; then
            IFS=':' read -ra RESTORE_INFO <<< "$selected_data"
            local workspace="${RESTORE_INFO[0]}"
            local window_id="${RESTORE_INFO[1]}"
            restore_window "$workspace" "$window_id"
        fi
    fi
}

# Test function to restore first minimized window
test_restore() {
    echo "
    local awful = require('awful')
    local naughty = require('naughty')
    
    -- Find first minimized window
    for _, tag in ipairs(awful.screen.focused().tags) do
        for _, c in ipairs(tag:clients()) do
            if c.minimized then
                naughty.notify({title = 'Found minimized', text = c.name or 'Unknown'})
                c.minimized = false
                tag:view_only()
                c:emit_signal('request::activate', 'test', {raise = true})
                return 'Restored: ' .. (c.name or 'Unknown')
            end
        end
    end
    return 'No minimized windows found'
    " | awesome-client
}

# Main execution
case "${1:-main}" in
    "main"|"all")
        show_main_menu &
        ;;
    "minimized")
        show_minimized_menu &
        ;;
    "current")
        show_current_workspace_menu &
        ;;
    "count")
        # Return count for display in polybar
        minimized_count=$(get_minimized_count)
        if [ -n "$minimized_count" ] && [ "$minimized_count" -gt 0 ]; then
            echo "$minimized_count"
        else
            echo ""
        fi
        ;;
    "display")
        # Always show something for polybar display
        minimized_count=$(get_minimized_count)
        if [ -n "$minimized_count" ] && [ "$minimized_count" -gt 0 ]; then
            echo " ($minimized_count)"
        else
            echo ""  # Empty but prefix icon will still show
        fi
        ;;
    "test")
        test_restore
        ;;
    *)
        echo "Usage: $0 [main|minimized|current|count|display]"
        echo "  main      - Show all windows from all workspaces"
        echo "  minimized - Show only minimized windows"
        echo "  current   - Show windows from current workspace"
        echo "  count     - Return count of minimized windows"
        echo "  display   - Display mode for polybar (shows count in parentheses)"
        exit 1
        ;;
esac
