#!/usr/bin/env bash
# Install nnn plugins automatically when nnn config changes

set -e

echo "🔧 Installing nnn plugins..."

# Create plugins directory if it doesn't exist  
mkdir -p "$HOME/.config/nnn/plugins"

# Download official nnn plugins using the official installer
if command -v curl >/dev/null 2>&1; then
    cd "$HOME/.config/nnn"
    curl -Ls https://raw.githubusercontent.com/jarun/nnn/master/plugins/getplugs | bash
    
    # Make sure all plugins are executable
    find "$HOME/.config/nnn/plugins" -type f -exec chmod +x {} \;
    
    echo "✅ nnn plugins installed successfully!"
    echo "   Use ';' in nnn to access plugins"
    echo "   Key plugins: f (finder), c (fzcd), o (fzopen), p (preview)"
else
    echo "❌ curl not found - cannot install nnn plugins"
    exit 1
fi