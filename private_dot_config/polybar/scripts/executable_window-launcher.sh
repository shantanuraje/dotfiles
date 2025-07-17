#!/usr/bin/env bash

# Quick launcher for window management functions
# This script can be used in keybindings or as a standalone tool

case "${1:-help}" in
    "workspace-menu")
        # Show workspace-specific window menu
        if [ -n "$2" ]; then
            ~/.config/polybar/scripts/awesome-workspaces.sh "menu-$2"
        else
            # Get current workspace and show its menu
            current=$(echo 'return require("awful").screen.focused().selected_tag.index' | awesome-client 2>/dev/null | sed 's/.*: //' | tr -d ' \n')
            if [ -n "$current" ]; then
                ~/.config/polybar/scripts/awesome-workspaces.sh "menu-$current"
            fi
        fi
        ;;
    "all-windows")
        ~/.config/polybar/scripts/window-manager.sh main
        ;;
    "minimized")
        ~/.config/polybar/scripts/window-manager.sh minimized
        ;;
    "current-workspace")
        ~/.config/polybar/scripts/window-manager.sh current
        ;;
    "help"|*)
        echo "Window Management Launcher"
        echo "Usage: $0 [command] [options]"
        echo ""
        echo "Commands:"
        echo "  workspace-menu [num]  - Show window menu for workspace (current if no num)"
        echo "  all-windows          - Show all windows across all workspaces"
        echo "  minimized           - Show only minimized windows"
        echo "  current-workspace   - Show windows in current workspace"
        echo ""
        echo "Examples:"
        echo "  $0 workspace-menu 1    # Show windows in workspace 1"
        echo "  $0 all-windows         # Show all windows"
        echo "  $0 minimized          # Show minimized windows"
        ;;
esac
