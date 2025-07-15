#!/usr/bin/env bash

# Awesome workspaces integration for polybar
# This script shows current workspace and allows clicking to switch

# Function to get current workspace info from awesome
get_current_workspace() {
    echo 'return require("awful").screen.focused().selected_tag.index' | awesome-client 2>/dev/null | sed 's/.*: //' | tr -d ' \n'
}

# Function to get workspace info
get_workspace_info() {
    echo 'local s = require("awful").screen.focused(); local result = {}; for i = 1, #s.tags do local clients = #s.tags[i]:clients(); table.insert(result, tostring(clients)) end; return table.concat(result, ",")' | awesome-client 2>/dev/null | sed 's/.*: //' | tr -d ' \n'
}

# Handle click events
if [ -n "$1" ]; then
    case "$1" in
        1|2|3|4|5|6|7|8|9)
            echo "require('awful').screen.focused().tags[$1]:view_only()" | awesome-client >/dev/null 2>&1
            ;;
    esac
    exit 0
fi

# Get current workspace (1-based)
current=$(get_current_workspace)

# Get client counts for each workspace
workspace_info=$(get_workspace_info)

# If we can't get workspace info, show a fallback
if [ -z "$current" ] || [ -z "$workspace_info" ]; then
    echo "%{A1:~/.config/polybar/scripts/awesome-workspaces.sh 1:} 1 %{A}%{A1:~/.config/polybar/scripts/awesome-workspaces.sh 2:} 2 %{A}%{A1:~/.config/polybar/scripts/awesome-workspaces.sh 3:} 3 %{A}%{A1:~/.config/polybar/scripts/awesome-workspaces.sh 4:} 4 %{A}%{A1:~/.config/polybar/scripts/awesome-workspaces.sh 5:} 5 %{A}"
    exit 0
fi

# Split client counts by comma
IFS=',' read -ra CLIENT_COUNTS <<< "$workspace_info"

# Build output with proper formatting
output=""
for i in {1..5}; do
    # Get client count for this workspace (arrays are 0-indexed)
    array_index=$((i - 1))
    if [ $array_index -lt ${#CLIENT_COUNTS[@]} ]; then
        client_count=${CLIENT_COUNTS[$array_index]}
    else
        client_count=0
    fi
    
    # Format workspace based on status
    if [ "$i" = "$current" ]; then
        # Current workspace - highlighted with background
        workspace_display="%{F#1e2030}%{B#8bd5ca} $i %{B-}%{F-}"
    elif [ "$client_count" -gt 0 ] 2>/dev/null; then
        # Has clients - normal color
        workspace_display="%{F#cad3f5} $i %{F-}"
    else
        # Empty workspace - dimmed
        workspace_display="%{F#6e738d} $i %{F-}"
    fi
    
    # Add click action
    output+="%{A1:~/.config/polybar/scripts/awesome-workspaces.sh $i:}$workspace_display%{A}"
done

echo "$output"
