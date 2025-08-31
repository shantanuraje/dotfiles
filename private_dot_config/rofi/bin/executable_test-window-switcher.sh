#!/usr/bin/env bash

# Test script for the Catppuccin window switcher

echo "Testing Rofi Window Switcher with Catppuccin Macchiato theme..."
echo

# Check dependencies
echo "Checking dependencies:"
command -v rofi &> /dev/null && echo "✓ rofi installed" || echo "✗ rofi not found"
command -v wmctrl &> /dev/null && echo "✓ wmctrl installed" || echo "✗ wmctrl not found (optional)"
command -v xprop &> /dev/null && echo "✓ xprop installed" || echo "✗ xprop not found (optional)"
command -v xdotool &> /dev/null && echo "✓ xdotool installed" || echo "✗ xdotool not found (optional)"
echo

# Test theme file
THEME_FILE="$(dirname "$0")/../config/window.rasi"
if [[ -f "$THEME_FILE" ]]; then
    echo "✓ Theme file exists: $THEME_FILE"
else
    echo "✗ Theme file not found: $THEME_FILE"
fi
echo

# Test scripts
echo "Testing window switcher scripts:"
for script in window-switcher.sh window-switcher-advanced.sh; do
    SCRIPT_PATH="$(dirname "$0")/$script"
    if [[ -x "$SCRIPT_PATH" ]]; then
        echo "✓ $script is executable"
    else
        echo "✗ $script not found or not executable"
    fi
done
echo

# Test basic Rofi functionality with theme
echo "Testing basic Rofi with theme (press Escape to close):"
echo -e "Test Item 1\nTest Item 2\nTest Item 3" | rofi -dmenu -theme "$THEME_FILE" -p "Test"

echo
echo "Window switcher is ready to use!"
echo
echo "Usage:"
echo "  All windows:        ~/.config/rofi/bin/window-switcher-advanced.sh all"
echo "  Current workspace:  ~/.config/rofi/bin/window-switcher-advanced.sh current"
echo "  Minimized windows:  ~/.config/rofi/bin/window-switcher-advanced.sh minimized"
echo "  Simple switcher:    ~/.config/rofi/bin/window-switcher.sh"