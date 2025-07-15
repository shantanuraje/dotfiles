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

log "NixOS Configuration Deployment"
log "Source: $SOURCE_DIR"
log "Target: /etc/nixos"

# Create backup
BACKUP_DIR="/tmp/nixos-backup-$(date +%Y%m%d-%H%M%S)"
log "Creating backup at $BACKUP_DIR"
sudo mkdir -p "$BACKUP_DIR"
sudo cp -r /etc/nixos/* "$BACKUP_DIR/" 2>/dev/null || true

# Copy files
log "Copying configuration files..."
for file in "$SOURCE_DIR"/*; do
    if [[ -f "$file" ]]; then
        filename=$(basename "$file")
        log "  → $filename"
        sudo cp "$file" "/etc/nixos/$filename"
        sudo chown root:root "/etc/nixos/$filename"
        sudo chmod 644 "/etc/nixos/$filename"
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