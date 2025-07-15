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

log "=== NixOS Configuration Test Deployment ==="
log "Source: $SOURCE_DIR"
log "Target: /etc/nixos"
log ""

log "Files that would be deployed:"
for file in "$SOURCE_DIR"/*; do
    if [[ -f "$file" ]]; then
        filename=$(basename "$file")
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
done

log ""
log "=== Validation Test ==="
log "Would run: sudo nixos-rebuild dry-build"

log ""
success "Test completed! No changes made to system."
success "To actually deploy, run: bash ~/.local/share/chezmoi/scripts/deploy-nixos.sh"