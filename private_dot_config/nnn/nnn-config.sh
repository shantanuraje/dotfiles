#!/bin/bash
# nnn Configuration for GUI-free workflow optimization
# Advanced file manager setup with plugins and enhanced functionality

# === Core nnn Environment Variables ===

# Plugin configuration - comprehensive set for GUI-free workflow with custom fzf plugins  
export NNN_PLUG='f:finder;p:preview-tui;d:fzdir;t:nmount;v:imgview;r:fzrg;c:fzcd;z:fzf;o:fzopen;w:preview-text;e:suedit;b:nbak;x:xdgdefault;m:mimelist;s:pass;k:kdeconnect;i:imgur;l:launch;n:nuke'

# FIFO for live preview
export NNN_FIFO=/tmp/nnn.fifo

# Kitty remote control for preview-tui plugin
export KITTY_LISTEN_ON=unix:@mykitty

# === Plugin Environment Configuration ===

# Configure finder plugin to use fzf
export NNN_FZFIND='fzf --height=50% --layout=reverse --border'

# Configure fzcd plugin for directory navigation with fzf
export NNN_FZCD='fzf --height=40% --layout=reverse --preview="ls -la {}" --bind="ctrl-o:execute(echo {} >/dev/tty)"'

# Configure fzopen plugin for file opening with fzf
export NNN_FZOPEN='fzf --height=50% --layout=reverse --preview="bat --color=always --style=numbers {}" --bind="ctrl-o:execute(echo {} >/dev/tty)"'

# Set fzf as the default finder for plugins
export FZF_DEFAULT_OPTS='--height=50% --layout=reverse --border --inline-info --color=16'

# Use fd for faster file finding if available
if command -v fd >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi

# Default opener - CLI-first with fallback
export NNN_OPENER="$HOME/.config/nnn/nnn-opener.sh"

# Bookmarks for quick navigation (press 'g' + key)
export NNN_BMS='h:~;d:~/Downloads;p:~/Projects;D:~/Documents;P:~/Pictures;V:~/Videos;c:~/.config;s:~/.local/share/chezmoi;n:~/system_nixos;w:/etc/nixos;A:~/AndroidStudioProjects'

# nnn behavior options
# c: auto-enter dir on selection
# d: detail mode (show file details)
# i: case-insensitive sort
# E: use $EDITOR to edit files
# r: navigate to last visited dir on start
# x: navigate to last dir on quit
export NNN_OPTS='cdiErx'

# Color scheme
export NNN_COLORS='2136'  # Custom color scheme
export NNN_FCOLORS='c1e2272e006033f7c6d6abc4'  # File type colors

# Archive file pattern for auto-detection
export NNN_ARCHIVE="\\.(7z|a|ace|alz|arc|arj|bz|bz2|cab|cpio|deb|gz|jar|lha|lz|lzh|lzma|lzo|rar|rpm|rz|t7z|tar|tbz|tbz2|tgz|tlz|txz|tZ|tzo|war|xpi|xz|Z|zip)$"

# === nnn Aliases ===

# Basic aliases
alias n='nnn'
alias nn='nnn -H'  # Show hidden files
alias ncd='nnn -c'  # Auto-enter directories

# Context-specific file managers
alias nedit='NNN_OPENER=nvim nnn'  # Open files with nvim
alias nimage='NNN_OPENER=feh nnn'  # Open images with feh
alias ncode='NNN_OPENER=code nnn'  # Open with VS Code

# === Advanced nnn Functions ===

# nnn with preview in terminal multiplexer
nnn_preview() {
    if command -v tmux >/dev/null && [ -n "$TMUX" ]; then
        # Split tmux window and run nnn with preview
        tmux split-window -h -p 50 "nnn -p"
    elif command -v zellij >/dev/null && [ -n "$ZELLIJ" ]; then
        # Create new zellij pane with nnn preview
        zellij action new-pane --direction right -- nnn -p
    else
        # Fallback to regular nnn
        nnn "$@"
    fi
}
alias np='nnn_preview'

# === Quick Bookmark Navigation ===

# Navigate to common directories with nnn
alias nh='cd ~ && nnn'
alias nd='cd ~/Downloads && nnn'
alias nproj='cd ~/Projects && nnn'
alias ndocs='cd ~/Documents && nnn'
alias npics='cd ~/Pictures && nnn'
alias nconfig='cd ~/.config && nnn'
alias nchezmoi='cd ~/.local/share/chezmoi && nnn'
alias nnixos='cd ~/system_nixos && nnn'
alias nandroid='cd ~/AndroidStudioProjects && nnn'

# === fzf Integration ===

# nnn with fuzzy directory selection
nf() {
    local dir
    dir=$(find . -type d -not -path '*/.*' | fzf --preview 'ls -la {}' --header 'Select directory for nnn')
    if [ -n "$dir" ]; then
        cd "$dir" && nnn
    fi
}

# nnn with fuzzy file search and preview
nff() {
    local file
    file=$(find . -type f -not -path '*/.*' | fzf --preview 'bat --color=always {}' --header 'Select file location for nnn')
    if [ -n "$file" ]; then
        cd "$(dirname "$file")" && nnn
    fi
}

# === Plugin Management ===

# Auto-install nnn plugins if not present
install_nnn_plugins() {
    if [ ! -d ~/.config/nnn/plugins ]; then
        echo "Installing nnn plugins..."
        mkdir -p ~/.config/nnn
        curl -Ls https://raw.githubusercontent.com/jarun/nnn/master/plugins/getplugs | sh
        echo "✅ nnn plugins installed to ~/.config/nnn/plugins"
        echo "Use ';' in nnn to access plugins"
    else
        echo "✅ nnn plugins already installed"
    fi
}

# Update nnn plugins
update_nnn_plugins() {
    if [ -d ~/.config/nnn/plugins ]; then
        echo "Updating nnn plugins..."
        cd ~/.config/nnn
        curl -Ls https://raw.githubusercontent.com/jarun/nnn/master/plugins/getplugs | sh
        echo "✅ nnn plugins updated"
    else
        install_nnn_plugins
    fi
}

# === Session Management ===

# Save current directory as nnn session
save_nnn_session() {
    local session_name="${1:-default}"
    local session_dir="$HOME/.config/nnn/sessions"
    local session_file="$session_dir/$session_name"
    
    mkdir -p "$session_dir"
    pwd > "$session_file"
    echo "💾 nnn session '$session_name' saved: $(pwd)"
}

# Load and start nnn from saved session
load_nnn_session() {
    local session_name="${1:-default}"
    local session_file="$HOME/.config/nnn/sessions/$session_name"
    
    if [ -f "$session_file" ]; then
        local saved_dir
        saved_dir=$(cat "$session_file")
        if [ -d "$saved_dir" ]; then
            cd "$saved_dir" && nnn
        else
            echo "❌ Saved directory no longer exists: $saved_dir"
        fi
    else
        echo "❌ Session not found: $session_name"
        echo "Available sessions:"
        ls ~/.config/nnn/sessions/ 2>/dev/null || echo "No sessions saved"
    fi
}

# List saved sessions
list_nnn_sessions() {
    local session_dir="$HOME/.config/nnn/sessions"
    if [ -d "$session_dir" ] && [ "$(ls -A "$session_dir" 2>/dev/null)" ]; then
        echo "📁 Saved nnn sessions:"
        for session in "$session_dir"/*; do
            if [ -f "$session" ]; then
                local name=$(basename "$session")
                local path=$(cat "$session")
                echo "  $name → $path"
            fi
        done
    else
        echo "No nnn sessions saved"
    fi
}

# Session aliases
alias nsave='save_nnn_session'
alias nload='load_nnn_session'
alias nlist='list_nnn_sessions'

# === Utility Functions ===

# Quick setup for new users
setup_nnn() {
    echo "🚀 Setting up nnn for GUI-free workflow..."
    install_nnn_plugins
    
    # Create common directories if they don't exist
    mkdir -p ~/Projects ~/Documents/nixos
    
    echo "📚 nnn setup complete!"
    echo ""
    echo "Quick start guide:"
    echo "  n         - Start nnn"
    echo "  np        - Start nnn with preview (in tmux/zellij)"
    echo "  nf        - Fuzzy directory selection + nnn"
    echo "  nh        - nnn in home directory"
    echo "  nd        - nnn in Downloads"
    echo "  nproj     - nnn in Projects"
    echo "  ;         - Access plugins in nnn"
    echo "  g + key   - Quick bookmarks (gh=home, gd=downloads, etc.)"
    echo ""
    echo "Bookmarks available: h(home) d(downloads) p(projects) c(config) s(chezmoi) n(nixos)"
}

# === Auto-initialization ===

# Plugins are managed by chezmoi run_onchange script
# Use 'chezmoi apply' to install/update plugins

# === Integration with Existing Tools ===

# Enhanced file operations with nnn + fzf + ripgrep
nrg() {
    local file
    file=$(rg --files | fzf --preview 'bat --color=always {}' --header 'Select file for nnn')
    if [ -n "$file" ]; then
        cd "$(dirname "$file")" && nnn
    fi
}

# nnn with git integration
ngit() {
    if git rev-parse --git-dir > /dev/null 2>&1; then
        local file
        file=$(git ls-files | fzf --preview 'bat --color=always {}' --header 'Select git file for nnn')
        if [ -n "$file" ]; then
            cd "$(dirname "$file")" && nnn
        fi
    else
        echo "❌ Not in a git repository"
    fi
}

# === Help Function ===

nnn_help() {
    cat << 'EOF'
🗂️  nnn - GUI-free File Manager Configuration

BASIC USAGE:
  n              Start nnn
  nn             Start nnn with hidden files
  np             Start nnn with preview pane

NAVIGATION:
  nh             nnn in home directory
  nd             nnn in Downloads  
  nproj          nnn in Projects
  nchezmoi       nnn in chezmoi config
  nnixos         nnn in NixOS config

FUZZY SEARCH:
  nf             Fuzzy directory selection + nnn
  nff            Fuzzy file search + nnn  
  nrg            Ripgrep file search + nnn
  ngit           Git file search + nnn

SESSION MANAGEMENT:
  nsave [name]   Save current directory as session
  nload [name]   Load saved session
  nlist          List all saved sessions

PLUGINS (press ; in nnn):
  z - fzf        Direct fzf file finder (like nff)
  d - fzdir      Direct fzf directory navigation (like nf)  
  r - fzrg       Content search with ripgrep (like nrg)
  w - preview-text  Enhanced text file preview (CSV, MD, logs)
  t - nmount     Mount/unmount devices
  f - finder     Advanced finder with options
  c - fzcd       Directory navigation with fzf
  o - fzopen     File opening with fzf + preview
  p - preview    Live preview pane
  v - imgview    Image viewer
  n - nuke       Batch operations

BOOKMARKS (press g + key in nnn):
  gh - home      gd - downloads    gp - projects
  gc - config    gs - chezmoi      gn - nixos

SETUP:
  setup_nnn      Complete setup guide
  install_nnn_plugins    Install/reinstall plugins
  update_nnn_plugins     Update plugins

For more help, see: https://github.com/jarun/nnn
EOF
}

alias nhelp='nnn_help'

# Export functions for use in subshells
export -f nnn_preview nf nff save_nnn_session load_nnn_session list_nnn_sessions
export -f install_nnn_plugins update_nnn_plugins setup_nnn nnn_help nrg ngit