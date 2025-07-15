#!/bin/bash

# Dynamic System Information Detection Script
# Generates current system profile for Claude context

set -euo pipefail

# Colors for output formatting
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== NixOS System Profile ===${NC}"
echo

# Hardware & Environment
echo -e "${GREEN}🖥️ Hardware & Environment${NC}"
echo "- **Hostname**: $(hostname)"
echo "- **Architecture**: $(uname -m)"
echo "- **NixOS Version**: $(nixos-version | cut -d' ' -f1) ($(nixos-version | cut -d'(' -f2 | tr -d ')'))"

# Get timezone
TIMEZONE=$(timedatectl | grep "Time zone" | awk '{print $3}')
echo "- **Timezone**: $TIMEZONE"

# Get locale
LOCALE=$(locale | grep LC_TIME | cut -d'=' -f2)
echo "- **Locale**: $LOCALE"

# User info
USERNAME=$(whoami)
USER_GROUPS=$(groups | tr ' ' ', ')
echo "- **User**: $USERNAME (groups: $USER_GROUPS)"
echo

# Desktop Environment Detection
echo -e "${GREEN}🎨 Desktop Environment Stack${NC}"

# Check for active desktop sessions
if pgrep -x "Hyprland" > /dev/null; then
    echo "- **Primary**: Hyprland (Wayland compositor) - ✅ Currently Active"
else
    echo "- **Primary**: Hyprland (Wayland compositor) - Available"
fi

if pgrep -x "awesome" > /dev/null; then
    echo "- **Secondary**: AwesomeWM (X11 window manager) - ✅ Currently Active"
else
    echo "- **Secondary**: AwesomeWM (X11 window manager) - Available"
fi

if pgrep -x "gnome-shell" > /dev/null; then
    echo "- **Fallback**: GNOME Desktop Environment - ✅ Currently Active"
else
    echo "- **Fallback**: GNOME Desktop Environment - Available"
fi

# Check display manager
if systemctl is-active --quiet gdm; then
    echo "- **Display Manager**: GDM (GNOME Display Manager) - ✅ Active"
else
    echo "- **Display Manager**: GDM (GNOME Display Manager) - Available"
fi

# Check for Waybar
if pgrep -x "waybar" > /dev/null; then
    echo "- **Status Bar**: Waybar (Hyprland) - ✅ Running"
else
    echo "- **Status Bar**: Waybar (Hyprland) - Available"
fi
echo

# System Services Status
echo -e "${GREEN}🔧 System Services & Features${NC}"

# Audio system
if systemctl --user is-active --quiet pipewire; then
    echo "- **Audio**: PipeWire - ✅ Active"
elif systemctl --user is-active --quiet pulseaudio; then
    echo "- **Audio**: PulseAudio - ✅ Active"
else
    echo "- **Audio**: PipeWire (configured)"
fi

# Network
if systemctl is-active --quiet NetworkManager; then
    echo "- **Networking**: NetworkManager - ✅ Active"
else
    echo "- **Networking**: NetworkManager - Available"
fi

# Check CUPS
if systemctl is-active --quiet cups; then
    echo "- **Printing**: CUPS - ✅ Active"
else
    echo "- **Printing**: CUPS - Available"
fi

# Check ADB
if command -v adb > /dev/null; then
    echo "- **Android**: ADB support - ✅ Available"
fi
echo

# Installed Key Applications
echo -e "${GREEN}📦 Key Applications Status${NC}"

# Check browsers
if command -v firefox > /dev/null; then
    echo "- **Browser**: Firefox - ✅ Installed"
fi
if command -v google-chrome-stable > /dev/null; then
    echo "- **Browser**: Google Chrome - ✅ Installed"
fi

# Development tools
if command -v nvim > /dev/null; then
    echo "- **Editor**: Neovim - ✅ Installed"
fi
if command -v code > /dev/null; then
    echo "- **IDE**: VS Code - ✅ Installed"
fi
if command -v kitty > /dev/null; then
    echo "- **Terminal**: Kitty - ✅ Installed"
fi

# AI Tools
if command -v claude-code > /dev/null; then
    echo "- **AI**: Claude Code - ✅ Installed"
fi
if command -v gemini > /dev/null; then
    echo "- **AI**: Gemini CLI - ✅ Installed"
fi

# Communication
if command -v discord > /dev/null; then
    echo "- **Communication**: Discord - ✅ Installed"
fi

# Productivity
if command -v obsidian > /dev/null; then
    echo "- **Productivity**: Obsidian - ✅ Installed"
fi
echo

# Resource Information
echo -e "${GREEN}💾 System Resources${NC}"

# Memory
TOTAL_MEM=$(free -h | awk '/^Mem:/ {print $2}')
USED_MEM=$(free -h | awk '/^Mem:/ {print $3}')
echo "- **Memory**: $USED_MEM / $TOTAL_MEM used"

# Disk space for root
ROOT_DISK=$(df -h / | awk 'NR==2 {print $3 "/" $2 " used (" $5 ")"}')
echo "- **Root Disk**: $ROOT_DISK"

# Load average
LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | xargs)
echo "- **Load Average**: $LOAD_AVG"
echo

# Current Session Info
echo -e "${GREEN}🖱️ Current Session${NC}"
echo "- **Session Type**: ${XDG_SESSION_TYPE:-Unknown}"
echo "- **Desktop**: ${XDG_CURRENT_DESKTOP:-Unknown}"
if [ -n "${WAYLAND_DISPLAY:-}" ]; then
    echo "- **Wayland Display**: $WAYLAND_DISPLAY"
fi
if [ -n "${DISPLAY:-}" ]; then
    echo "- **X11 Display**: $DISPLAY"
fi
echo

# Package counts
echo -e "${GREEN}📊 Package Information${NC}"
USER_PACKAGES=$(nix-env -q | wc -l 2>/dev/null || echo "0")
echo "- **User Packages**: $USER_PACKAGES installed"

# Generation info (only if we can access it without password)
if CURRENT_GEN=$(nix-env --list-generations -p /nix/var/nix/profiles/system 2>/dev/null | tail -1 | awk '{print $1}'); then
    echo "- **Current Generation**: #$CURRENT_GEN"
else
    echo "- **Current Generation**: Available (requires admin access)"
fi
echo

echo -e "${YELLOW}Last updated: $(date)${NC}"
echo -e "${BLUE}=============================${NC}"