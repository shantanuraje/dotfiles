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
#
# Logging:
#   - Every run produces a timestamped log file under
#     ~/.local/state/nixos-deploy/<timestamp>-<machine>.log
#   - Symlink ~/.local/state/nixos-deploy/latest.log always points at the
#     most recent run's log
#   - Full stdout/stderr (including nixos-rebuild output) is captured to the
#     log via tee, while the user still sees colored output on the terminal
#   - The log path is included in the success/failure ntfy notification body
#   - Log files are kept for 30 days; older runs are auto-pruned at start

set -euo pipefail

# ── Logging setup (must run before anything noisy) ────────────────────────────
TS="$(date +%Y%m%d-%H%M%S)"
LOG_DIR="${HOME}/.local/state/nixos-deploy"
mkdir -p "$LOG_DIR"

# Prune logs older than 30 days
find "$LOG_DIR" -maxdepth 1 -name '*.log' -type f -mtime +30 -delete 2>/dev/null || true

# Tee all output to a log file. The actual machine name is unknown until the
# user picks one, so the log starts with a generic name and gets renamed
# after selection.
LOG_FILE="${LOG_DIR}/${TS}-pending.log"
ln -sfn "$LOG_FILE" "${LOG_DIR}/latest.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()      { echo -e "$(date '+%H:%M:%S') ${BLUE}[NIXOS-DEPLOY]${NC} $1"; }
success()  { echo -e "$(date '+%H:%M:%S') ${GREEN}[NIXOS-DEPLOY]${NC} $1"; }
warning()  { echo -e "$(date '+%H:%M:%S') ${YELLOW}[NIXOS-DEPLOY]${NC} $1"; }
error()    { echo -e "$(date '+%H:%M:%S') ${RED}[NIXOS-DEPLOY]${NC} $1"; }

log "Deploy started — log file: $LOG_FILE"
log "User: $(whoami)  Host: $(hostname)  PWD: $PWD"

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

# Rename log file to include the chosen machine for easier retrieval
SAFE_MACHINE="${selected_machine//\//-}"
NEW_LOG_FILE="${LOG_DIR}/${TS}-${SAFE_MACHINE}.log"
mv "$LOG_FILE" "$NEW_LOG_FILE"
LOG_FILE="$NEW_LOG_FILE"
ln -sfn "$LOG_FILE" "${LOG_DIR}/latest.log"
log "Log file renamed: $LOG_FILE"

# Step 1: Optionally regenerate flake.lock in chezmoi source BEFORE copying
if [[ -f "$SOURCE_DIR/flake.nix" ]]; then
    read -p "Update flake inputs (nix flake update)? (y/N): " regen_lock
    if [[ "$regen_lock" =~ ^[Yy]$ ]]; then
        log "Updating flake inputs in chezmoi source..."
        cd "$SOURCE_DIR"
        nix flake update
        cd - > /dev/null
        success "Flake inputs updated"
    fi
fi

# Step 2: Create backup of current /etc/nixos/
BACKUP_DIR="/tmp/nixos-backup-$(date +%Y%m%d-%H%M%S)"
log "Creating backup at $BACKUP_DIR"
sudo mkdir -p "$BACKUP_DIR"
sudo cp -r /etc/nixos/* "$BACKUP_DIR/" 2>/dev/null || true

# Step 3: Copy selected machine configuration as configuration.nix
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

# Step 4: Copy other essential files (excluding configuration.nix and hardware-configuration.nix)
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

# Step 5: Copy machines directory structure (for imports like shared/hardware modules)
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

# Step 6: Rebuild NixOS system
log "Rebuilding NixOS system..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOTIFY_DEPLOY="${SCRIPT_DIR}/notify/send-deploy.sh"

# Source webhook env so action buttons can be embedded in the deploy notification
[[ -f "${HOME}/.config/notify/webhook-env" ]] && set -a && source "${HOME}/.config/notify/webhook-env" && set +a

deploy_start=$SECONDS
if sudo nixos-rebuild switch; then
    elapsed=$((SECONDS - deploy_start))
    duration="$((elapsed / 60))m$((elapsed % 60))s"
    success "NixOS system successfully rebuilt in $duration"
    success "Backup available at: $BACKUP_DIR"
    success "Full deploy log: $LOG_FILE"
    success "    (also at:    ${LOG_DIR}/latest.log)"
    [[ -x "$NOTIFY_DEPLOY" ]] && "$NOTIFY_DEPLOY" ok "$duration" || true
else
    elapsed=$((SECONDS - deploy_start))
    duration="$((elapsed / 60))m$((elapsed % 60))s"
    error "Rebuild failed after $duration! /etc/nixos left as-is for inspection."
    error "Backup of previous /etc/nixos at: $BACKUP_DIR"
    error "System is still running the previous generation (boot loader untouched)."
    error "To restore old files: sudo cp -r $BACKUP_DIR/* /etc/nixos/"
    error "Full deploy log: $LOG_FILE"
    [[ -x "$NOTIFY_DEPLOY" ]] && "$NOTIFY_DEPLOY" fail "$duration" || true
    exit 1
fi
