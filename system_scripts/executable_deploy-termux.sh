#!/data/data/com.termux/files/usr/bin/bash

# Termux Deployment Script - Essential Tools Only
# Minimal setup for mobile environment

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

# Check Termux environment
check_termux() {
    if [ -z "$ANDROID_ROOT" ] || [ -z "$PREFIX" ]; then
        log_error "Must run in Termux!"
        exit 1
    fi
}

# Update repositories
update_repos() {
    log_info "Updating packages..."
    pkg update -y && pkg upgrade -y
    log_success "Packages updated"
}

# Install essential packages
install_essentials() {
    log_info "Installing essential tools..."

    local packages=(
        # Core essentials
        "git"
        "neovim"
        "curl"
        "wget"
        "openssh"

        # Modern CLI tools (worth it even on mobile)
        "bat"           # better cat
        "eza"           # better ls
        "fd"            # better find
        "ripgrep"       # better grep
        "fzf"           # fuzzy finder
        "git-delta"     # better git diff

        # File management
        "nnn"           # lightweight file manager
        "tree"

        # Utilities
        "jq"            # JSON processor
        "htop"          # system monitor
        "neofetch"      # system info
        "tmux"          # terminal multiplexer

        # Basic dev tools
        "python"
        "nodejs"
        "clang"
        "make"

        # Archive support
        "zip"
        "unzip"
        "tar"
    )

    for pkg in "${packages[@]}"; do
        if pkg install -y "$pkg" 2>/dev/null; then
            log_success "$pkg"
        else
            log_warning "$pkg failed (may not be available)"
        fi
    done
}

# Install minimal Python packages
install_python_essentials() {
    log_info "Checking Python package installation..."

    if ! command -v pip >/dev/null 2>&1; then
        log_warning "pip not available, skipping Python packages"
        return
    fi

    # Try to upgrade pip, but don't fail if it's forbidden
    if pip install --upgrade pip 2>/dev/null; then
        log_success "pip upgraded"
    else
        log_warning "pip upgrade failed (may be restricted in Termux)"
        log_info "Continuing without Python packages..."
        return
    fi

    local py_packages=(
        "pynvim"        # neovim support
        "requests"      # HTTP library
        "tldr"          # simplified man pages
    )

    for pkg in "${py_packages[@]}"; do
        if pip install "$pkg" 2>/dev/null; then
            log_success "Python: $pkg"
        else
            log_warning "Python: $pkg failed"
        fi
    done
}

# Setup Termux storage
setup_storage() {
    if [ ! -d "$HOME/storage" ]; then
        log_info "Setting up storage access..."
        termux-setup-storage
        log_info "Grant storage permission when prompted"
    fi
}

# Install nnn plugins
install_nnn_plugins() {
    if command -v nnn >/dev/null 2>&1; then
        local plugin_script="$HOME/.local/share/chezmoi/run_onchange_executable_install-nnn-plugins.sh"
        if [ -f "$plugin_script" ]; then
            log_info "Installing nnn plugins..."
            bash "$plugin_script" || log_warning "nnn plugins script failed"
        fi
    fi
}

# Apply dotfiles
apply_dotfiles() {
    log_info "Applying dotfiles..."

    if ! command -v chezmoi >/dev/null 2>&1; then
        log_error "chezmoi not found!"
        exit 1
    fi

    if [ ! -d "$HOME/.local/share/chezmoi/.git" ]; then
        log_error "chezmoi not initialized! Run: chezmoi init shantanuraje"
        exit 1
    fi

    chezmoi apply && log_success "Dotfiles applied"
}

# Summary
show_summary() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_success "Termux setup complete!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Installed essentials:"
    echo "  • Core: git, neovim, openssh"
    echo "  • Modern CLI: bat, eza, fd, ripgrep, fzf, delta"
    echo "  • File manager: nnn"
    echo "  • Dev: python, nodejs"
    echo ""
    echo "Next steps:"
    echo "  1. Restart terminal: exit and reopen"
    echo "  2. Or reload: source ~/.bashrc"
    echo "  3. Configure git:"
    echo "     git config --global user.name 'Your Name'"
    echo "     git config --global user.email 'you@example.com'"
    echo ""
    echo "Quick commands:"
    echo "  • File manager: n or nnn"
    echo "  • Editor: nvim"
    echo "  • System info: neofetch"
    echo "  • Aliases: alias"
    echo "  • Dotfiles: chezmoi"
    echo ""
}

# Main
main() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Termux Deployment - Essential Tools Only"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    check_termux
    update_repos
    install_essentials
    install_python_essentials
    setup_storage
    install_nnn_plugins
    apply_dotfiles
    show_summary
}

main "$@"
