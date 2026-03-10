#!/usr/bin/env bash

# File Search - rofi script mode
# Fuzzy find files and open with xdg-open
# Add to unified palette: rofi -modi "files:file-search-mode.sh" -show files

SEARCH_DIRS="$HOME/Documents $HOME/Projects $HOME/Downloads $HOME/Pictures"

if [ -z "$1" ]; then
    echo -en "\0prompt\x1fFiles\n"
    fd --type f --max-depth 4 --hidden --exclude .git --exclude node_modules \
       --exclude .obsidian --exclude __pycache__ \
       . $SEARCH_DIRS 2>/dev/null | \
       sed "s|$HOME/|~/|"
else
    real_path="${1/#\~/$HOME}"
    xdg-open "$real_path" &
fi
