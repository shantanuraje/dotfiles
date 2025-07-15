#!/bin/bash
# Manual NixOS deployment script
# Run this script to deploy NixOS configurations from chezmoi

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[NIXOS-DEPLOY]${NC} $1"; }
success() { echo -e "${GREEN}[NIXOS-DEPLOY]${NC} $1"; }
warning() { echo -e "${YELLOW}[NIXOS-DEPLOY]${NC} $1"; }
error() { echo -e "${RED}[NIXOS-DEPLOY]${NC} $1"; }

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

# Machine selection
MACHINES_DIR="$SOURCE_DIR/machines"
if [[ ! -d "$MACHINES_DIR" ]]; then
    error "Machines directory $MACHINES_DIR not found!"
    exit 1
fi

log "Available machine configurations:"
machines=()
for machine_file in "$MACHINES_DIR"/*.nix; do
    if [[ -f "$machine_file" ]]; then
        machine_name=$(basename "$machine_file" .nix)
        machines+=("$machine_name")
        echo "  [$((${#machines[@]})))] $machine_name"
    fi
done

if [[ ${#machines[@]} -eq 0 ]]; then
    error "No machine configurations found in $MACHINES_DIR"
    exit 1
fi

echo
read -p "Select machine configuration (1-${#machines[@]}): " choice

if [[ ! "$choice" =~ ^[0-9]+$ ]] || [[ $choice -lt 1 ]] || [[ $choice -gt ${#machines[@]} ]]; then
    error "Invalid selection!"
    exit 1
fi

selected_machine="${machines[$((choice-1))]}"
selected_config="$MACHINES_DIR/${selected_machine}.nix"

log "Selected: $selected_machine"
log "Config: $selected_config"

# Create backup
BACKUP_DIR="/tmp/nixos-backup-$(date +%Y%m%d-%H%M%S)"
log "Creating backup at $BACKUP_DIR"
sudo mkdir -p "$BACKUP_DIR"
sudo cp -r /etc/nixos/* "$BACKUP_DIR/" 2>/dev/null || true

# Copy selected machine configuration as configuration.nix
log "Copying $selected_machine configuration as configuration.nix..."
sudo cp "$selected_config" "/etc/nixos/configuration.nix"
sudo chown root:root "/etc/nixos/configuration.nix"
sudo chmod 644 "/etc/nixos/configuration.nix"

# Copy other essential files (excluding machine configs and old configuration.nix)
log "Copying shared configuration files..."
for file in "$SOURCE_DIR"/*; do
    if [[ -f "$file" ]]; then
        filename=$(basename "$file")
        # Skip configuration.nix (we already copied the selected machine config)
        # and machines directory
        if [[ "$filename" != "configuration.nix" ]]; then
            log "  → $filename"
            sudo cp "$file" "/etc/nixos/$filename"
            sudo chown root:root "/etc/nixos/$filename"
            sudo chmod 644 "/etc/nixos/$filename"
        fi
    fi
done

# # Validate
# log "Validating configuration..."
# if ! sudo nixos-rebuild dry-build 2>/dev/null; then
#     error "Configuration validation failed! Restoring backup..."
#     sudo cp "$BACKUP_DIR"/* /etc/nixos/
#     exit 1
# fi

# # Apply
# log "Rebuilding NixOS system..."
# if sudo nixos-rebuild switch; then
#     success "NixOS system successfully rebuilt!"
#     success "Backup: $BACKUP_DIR"
# else
#     error "Rebuild failed! Restoring backup..."
#     sudo cp "$BACKUP_DIR"/* /etc/nixos/
#     exit 1
# fi