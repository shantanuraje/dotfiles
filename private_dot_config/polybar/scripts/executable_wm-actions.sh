#!/usr/bin/env bash

# Unified Command Palette for AwesomeWM
# Combines app launcher (drun), window switcher (window), and WM actions
# into a single rofi window with tabs. Tab with Ctrl+Tab or click tabs.
#
# Usage:
#   wm-actions.sh          - opens on Actions tab
#   wm-actions.sh apps     - opens on Apps tab
#   wm-actions.sh windows  - opens on Windows tab

THEME="$HOME/.config/rofi/config/wm-actions.rasi"
SCRIPT="$HOME/.config/rofi/bin/wm-actions-mode.sh"

# Which tab to show first
MODE="${1:-actions}"
case "$MODE" in
    apps)    SHOW="drun" ;;
    windows) SHOW="window" ;;
    *)       SHOW="actions" ;;
esac

rofi -modi "drun,window,actions:${SCRIPT}" \
     -show "$SHOW" \
     -theme "$THEME" \
     -display-drun "󰀻 Apps" \
     -display-window "󰖲 Windows" \
     -display-actions "󰣆 Actions" \
     2>/dev/null
