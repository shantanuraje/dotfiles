#!/usr/bin/env bash

# System updates checker for polybar
# Checks for available package updates

get_updates() {
    # For NixOS, check if rebuild would change anything
    if command -v nixos-rebuild >/dev/null 2>&1; then
        # Check if there are any flake updates available
        cd /etc/nixos
        if [ -f flake.lock ]; then
            # Count outdated inputs (simplified check)
            updates=$(nix flake update --dry-run 2>&1 | grep -c "Updated" || echo "0")
        else
            updates="0"
        fi
    else
        updates="0"
    fi
    
    if [ "$updates" -gt 0 ]; then
        echo "%{F#f5a97f} $updates%{F-}"
    else
        echo ""
    fi
}

case "$1" in
    --update)
        # Trigger update (could open terminal with update command)
        kitty -e bash -c "echo 'Run: sudo nixos-rebuild switch --flake /etc/nixos'; bash"
        ;;
    *)
        get_updates
        ;;
esac
