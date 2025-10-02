#!/bin/bash
# VNC startup script with keyboard fixes for Android clients

# Kill any existing x11vnc instances
pkill x11vnc

# Apply keyboard mappings for better VNC compatibility
# This ensures Shift+Tab works properly
if command -v xmodmap &> /dev/null; then
    # Map Tab key to work with shift modifier
    xmodmap -e 'keycode 23 = Tab ISO_Left_Tab Tab ISO_Left_Tab' 2>/dev/null || true
    echo "Applied VNC keyboard mappings"
fi

# Start x11vnc with Android-friendly options
exec x11vnc -display :0 -rfbport 5901 -forever -loop -noxdamage -repeat -rfbauth ~/.vnc/passwd