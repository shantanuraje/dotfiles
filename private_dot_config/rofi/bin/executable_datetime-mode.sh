#!/usr/bin/env bash

# DateTime & Calendar rofi script mode
# Shows current time, date info, mini calendar, and today's Obsidian tasks
# Add to unified palette: rofi -modi "clock:datetime-mode.sh" -show clock

VAULT="$HOME/Documents/personal"

if [ -z "$1" ]; then
    echo -en "\0prompt\x1fDateTime\n"
    echo -en "\0markup-rows\x1ftrue\n"

    NOW=$(date '+%I:%M %p')
    TODAY=$(date '+%A, %B %-d, %Y')
    WEEK=$(date '+%V')
    DOY=$(date '+%j')
    UNIX=$(date '+%s')
    ISO=$(date '+%Y-%m-%dT%H:%M:%S%z')

    # Header
    echo "<span color=\"#8bd5ca\">━━ 󰥔 Current Time ━━━━━━━━━</span>"
    echo "<span color=\"#cad3f5\">  $NOW  ·  $TODAY</span>"
    echo "<span color=\"#a5adcb\">  Week $WEEK  ·  Day $DOY  ·  Unix $UNIX</span>"

    # Mini calendar (current month)
    echo ""
    echo "<span color=\"#c6a0f6\">━━ 󰃭 Calendar ━━━━━━━━━━━━━</span>"
    # cal output with today highlighted
    while IFS= read -r line; do
        # Highlight today's date in the calendar
        echo "<span color=\"#a5adcb\">  $line</span>"
    done < <(cal)

    # Upcoming dates
    TOMORROW=$(date -d '+1 day' '+%A, %B %-d')
    NEXT_WEEK=$(date -d '+7 days' '+%A, %B %-d')

    echo ""
    echo "<span color=\"#f5a97f\">━━ 󰸗 Quick Dates ━━━━━━━━━━</span>"
    echo "<span color=\"#cad3f5\">  Tomorrow: $TOMORROW</span>"
    echo "<span color=\"#cad3f5\">  Next week: $NEXT_WEEK</span>"

    # ISO timestamp for copying
    echo ""
    echo "<span color=\"#a6da95\">━━ 󰅍 Copy ━━━━━━━━━━━━━━━━━</span>"
    echo "Copy ISO timestamp: $ISO"
    echo "Copy Unix timestamp: $UNIX"
    echo "Copy date: $(date '+%Y-%m-%d')"

    # Today's tasks from Obsidian vault
    TODAY_DATE=$(date '+%Y-%m-%d')
    YEAR=$(date '+%Y')
    QUARTER="Q$(( ($(date '+%-m') - 1) / 3 + 1 ))"
    WEEK_DIR="W-$(date '+%V')"
    JOURNAL_DIR="$VAULT/06-Journal/$YEAR/$QUARTER/$WEEK_DIR/$TODAY_DATE"

    if [ -d "$JOURNAL_DIR" ]; then
        TASKS=$(grep -rh '\- \[ \]' "$JOURNAL_DIR"/ 2>/dev/null | sed 's/- \[ \] //' | head -8)
        if [ -n "$TASKS" ]; then
            echo ""
            echo "<span color=\"#ed8796\">━━ 󰄬 Today's Tasks ━━━━━━━━</span>"
            while IFS= read -r task; do
                echo "<span color=\"#cad3f5\">  󰄱 $task</span>"
            done <<< "$TASKS"
        fi
    fi

    # Check for overdue tasks across vault
    OVERDUE=$(grep -rl "due: $TODAY_DATE\|due: $(date -d '-1 day' '+%Y-%m-%d')" "$VAULT"/06-Journal/ 2>/dev/null | head -3)
    if [ -n "$OVERDUE" ]; then
        echo ""
        echo "<span color=\"#ed8796\">━━ 󰀦 Overdue ━━━━━━━━━━━━━━</span>"
        while IFS= read -r f; do
            NAME=$(basename "$f" .md)
            echo "<span color=\"#ed8796\">  󰈸 $NAME</span>"
        done <<< "$OVERDUE"
    fi

    exit 0
fi

# Handle selections
case "$1" in
    "Copy ISO"*)
        ISO=$(date '+%Y-%m-%dT%H:%M:%S%z')
        echo -n "$ISO" | xclip -selection clipboard
        notify-send "Copied" "$ISO" -t 2000
        ;;
    "Copy Unix"*)
        UNIX=$(date '+%s')
        echo -n "$UNIX" | xclip -selection clipboard
        notify-send "Copied" "$UNIX" -t 2000
        ;;
    "Copy date"*)
        DATE=$(date '+%Y-%m-%d')
        echo -n "$DATE" | xclip -selection clipboard
        notify-send "Copied" "$DATE" -t 2000
        ;;
esac
