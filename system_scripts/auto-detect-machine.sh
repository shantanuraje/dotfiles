#!/bin/bash
# Auto-detect machine configuration script
# Intelligently suggests the best machine configuration based on hardware

set -euo pipefail

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${BLUE}[AUTO-DETECT]${NC} $1"; }
success() { echo -e "${GREEN}[AUTO-DETECT]${NC} $1"; }
warning() { echo -e "${YELLOW}[AUTO-DETECT]${NC} $1"; }

# Get hardware information
get_hardware_info() {
    local host_info=""
    local cpu_info=""
    
    # Try neofetch first (most reliable)
    if command -v neofetch >/dev/null 2>&1; then
        host_info=$(neofetch --stdout 2>/dev/null | grep "Host:" | cut -d':' -f2- | xargs)
        cpu_info=$(neofetch --stdout 2>/dev/null | grep "CPU:" | cut -d':' -f2- | xargs)
    fi
    
    # Fallback methods
    if [[ -z "$host_info" ]]; then
        host_info=$(hostnamectl 2>/dev/null | grep "Hardware Model" | cut -d':' -f2- | xargs || echo "Unknown")
    fi
    
    if [[ -z "$cpu_info" ]]; then
        cpu_info=$(grep "model name" /proc/cpuinfo | head -1 | cut -d':' -f2- | xargs || echo "Unknown")
    fi
    
    echo "HOST:$host_info"
    echo "CPU:$cpu_info"
}

# Detect machine type based on hardware
detect_machine_config() {
    local hardware_info=$(get_hardware_info)
    local host_line=$(echo "$hardware_info" | grep "HOST:")
    local cpu_line=$(echo "$hardware_info" | grep "CPU:")
    
    log "Hardware Detection:"
    echo "  $host_line"
    echo "  $cpu_line"
    echo
    
    # Samsung Galaxy Book detection
    if echo "$host_line" | grep -q "SAMSUNG.*NP930QCG"; then
        success "Detected: Samsung Galaxy Book NP930QCG-K01US"
        echo "  → Recommended: personal/laptop-samsung (with audio fix)"
        echo "  → Hardware module: samsung-galaxy-book-audio.nix"
        return 0
    fi
    
    # Add more hardware detection patterns here
    if echo "$cpu_line" | grep -qi "intel.*i7"; then
        warning "Detected: Intel i7 system (generic)"
        echo "  → Consider: personal/desktop-main or work/workstation"
        return 1
    fi
    
    warning "Unknown hardware configuration"
    echo "  → Fallback: Check all available configurations manually"
    return 2
}

# Main function
main() {
    log "Starting automatic machine detection..."
    echo
    
    detect_machine_config
    local result=$?
    
    echo
    case $result in
        0) success "Specific hardware configuration detected and recommended" ;;
        1) warning "Generic hardware detected - manual selection recommended" ;;
        2) warning "Unknown hardware - manual configuration required" ;;
    esac
    
    return $result
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi