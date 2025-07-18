#!/bin/bash
# NixOS Deployment Script
# Deploys modular NixOS configurations from chezmoi to /etc/nixos/
# 
# Structure:
#   machines/personal/   - Personal machine configs (laptop-samsung.nix)
#   machines/work/       - Work machine configs (desktop-hp.nix)  
#   machines/shared/     - Common modules (system-common.nix, hardware modules)
#
# When deployed:
#   - Selected machine config becomes /etc/nixos/configuration.nix
#   - All machines/ directory copied to /etc/nixos/machines/
#   - Imports resolve as: ./machines/shared/system-common.nix

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

# Machine selection with new hierarchical structure
MACHINES_DIR="$SOURCE_DIR/machines"
if [[ ! -d "$MACHINES_DIR" ]]; then
    error "Machines directory $MACHINES_DIR not found!"
    exit 1
fi

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

# Note: shared/ directory contains modules, not deployable machines

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
selected_config="${machine_paths[$((choice-1))]}"

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

# Validate the copied configuration has correct syntax
log "Validating configuration syntax..."
if ! sudo nix-instantiate --parse "/etc/nixos/configuration.nix" > /dev/null 2>&1; then
    error "Configuration syntax validation failed!"
    sudo cp "$BACKUP_DIR/configuration.nix" "/etc/nixos/configuration.nix" 2>/dev/null || true
    exit 1
fi
success "Configuration syntax validated successfully"

# Copy other essential files (excluding configuration.nix and hardware-configuration.nix)
log "Copying shared configuration files..."
for file in "$SOURCE_DIR"/*; do
    if [[ -f "$file" ]]; then
        filename=$(basename "$file")
        # Skip configuration.nix (we already copied the selected machine config)
        # Skip hardware-configuration.nix (system-specific, should not be overwritten)
        if [[ "$filename" != "configuration.nix" && "$filename" != "hardware-configuration.nix" ]]; then
            log "  → $filename"
            sudo cp "$file" "/etc/nixos/$filename"
            sudo chown root:root "/etc/nixos/$filename"
            sudo chmod 644 "/etc/nixos/$filename"
        fi
    fi
done

# Copy machines directory structure (for imports like shared/hardware modules)
if [[ -d "$SOURCE_DIR/machines" ]]; then
    log "Copying machines directory structure..."
    # Clean up old machines directory to avoid stale files
    sudo rm -rf "/etc/nixos/machines"
    sudo cp -r "$SOURCE_DIR/machines" "/etc/nixos/"
    sudo chown -R root:root "/etc/nixos/machines"
    sudo find "/etc/nixos/machines" -type f -exec chmod 644 {} \;
    sudo find "/etc/nixos/machines" -type d -exec chmod 755 {} \;
    success "Machines directory structure updated"
fi

# Check if flake.lock exists and offer to regenerate
if [[ -f "$SOURCE_DIR/flake.lock" ]]; then
    warning "Found existing flake.lock from another system"
    echo "This may cause hash mismatches. Consider regenerating."
    read -p "Regenerate flake.lock? (y/N): " regen_lock
    if [[ "$regen_lock" =~ ^[Yy]$ ]]; then
        log "Removing old flake.lock and regenerating..."
        cd "$SOURCE_DIR"
        rm -f flake.lock
        nix flake lock
        cd - > /dev/null
        success "Flake lock regenerated"
    fi
fi

# Check for gemini-cli hash script and offer to update hashes
if [[ -f "$SOURCE_DIR/packages/gemini-cli/get-gemini-hashes.sh" ]]; then
    warning "Gemini CLI package detected"
    echo "Consider updating hashes to ensure successful build."
    read -p "Update gemini-cli hashes? (y/N): " update_hashes
    if [[ "$update_hashes" =~ ^[Yy]$ ]]; then
        log "Updating gemini-cli hashes..."
        cd "$SOURCE_DIR"
        if bash packages/gemini-cli/get-gemini-hashes.sh; then
            success "Gemini CLI hashes updated"
            warning "Note: You may need to manually update npmDepsHash in gemini-cli.nix"
        else
            warning "Hash update failed, continuing with existing hashes..."
        fi
        cd - > /dev/null
    fi
fi

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