# Zellij Journal Notes — Terminal Periodic Notes Viewer

## Problem

Open daily, weekly, and yearly Obsidian periodic notes as connected panes in Zellij, and cycle through them (next/prev day, with weekly and yearly adjusting at boundaries).

## Zellij Limitations (v0.43.1)

- **`write-chars` has no `--pane-id`** — only writes to the focused pane
- **`close-pane` has no `--pane-id`** — only closes the focused pane
- **No "replace pane command" action** — `--in-place` suspends the old pane, doesn't replace it
- **Open feature requests**: [#4524](https://github.com/zellij-org/zellij/issues/4524) (close pane by name/ID), [#3061](https://github.com/zellij-org/zellij/issues/3061) (actions on specific panes)

These constraints mean there's no clean way to programmatically send commands to specific panes by name or ID.

## Solutions

### Solution 1: `jn` — nvim Vertical Splits (Recommended, Simplest)

A single shell function that opens all 3 notes as nvim vertical splits in one pane. Cycling is just `:qa` and re-run with a new offset.

```bash
# Usage: jn (today), jn -1 (yesterday's set), jn +1 (tomorrow's set)
jn() {
    local offset="${1:-0}"
    local VAULT="$HOME/Documents/personal"

    # Daily
    local d=$(date -d "today ${offset} days" +%Y-%m-%d)
    local year=$(date -d "$d" +%G)
    local week=$(date -d "$d" +%V)
    local daily="${VAULT}/06-Journal/06-02 Daily/${year}/${year}-W${week}/${d}/${d}.md"

    # Weekly (find the Monday of that day's week)
    local dow=$(date -d "$d" +%u)
    local monday=$(date -d "$d -$(( dow - 1 )) days" +%Y-%m-%d)
    local sunday=$(date -d "$monday +6 days" +%Y-%m-%d)
    local wy=$(date -d "$monday" +%G)
    local ww=$(date -d "$monday" +%V)
    local weekly="${VAULT}/06-Journal/06-01 Weekly/${wy}/${wy}-W${ww} ${monday} to ${sunday}.md"

    # Yearly
    local yearly="${VAULT}/06-Journal/06-00 Yearly/${year}.md"

    nvim -O "$daily" "$weekly" "$yearly"
}
```

**Pros**: Zero complexity, works everywhere, no Zellij dependency, cycling via offset.
**Cons**: All notes in one nvim instance (no separate Zellij pane titles/frames). Must `:qa` to cycle.

### Solution 2: Zellij Layout with Loop Wrappers

Each pane runs a loop script that reads a shared state file. To cycle: `:q` in each nvim pane → the script reads the updated state → opens the next date's note automatically.

#### State File
`/tmp/zellij-journal-offset` — contains a single integer (default: 0).

#### Loop Wrapper Scripts
Each pane runs one of these. When nvim exits (`:q`), the script loops and re-reads the offset.

```bash
#!/usr/bin/env bash
# journal-pane.sh <daily|weekly|yearly>
TYPE="$1"
VAULT="$HOME/Documents/personal"
STATE="/tmp/zellij-journal-offset"

while true; do
    offset=$(cat "$STATE" 2>/dev/null || echo 0)

    d=$(date -d "today ${offset} days" +%Y-%m-%d)
    year=$(date -d "$d" +%G)
    week=$(date -d "$d" +%V)

    case "$TYPE" in
        daily)
            file="${VAULT}/06-Journal/06-02 Daily/${year}/${year}-W${week}/${d}/${d}.md"
            ;;
        weekly)
            dow=$(date -d "$d" +%u)
            monday=$(date -d "$d -$(( dow - 1 )) days" +%Y-%m-%d)
            sunday=$(date -d "$monday +6 days" +%Y-%m-%d)
            wy=$(date -d "$monday" +%G)
            ww=$(date -d "$monday" +%V)
            file="${VAULT}/06-Journal/06-01 Weekly/${wy}/${wy}-W${ww} ${monday} to ${sunday}.md"
            ;;
        yearly)
            file="${VAULT}/06-Journal/06-00 Yearly/${year}.md"
            ;;
    esac

    mkdir -p "$(dirname "$file")"
    nvim "$file"

    # After nvim exits, check if state file still exists (exit loop if deleted)
    [ ! -f "$STATE" ] && break
done
```

#### Zellij Layout (`journal.kdl`)
```kdl
layout {
    tab name="journal" {
        pane size=1 borderless=true {
            plugin location="zellij:tab-bar"
        }
        pane split_direction="vertical" {
            // Daily note (60% width, main focus)
            pane command="bash" size="60%" focus=true {
                args "-c" "$HOME/.local/bin/journal-pane.sh daily"
                name "Daily"
            }
            pane split_direction="horizontal" {
                // Weekly note (top right)
                pane command="bash" {
                    args "-c" "$HOME/.local/bin/journal-pane.sh weekly"
                    name "Weekly"
                }
                // Yearly note (bottom right)
                pane command="bash" {
                    args "-c" "$HOME/.local/bin/journal-pane.sh yearly"
                    name "Yearly"
                }
            }
        }
        pane size=2 borderless=true {
            plugin location="zellij:status-bar"
        }
    }
}
```

#### Cycling Script
```bash
#!/usr/bin/env bash
# journal-cycle.sh <next|prev|reset>
STATE="/tmp/zellij-journal-offset"
current=$(cat "$STATE" 2>/dev/null || echo 0)

case "${1:-next}" in
    next)  echo $(( current + 1 )) > "$STATE" ;;
    prev)  echo $(( current - 1 )) > "$STATE" ;;
    reset) echo 0 > "$STATE" ;;
esac

echo "Journal offset: $(cat "$STATE") ($(date -d "today $(cat "$STATE") days" +%Y-%m-%d))"
```

#### Workflow
1. Launch: `zellij --layout journal.kdl` or add the tab to `default.kdl`
2. All 3 panes open with today's notes
3. To cycle: run `journal-cycle.sh next` (from any shell), then `:q` in each nvim pane
4. Each pane's loop script re-reads the offset and opens the new date's note
5. To exit completely: delete the state file (`rm /tmp/zellij-journal-offset`) then `:q`

**Pros**: Proper Zellij panes with titles/frames, each note independently scrollable/resizable.
**Cons**: Must `:q` each pane manually to trigger re-read. Cycling is 2-step (run cycle script + quit panes).

### Solution 3: Zellij Layout + WriteChars Focus Cycling (Hackiest)

A script that sequentially focuses each pane and sends `:e <newfile>\n` via `write-chars`. Works but fragile — depends on pane focus order being consistent.

```bash
#!/usr/bin/env bash
# journal-write-cycle.sh <next|prev>
# Must be run from WITHIN the journal tab in Zellij
STATE="/tmp/zellij-journal-offset"
current=$(cat "$STATE" 2>/dev/null || echo 0)
[[ "$1" == "prev" ]] && current=$(( current - 1 )) || current=$(( current + 1 ))
echo "$current" > "$STATE"

VAULT="$HOME/Documents/personal"
d=$(date -d "today ${current} days" +%Y-%m-%d)
year=$(date -d "$d" +%G)
week=$(date -d "$d" +%V)
dow=$(date -d "$d" +%u)
monday=$(date -d "$d -$(( dow - 1 )) days" +%Y-%m-%d)
sunday=$(date -d "$monday +6 days" +%Y-%m-%d)
wy=$(date -d "$monday" +%G)
ww=$(date -d "$monday" +%V)

daily="${VAULT}/06-Journal/06-02 Daily/${year}/${year}-W${week}/${d}/${d}.md"
weekly="${VAULT}/06-Journal/06-01 Weekly/${wy}/${wy}-W${ww} ${monday} to ${sunday}.md"
yearly="${VAULT}/06-Journal/06-00 Yearly/${year}.md"

# Escape any active nvim mode, then :e to switch buffer
# This sends to the FOCUSED pane, so we must focus each one
send_to_focused() {
    # Press Escape to ensure normal mode, then open file
    zellij action write 27  # ESC
    sleep 0.1
    zellij action write-chars ":e $1"
    zellij action write 13  # Enter
}

# Assumes 3 panes in order: daily, weekly, yearly
# Navigate to first pane, then cycle through
send_to_focused "$daily"
zellij action focus-next-pane
sleep 0.2
send_to_focused "$weekly"
zellij action focus-next-pane
sleep 0.2
send_to_focused "$yearly"
zellij action focus-next-pane  # return to daily
```

**Pros**: Instant cycling without quitting nvim.
**Cons**: Fragile — depends on pane focus order, race conditions with sleep, breaks if panes are reordered.

## Recommendation

**Start with Solution 1 (`jn` function)** — it's simple, reliable, and covers 90% of the use case. Add it to `.bash_aliases` alongside `dn`, `wn`, `yn`.

**Graduate to Solution 2** if you want the full Zellij pane experience with separate frames and titles.

**Solution 3** is documented for reference but not recommended for daily use due to fragility.

## Date Format Reference

| Code | Meaning | Example | Why |
|------|---------|---------|-----|
| `%G` | ISO week-year | `2026` | Matches Periodic Notes `gggg` — handles year boundary weeks |
| `%V` | ISO week number | `12` | Matches Periodic Notes `ww` |
| `%u` | Day of week (Mon=1) | `2` | Used to find Monday of any week |
| `%Y-%m-%d` | Calendar date | `2026-03-17` | Matches Periodic Notes `YYYY-MM-DD` |
