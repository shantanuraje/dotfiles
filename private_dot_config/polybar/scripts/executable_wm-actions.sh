#!/usr/bin/env bash

# Unified Command Palette for AwesomeWM
# All modes in one tabbed rofi: apps, windows, actions, clipboard,
# calculator, files, media, services, keybindings, datetime
#
# Usage:
#   wm-actions.sh              - opens on Actions tab
#   wm-actions.sh apps         - opens on Apps tab
#   wm-actions.sh windows      - opens on Windows tab
#   wm-actions.sh clipboard    - opens on Clipboard tab
#   wm-actions.sh calc         - opens on Calculator tab
#   wm-actions.sh datetime     - opens on DateTime tab
#   wm-actions.sh emoji        - opens emoji picker (rofimoji)
#   wm-actions.sh note         - opens quick note prompt
#   wm-actions.sh <any-mode>   - opens on that tab

THEME="$HOME/.config/rofi/config/wm-actions.rasi"
SCRIPTS="$HOME/.config/rofi/bin"

# Special launchers that don't use the unified palette
case "${1:-}" in
    emoji)
        rofimoji --selector rofi --action copy --skin-tone neutral 2>/dev/null
        exit 0
        ;;
    note)
        exec "$SCRIPTS/quick-note.sh"
        ;;
esac

# Map friendly names to rofi mode names
MODE="${1:-actions}"
case "$MODE" in
    apps)       SHOW="drun" ;;
    windows)    SHOW="window" ;;
    clip*)      SHOW="clipboard" ;;
    calc*)      SHOW="calc" ;;
    file*)      SHOW="files" ;;
    media)      SHOW="media" ;;
    serv*)      SHOW="services" ;;
    keys*)      SHOW="keys" ;;
    date*|time*|clock*) SHOW="clock" ;;
    *)          SHOW="actions" ;;
esac

rofi -font "JetBrainsMono Nerd Font 11" \
     -plugin-path /run/current-system/sw/lib/rofi \
     -modi "drun,window,actions:${SCRIPTS}/wm-actions-mode.sh,clipboard:greenclip print,calc,files:${SCRIPTS}/file-search-mode.sh,media:${SCRIPTS}/media-control-mode.sh,services:${SCRIPTS}/systemd-mode.sh,keys:${SCRIPTS}/keybindings-mode.sh,clock:${SCRIPTS}/datetime-mode.sh" \
     -show "$SHOW" \
     -theme "$THEME" \
     -display-drun "Apps" \
     -display-window "Win" \
     -display-actions "Act" \
     -display-clipboard "Clip" \
     -display-calc "Calc" \
     -display-files "Find" \
     -display-media "Media" \
     -display-services "Svc" \
     -display-keys "Keys" \
     -display-clock "Time" \
     2>/dev/null
