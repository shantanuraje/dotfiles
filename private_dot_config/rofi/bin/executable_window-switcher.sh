#!/usr/bin/env bash

# Catppuccin Macchiato Window Switcher for AwesomeWM
# Integrates with Rofi to provide a themed window switcher

# Get the directory of this script
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME="$DIR/../config/window.rasi"

# Check if we're running under AwesomeWM
if [[ "$XDG_SESSION_DESKTOP" == "awesome" ]] || pgrep -x awesome > /dev/null; then
    # Use wmctrl for better window management in AwesomeWM
    if command -v wmctrl &> /dev/null; then
        # Get window list with workspace info, sorted by workspace
        WINDOWS=$(wmctrl -l | sort -k2,2n -k1,1 | awk '{
            # Skip the window ID and workspace number
            id=$1; ws=$2; 
            # Get the hostname
            host=$3;
            # Everything after hostname is the window title
            title=""; for(i=4;i<=NF;i++) title=title" "$i;
            # Format: WindowID | Workspace | Title
            printf "%s | WS:%s |%s\n", id, ws+1, title
        }')
        
        # Show Rofi window switcher with our theme
        SELECTED=$(echo "$WINDOWS" | rofi -dmenu \
            -theme "$THEME" \
            -p "Window" \
            -i \
            -format "s" \
            -matching fuzzy)
        
        # If a window was selected, switch to it
        if [[ -n "$SELECTED" ]]; then
            # Extract window ID (first field)
            WINDOW_ID=$(echo "$SELECTED" | cut -d' ' -f1)
            # Use wmctrl to switch to the window
            wmctrl -ia "$WINDOW_ID"
        fi
    else
        # Fallback to standard Rofi window mode
        rofi -show window -theme "$THEME"
    fi
else
    # For other window managers, use standard Rofi window mode
    rofi -show window -theme "$THEME"
fi