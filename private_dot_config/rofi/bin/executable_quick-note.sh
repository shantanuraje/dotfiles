#!/usr/bin/env bash

# Quick Note - capture a thought directly to Obsidian Inbox
# Opens a rofi prompt, saves to today's quick note file

THEME="$HOME/.config/rofi/config/wm-actions.rasi"
INBOX="$HOME/Documents/personal/00-Inbox"

NOTE=$(rofi -dmenu -p "󰏫 Quick Note" -l 0 -theme "$THEME" \
    -theme-str 'listview {enabled: false;} mode-switcher {enabled: false;}' 2>/dev/null)

[ -z "$NOTE" ] && exit 0

DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M:%S)
FILENAME="${INBOX}/${DATE} Quick Notes.md"

# Create file with frontmatter if it doesn't exist
if [ ! -f "$FILENAME" ]; then
    mkdir -p "$INBOX"
    cat > "$FILENAME" << FRONT
---
title: Quick Notes ${DATE}
dateCreated: $(date -Iseconds)
dateModified: $(date -Iseconds)
tags:
  - inbox
  - quick-note
archived: false
---

# Quick Notes - ${DATE}

FRONT
fi

# Append the note
echo "- [${TIME}] ${NOTE}" >> "$FILENAME"
dunstify -u low "Note saved to Inbox" "$NOTE"
