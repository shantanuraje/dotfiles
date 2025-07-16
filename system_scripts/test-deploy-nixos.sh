#!/bin/bash
# Test NixOS deployment script (dry-run mode)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[TEST-DEPLOY]${NC} $1"; }
success() { echo -e "${GREEN}[TEST-DEPLOY]${NC} $1"; }
warning() { echo -e "${YELLOW}[TEST-DEPLOY]${NC} $1"; }
error() { echo -e "${RED}[TEST-DEPLOY]${NC} $1"; }

# Check if we're on NixOS
if [[ ! -f /etc/nixos/configuration.nix ]]; then
    error "Not running on NixOS!"
    exit 1
fi

SOURCE_DIR="$(dirname "$0")/../system_nixos"
if [[ ! -d "$SOURCE_DIR" ]]; then
    error "Source directory $SOURCE_DIR not found!"
    exit 1
fi

# Machine selection (test mode)
MACHINES_DIR="$SOURCE_DIR/machines"
if [[ ! -d "$MACHINES_DIR" ]]; then
    error "Machines directory $MACHINES_DIR not found!"
    exit 1
fi

log "=== NixOS Configuration Test Deployment ==="
log "Source: $SOURCE_DIR"
log "Target: /etc/nixos"
log ""

log "Available machine configurations:"
machines=()
machine_paths=()

# Scan personal machines
if [[ -d "$MACHINES_DIR/personal" ]]; then
    for machine_file in "$MACHINES_DIR/personal"/*.nix; do
        if [[ -f "$machine_file" ]]; then
            machine_name="personal/$(basename "$machine_file" .nix)"
            machines+=("$machine_name")
            machine_paths+=("$machine_file")
            echo "  [$((${#machines[@]})))] $machine_name"
        fi
    done
fi

# Scan work machines  
if [[ -d "$MACHINES_DIR/work" ]]; then
    for machine_file in "$MACHINES_DIR/work"/*.nix; do
        if [[ -f "$machine_file" ]]; then
            machine_name="work/$(basename "$machine_file" .nix)"
            machines+=("$machine_name")
            machine_paths+=("$machine_file")
            echo "  [$((${#machines[@]})))] $machine_name"
        fi
    done
fi

if [[ ${#machines[@]} -eq 0 ]]; then
    error "No machine configurations found in $MACHINES_DIR"
    exit 1
fi

echo
read -p "Select machine configuration to test (1-${#machines[@]}): " choice

if [[ ! "$choice" =~ ^[0-9]+$ ]] || [[ $choice -lt 1 ]] || [[ $choice -gt ${#machines[@]} ]]; then
    error "Invalid selection!"
    exit 1
fi

selected_machine="${machines[$((choice-1))]}"
selected_config="${machine_paths[$((choice-1))]}"

log "Testing deployment of: $selected_machine"
log "Config file: $selected_config"
log ""

# Show what would happen to configuration.nix
log "configuration.nix would be replaced with $selected_machine config:"
if [[ -f "/etc/nixos/configuration.nix" ]]; then
    echo -e "${YELLOW}    Differences from current configuration.nix:${NC}"
    diff -u "/etc/nixos/configuration.nix" "$selected_config" | head -20 || true
    echo ""
else
    echo -e "${GREEN}    New configuration.nix file${NC}"
fi

log "Other files that would be deployed:"
for file in "$SOURCE_DIR"/*; do
    if [[ -f "$file" ]]; then
        filename=$(basename "$file")
        # Skip configuration.nix as we handle it separately, skip hardware-configuration.nix
        if [[ "$filename" != "configuration.nix" && "$filename" != "hardware-configuration.nix" ]]; then
            log "  → $filename"
            
            # Show diff if file exists
            if [[ -f "/etc/nixos/$filename" ]]; then
                echo -e "${YELLOW}    Differences:${NC}"
                diff -u "/etc/nixos/$filename" "$file" | head -10 || true
                echo ""
            else
                echo -e "${GREEN}    New file${NC}"
            fi
        fi
    fi
done

# Show machines directory structure that would be deployed
if [[ -d "$SOURCE_DIR/machines" ]]; then
    log "Machines directory structure that would be deployed:"
    if [[ -d "/etc/nixos/machines" ]]; then
        log "  → machines/ (would be updated)"
        echo -e "${YELLOW}    Directory structure comparison:${NC}"
        diff -r "/etc/nixos/machines" "$SOURCE_DIR/machines" | head -10 || true
        echo ""
    else
        log "  → machines/ (new directory)"
        echo -e "${GREEN}    New directory with structure:${NC}"
        find "$SOURCE_DIR/machines" -name "*.nix" | sed 's|.*/|    |'
    fi
fi

log ""
log "=== Validation Test ==="
log "Would run: sudo nixos-rebuild dry-build"

log ""
success "Test completed! No changes made to system."
success "To actually deploy, run: bash ~/.local/share/chezmoi/scripts/deploy-nixos.sh"