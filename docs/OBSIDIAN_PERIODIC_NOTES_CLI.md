# Obsidian Periodic Notes — Terminal CLI Access

## Problem

The Obsidian Periodic Notes plugin manages daily, weekly, and yearly notes with date-based directory hierarchies. There's no built-in way to open or cycle through these notes in a terminal editor like `nvim` without launching Obsidian.

## Vault Periodic Notes Configuration

From `.obsidian/plugins/periodic-notes/data.json`:

| Type   | Folder                    | Format                                          | Example Path                                              |
|--------|---------------------------|-------------------------------------------------|-----------------------------------------------------------|
| Daily  | `06-Journal/06-02 Daily`  | `YYYY/YYYY-[W]ww/YYYY-MM-DD/YYYY-MM-DD`        | `06-Journal/06-02 Daily/2026/2026-W12/2026-03-17/2026-03-17.md` |
| Weekly | `06-Journal/06-01 Weekly` | `YYYY/gggg-[W]ww YYYY-MM-DD to YYYY-MM-DD`     | `06-Journal/06-01 Weekly/2026/2026-W12 2026-03-16 to 2026-03-22.md` |
| Yearly | `06-Journal/06-00 Yearly` | `YYYY`                                          | `06-Journal/06-00 Yearly/2026.md`                         |

## Research Summary

### Options Evaluated

| Approach | Pros | Cons | Verdict |
|----------|------|------|---------|
| **Shell functions + nvim** | No dependencies, works offline, supports daily/weekly/yearly, simple offset-based cycling | Need to maintain path logic, no template insertion | **Best option** |
| **Fix obsidian.nvim config** | Already installed, telescope picker, `:ObsidianToday` commands | Only supports daily notes (not weekly/yearly), format matching is finicky | Complementary |
| **Obsidian CLI + shell wrapper** | Uses `obsidian file` for path resolution | Requires Obsidian GUI running | Not standalone |
| **basalt TUI** | Nice browsing interface | No periodic note awareness, general-purpose | Not suitable |

### Obsidian CLI Findings

The `obsidian` CLI (installed at `/run/current-system/sw/bin/obsidian`) can return file paths but requires Obsidian to be running:

```bash
# Get vault-relative path for a note
obsidian file file="2026-03-17" | awk -F'\t' '/^path/ {print $2}'

# Get vault root path
obsidian vault info=path

# Trigger periodic notes commands (opens in Obsidian GUI, not terminal)
obsidian command id="periodic-notes:open-daily-note"
obsidian command id="periodic-notes:open-weekly-note"
obsidian command id="periodic-notes:open-yearly-note"
obsidian command id="periodic-notes:next-daily-note"
obsidian command id="periodic-notes:prev-daily-note"
```

### obsidian.nvim Status

Already installed at `~/.config/nvim/lua/plugins/obsidian.lua` but `daily_notes` config does not match the Periodic Notes plugin format. The community fork at [obsidian-nvim/obsidian.nvim](https://github.com/obsidian-nvim/obsidian.nvim) is the actively maintained version.

## Recommended Implementation: Shell Functions

Add these to `.bashrc` or `.bash_aliases` for terminal access to periodic notes:

```bash
VAULT="$HOME/Documents/personal"

# Daily note: dn [offset]
#   dn        → today's daily note
#   dn -1     → yesterday
#   dn +1     → tomorrow
dn() {
    local offset="${1:-0}"
    local d=$(date -d "today ${offset} days" +%Y-%m-%d)
    local year=$(date -d "$d" +%G)       # ISO week-year
    local week=$(date -d "$d" +%V)       # ISO week number (01-53)
    nvim "${VAULT}/06-Journal/06-02 Daily/${year}/${year}-W${week}/${d}/${d}.md"
}

# Weekly note: wn [offset]
#   wn        → this week's note
#   wn -1     → last week
#   wn +1     → next week
wn() {
    local offset_weeks="${1:-0}"
    local dow=$(date +%u)  # 1=Mon, 7=Sun
    local monday=$(date -d "today -$(( dow - 1 )) days +$(( offset_weeks * 7 )) days" +%Y-%m-%d)
    local sunday=$(date -d "$monday +6 days" +%Y-%m-%d)
    local iso_year=$(date -d "$monday" +%G)
    local iso_week=$(date -d "$monday" +%V)
    nvim "${VAULT}/06-Journal/06-01 Weekly/${iso_year}/${iso_year}-W${iso_week} ${monday} to ${sunday}.md"
}

# Yearly note: yn [offset]
#   yn        → this year's note
#   yn -1     → last year
yn() {
    local offset="${1:-0}"
    local year=$(date -d "today ${offset} years" +%Y)
    nvim "${VAULT}/06-Journal/06-00 Yearly/${year}.md"
}
```

### Key Date Format Codes

| Code | Meaning | Example |
|------|---------|---------|
| `%G` | ISO week-year (may differ from calendar year at year boundaries) | `2026` |
| `%V` | ISO week number (01-53, weeks start Monday) | `12` |
| `%u` | Day of week (1=Monday, 7=Sunday) | `2` |
| `%Y-%m-%d` | Calendar date | `2026-03-17` |

### Notes

- These functions open the file path directly — if the note doesn't exist yet, nvim will create it as an empty file (no template insertion). Consider adding template logic or creating notes via Obsidian first.
- The `%G` (ISO week-year) is important: at year boundaries (e.g., Dec 31 or Jan 1), the ISO week-year may differ from the calendar year, matching how Periodic Notes handles week numbering.
- Cycling is offset-based, so `dn -1`, `dn +1` always works even if the target note doesn't exist yet.

## Future Improvements

- Add template insertion when creating new notes (copy from `05-Meta/05-02-Templates/`)
- Fix obsidian.nvim `daily_notes` config to match Periodic Notes paths for in-editor commands
- Consider an `fzf`-based picker to browse existing notes in the journal directories
