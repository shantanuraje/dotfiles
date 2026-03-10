#!/usr/bin/env bash

# Clipboard History - rofi script mode
# Requires: greenclip daemon running
# Add to unified palette: rofi -modi "clip:clipboard-mode.sh" -show clip

if [ -z "$1" ]; then
    echo -en "\0prompt\x1fClipboard\n"
    greenclip print 2>/dev/null
else
    echo -n "$1" | xclip -selection clipboard
    greenclip clear "$1" 2>/dev/null
fi
