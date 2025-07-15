#!/bin/bash

# Documentation Update Script
# Automatically updates documentation when dotfiles change

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory and repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Documentation files
README_FILE="$REPO_ROOT/README.md"
CONFIG_GUIDE="$REPO_ROOT/CONFIGURATION_GUIDE.md"
NIXOS_USAGE="$REPO_ROOT/NIXOS_USAGE.md"

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Function to check if documentation needs updating
needs_update() {
    local doc_file="$1"
    local config_dir="$2"
    
    if [[ ! -f "$doc_file" ]]; then
        return 0  # File doesn't exist, needs creation
    fi
    
    # Check if any config files are newer than documentation
    local newest_config
    newest_config=$(find "$config_dir" -type f -name "*.conf" -o -name "*.lua" -o -name "*.nix" -o -name "*.md" -o -name "*.sh" 2>/dev/null | xargs ls -t 2>/dev/null | head -1)
    
    if [[ -n "$newest_config" && "$newest_config" -nt "$doc_file" ]]; then
        return 0  # Config is newer, documentation needs update
    fi
    
    return 1  # Documentation is up to date
}

# Function to update file listing in documentation
update_file_listing() {
    local doc_file="$1"
    local start_marker="$2"
    local end_marker="$3"
    local directory="$4"
    
    log "Updating file listing in $doc_file"
    
    # Create temporary file with updated listing
    local temp_file
    temp_file=$(mktemp)
    
    # Copy everything before the start marker
    sed "/$start_marker/Q" "$doc_file" > "$temp_file"
    
    # Add the start marker
    echo "$start_marker" >> "$temp_file"
    
    # Generate new file listing
    if [[ -d "$directory" ]]; then
        echo '```' >> "$temp_file"
        (cd "$REPO_ROOT" && find "$directory" -type f | sort | sed 's/^/├── /') >> "$temp_file"
        echo '```' >> "$temp_file"
    else
        echo "Directory $directory not found" >> "$temp_file"
    fi
    
    # Add everything after the end marker
    sed -n "/$end_marker/,\$p" "$doc_file" >> "$temp_file"
    
    # Replace original file
    mv "$temp_file" "$doc_file"
}

# Function to validate documentation syntax
validate_docs() {
    log "Validating documentation syntax..."
    
    local errors=0
    
    # Check for basic markdown syntax
    for doc in "$README_FILE" "$CONFIG_GUIDE" "$NIXOS_USAGE"; do
        if [[ -f "$doc" ]]; then
            # Check for unmatched code blocks
            local backticks
            backticks=$(grep -c '```' "$doc" || true)
            if (( backticks % 2 != 0 )); then
                error "Unmatched code blocks in $(basename "$doc")"
                ((errors++))
            fi
            
            # Check for broken internal links
            while IFS= read -r line; do
                if [[ "$line" =~ \[.*\]\(#.*\) ]]; then
                    local anchor
                    anchor=$(echo "$line" | sed -n 's/.*\[.*\](#\([^)]*\)).*/\1/p')
                    if [[ -n "$anchor" ]] && ! grep -q "^#.*$anchor" "$doc"; then
                        warning "Potentially broken internal link: #$anchor in $(basename "$doc")"
                    fi
                fi
            done < "$doc"
        fi
    done
    
    if (( errors == 0 )); then
        success "Documentation validation passed"
    else
        error "Documentation validation failed with $errors errors"
        return 1
    fi
}

# Function to update README.md with current statistics
update_readme_stats() {
    log "Updating README.md statistics..."
    
    # Count configurations
    local total_configs
    total_configs=$(find "$REPO_ROOT/private_dot_config" -maxdepth 1 -type d 2>/dev/null | wc -l)
    
    # Count dotfiles
    local total_dotfiles
    total_dotfiles=$(find "$REPO_ROOT" -maxdepth 1 -name "dot_*" -o -name "private_dot_*" | wc -l)
    
    # Update statistics section if it exists
    if grep -q "## 📊 Statistics" "$README_FILE"; then
        sed -i "/## 📊 Statistics/,/## / {
            s/\*\*Total configurations\*\*:.*/\*\*Total configurations\*\*: $total_configs+ applications/
            s/\*\*Total dotfiles\*\*:.*/\*\*Total dotfiles\*\*: $total_dotfiles managed files/
            s/\*\*Last updated\*\*:.*/\*\*Last updated\*\*: $(date +'%Y-%m-%d')/
        }" "$README_FILE"
    fi
}

# Function to check for new configurations
check_new_configs() {
    log "Checking for new configurations..."
    
    # Find config directories not documented
    local new_configs=()
    
    if [[ -d "$REPO_ROOT/private_dot_config" ]]; then
        while IFS= read -r -d '' config_dir; do
            local config_name
            config_name=$(basename "$config_dir")
            
            # Check if mentioned in CONFIGURATION_GUIDE.md
            if ! grep -q "$config_name" "$CONFIG_GUIDE" 2>/dev/null; then
                new_configs+=("$config_name")
            fi
        done < <(find "$REPO_ROOT/private_dot_config" -maxdepth 1 -type d -print0)
    fi
    
    if [[ ${#new_configs[@]} -gt 0 ]]; then
        warning "Found undocumented configurations: ${new_configs[*]}"
        return 1
    else
        success "All configurations are documented"
    fi
}

# Function to backup documentation
backup_docs() {
    local backup_dir="$REPO_ROOT/.doc_backups"
    local timestamp
    timestamp=$(date +'%Y%m%d_%H%M%S')
    
    mkdir -p "$backup_dir"
    
    log "Creating documentation backup..."
    
    for doc in "$README_FILE" "$CONFIG_GUIDE" "$NIXOS_USAGE"; do
        if [[ -f "$doc" ]]; then
            cp "$doc" "$backup_dir/$(basename "$doc").backup_$timestamp"
        fi
    done
    
    # Keep only last 5 backups
    find "$backup_dir" -name "*.backup_*" -type f | sort | head -n -15 | xargs rm -f 2>/dev/null || true
}

# Function to update last modified timestamps
update_timestamps() {
    log "Updating documentation timestamps..."
    
    local current_date
    current_date=$(date +'%Y-%m-%d')
    
    for doc in "$README_FILE" "$CONFIG_GUIDE"; do
        if [[ -f "$doc" ]] && grep -q "Last updated:" "$doc"; then
            sed -i "s/Last updated:.*/Last updated: $current_date/" "$doc"
        fi
    done
}

# Main update function
main() {
    log "Starting documentation update process..."
    
    # Change to repository root
    cd "$REPO_ROOT"
    
    # Create backup before making changes
    backup_docs
    
    # Check if updates are needed
    local needs_readme_update=false
    local needs_config_update=false
    
    if needs_update "$README_FILE" "$REPO_ROOT"; then
        needs_readme_update=true
    fi
    
    if needs_update "$CONFIG_GUIDE" "$REPO_ROOT/private_dot_config"; then
        needs_config_update=true
    fi
    
    if [[ "$needs_readme_update" == false && "$needs_config_update" == false ]]; then
        success "Documentation is up to date"
        return 0
    fi
    
    # Perform updates
    if [[ "$needs_readme_update" == true ]]; then
        log "Updating README.md..."
        update_readme_stats
    fi
    
    # Check for new configurations
    check_new_configs || warning "Consider updating CONFIGURATION_GUIDE.md with new configurations"
    
    # Update timestamps
    update_timestamps
    
    # Validate updated documentation
    if ! validate_docs; then
        error "Documentation validation failed"
        return 1
    fi
    
    success "Documentation update completed successfully"
    
    # Show what was updated
    if [[ "$needs_readme_update" == true ]]; then
        echo "  ✓ README.md updated"
    fi
    if [[ "$needs_config_update" == true ]]; then
        echo "  ✓ Configuration guide updated"
    fi
    
    log "Documentation update process finished"
}

# Handle command line arguments
case "${1:-}" in
    --force)
        log "Force updating all documentation..."
        touch "$REPO_ROOT/private_dot_config"  # Force update
        main
        ;;
    --validate)
        log "Validating documentation only..."
        validate_docs
        ;;
    --check)
        log "Checking for new configurations..."
        check_new_configs
        ;;
    --help|-h)
        echo "Documentation Update Script"
        echo ""
        echo "Usage: $0 [OPTION]"
        echo ""
        echo "Options:"
        echo "  --force     Force update all documentation"
        echo "  --validate  Validate documentation syntax only"
        echo "  --check     Check for undocumented configurations"
        echo "  --help, -h  Show this help message"
        echo ""
        echo "When run without options, updates documentation only if needed."
        ;;
    "")
        main
        ;;
    *)
        error "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac