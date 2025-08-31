#!/usr/bin/env bash

# Advanced Catppuccin Macchiato Window Switcher for AwesomeWM
# Features: Current workspace filter, all windows, minimized windows

# Get the directory of this script
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME="$DIR/../config/window.rasi"

# Parse command line arguments
MODE="${1:-all}"  # all, current, minimized

# Function to get current workspace
get_current_workspace() {
    if command -v wmctrl &> /dev/null; then
        wmctrl -d | grep '\*' | cut -d' ' -f1
    else
        echo "0"
    fi
}

# Function to get window icon based on class
get_window_icon() {
    local class="$1"
    case "${class,,}" in  # Convert to lowercase
        *firefox*) echo "firefox" ;;
        *chrome*|*chromium*) echo "google-chrome" ;;
        *code*|*vscode*) echo "visual-studio-code" ;;
        *terminal*|*kitty*|*alacritty*) echo "utilities-terminal" ;;
        *thunar*|*nautilus*|*dolphin*) echo "system-file-manager" ;;
        *discord*) echo "discord" ;;
        *slack*) echo "slack" ;;
        *spotify*) echo "spotify" ;;
        *) echo "application-x-executable" ;;
    esac
}

# Main window switcher logic
if command -v wmctrl &> /dev/null && command -v xprop &> /dev/null; then
    CURRENT_WS=$(get_current_workspace)
    
    # Get window list with detailed info, sorted by workspace then by stacking order
    WINDOW_LIST=""
    # Sort by workspace number (field 2) then keep original order
    while IFS= read -r line; do
        # Parse wmctrl output
        WIN_ID=$(echo "$line" | awk '{print $1}')
        WIN_WS=$(echo "$line" | awk '{print $2}')
        WIN_HOST=$(echo "$line" | awk '{print $3}')
        WIN_TITLE=$(echo "$line" | cut -d' ' -f4-)
        
        # Get window class for icon
        WIN_CLASS=$(xprop -id "$WIN_ID" WM_CLASS 2>/dev/null | grep -oP '"\K[^"]+' | tail -1)
        
        # Check if window is minimized
        IS_MINIMIZED=$(xprop -id "$WIN_ID" WM_STATE 2>/dev/null | grep -q 'window state: Iconic' && echo "true" || echo "false")
        
        # Filter based on mode
        case "$MODE" in
            "current")
                [[ "$WIN_WS" != "$CURRENT_WS" ]] && continue
                ;;
            "minimized")
                [[ "$IS_MINIMIZED" != "true" ]] && continue
                ;;
        esac
        
        # Format window entry
        ICON=$(get_window_icon "$WIN_CLASS")
        STATUS=""
        [[ "$IS_MINIMIZED" == "true" ]] && STATUS=" [MIN]"
        [[ "$WIN_WS" == "$CURRENT_WS" ]] && WS_INDICATOR="●" || WS_INDICATOR="○"
        
        # Add to list: ID | Icon | Workspace | Title
        WINDOW_LIST+="$WIN_ID\x00icon\x1f$ICON\x1fmeta\x1f$WS_INDICATOR WS:$((WIN_WS + 1))$STATUS | $WIN_TITLE\n"
    done < <(wmctrl -l | sort -k2,2n -k1,1)
    
    # Determine prompt based on mode
    case "$MODE" in
        "current") PROMPT="Current Workspace" ;;
        "minimized") PROMPT="Minimized Windows" ;;
        *) PROMPT="All Windows" ;;
    esac
    
    # Show Rofi with our custom theme
    SELECTED=$(echo -e "$WINDOW_LIST" | rofi -dmenu \
        -theme "$THEME" \
        -p "$PROMPT" \
        -i \
        -format "s" \
        -matching fuzzy \
        -markup-rows)
    
    # If a window was selected, switch to it
    if [[ -n "$SELECTED" ]]; then
        # Extract window ID (first field)
        WINDOW_ID=$(echo "$SELECTED" | cut -d' ' -f1)
        
        # Switch to window and unminimize if needed
        wmctrl -ia "$WINDOW_ID"
        
        # For AwesomeWM, also raise the window
        if [[ "$XDG_SESSION_DESKTOP" == "awesome" ]] || pgrep -x awesome > /dev/null; then
            xdotool windowraise "$WINDOW_ID" 2>/dev/null || true
        fi
    fi
else
    # Fallback to standard Rofi window mode
    rofi -show window -theme "$THEME"
fi