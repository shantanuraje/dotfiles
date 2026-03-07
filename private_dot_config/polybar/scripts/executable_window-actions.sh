#!/usr/bin/env bash

# Window actions script for polybar
# Displays focused window title and supports actions via arguments
# Usage:
#   window-actions.sh              - Display focused window title (truncated)
#   window-actions.sh close        - Close focused window
#   window-actions.sh toggle-float - Toggle floating on focused window
#   window-actions.sh toggle-full  - Toggle fullscreen on focused window
#   window-actions.sh move-next    - Move focused window to next workspace
#   window-actions.sh move-prev    - Move focused window to previous workspace
#   window-actions.sh minimize     - Minimize focused window

MAX_TITLE_LEN=30

get_focused_title() {
    local raw
    raw=$(echo '
    local c = client.focus
    if c then
        return c.name or c.class or "Unknown"
    else
        return ""
    end
    ' | awesome-client 2>/dev/null)
    local title
    title=$(echo "$raw" | sed 's/.*string "\(.*\)"/\1/' | tr -d '\n')
    if [ -z "$title" ]; then
        echo ""
        return
    fi
    # Truncate
    if [ ${#title} -gt $MAX_TITLE_LEN ]; then
        title="${title:0:$((MAX_TITLE_LEN - 3))}..."
    fi
    echo "$title"
}

do_close() {
    echo 'if client.focus then client.focus:kill() end' | awesome-client 2>/dev/null
}

do_toggle_float() {
    echo 'if client.focus then client.focus.floating = not client.focus.floating end' | awesome-client 2>/dev/null
}

do_toggle_full() {
    echo 'if client.focus then client.focus.fullscreen = not client.focus.fullscreen end' | awesome-client 2>/dev/null
}

do_minimize() {
    echo 'if client.focus then client.focus.minimized = true end' | awesome-client 2>/dev/null
}

do_move_next() {
    echo '
    local awful = require("awful")
    local c = client.focus
    if c then
        local s = c.screen
        local tags = s.tags
        local current_tag = c.first_tag
        if current_tag then
            local idx = current_tag.index
            local next_idx = (idx % #tags) + 1
            c:move_to_tag(tags[next_idx])
            tags[next_idx]:view_only()
        end
    end
    ' | awesome-client 2>/dev/null
}

do_move_prev() {
    echo '
    local awful = require("awful")
    local c = client.focus
    if c then
        local s = c.screen
        local tags = s.tags
        local current_tag = c.first_tag
        if current_tag then
            local idx = current_tag.index
            local prev_idx = ((idx - 2) % #tags) + 1
            c:move_to_tag(tags[prev_idx])
            tags[prev_idx]:view_only()
        end
    end
    ' | awesome-client 2>/dev/null
}

case "${1:-}" in
    close)
        do_close
        ;;
    toggle-float)
        do_toggle_float
        ;;
    toggle-full)
        do_toggle_full
        ;;
    minimize)
        do_minimize
        ;;
    move-next)
        do_move_next
        ;;
    move-prev)
        do_move_prev
        ;;
    *)
        title=$(get_focused_title)
        if [ -n "$title" ]; then
            echo "$title"
        else
            echo ""
        fi
        ;;
esac
