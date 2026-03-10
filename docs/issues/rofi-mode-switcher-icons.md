# Rofi 2.0 Mode-Switcher Cannot Render Non-ASCII Icons

**Status**: UNRESOLVED — rofi 2.0 mode-switcher buttons only render ASCII text
**Date**: 2026-03-10
**Rofi Version**: 2.0.0 (lbonn wayland fork, nixpkgs)

## Problem

The mode-switcher tab bar in rofi 2.0 cannot render any non-ASCII characters,
including Nerd Font glyphs, Font Awesome icons, Unicode PUA symbols, and emoji.
All appear as blank/invisible in the button text while rendering perfectly fine
in rofi's listview items (dmenu mode).

## What Was Tested

| Approach | Result |
|----------|--------|
| Nerd Font MDI icons (U+F0000+ supplementary PUA) | Blank |
| Nerd Font BMP PUA icons (U+E000-U+F8FF) | Blank |
| Font Awesome 7 icons (BMP PUA) | Blank |
| Standard Unicode symbols (⚡, ⌨, ⚙) | Blank |
| Color emoji (🔲, 📋, 🎵) | Mostly blank |
| ASCII text ("Apps", "Win") | Works |
| Mixed ASCII + PUA ("A  B") | ASCII renders, PUA blank |

## What Was Tried

### Font Configuration
- `-font "JetBrainsMono Nerd Font 11"` CLI flag — no effect on tabs
- `configuration { font: "JetBrainsMono Nerd Font 11"; }` in theme — no effect on tabs
- `button { font: "JetBrainsMono Nerd Font 13"; }` in theme — no effect
- `* { font: "JetBrainsMono Nerd Font 14"; }` global override — no effect
- `button { font: "Font Awesome 7 Free Solid 12"; }` — no effect
- `button { font: "Noto Color Emoji 11"; }` — no effect

### Markup
- `button { markup: true; }` in theme — enables Pango markup parsing
- `<span font='JetBrainsMono Nerd Font 13'>&#xf003b;</span>` as display name — HTML entities shown literally
- Pango markup NOT parsed for `-display-*` CLI values

### Icon Codepoint Verification
All icons confirmed present in JetBrainsMono Nerd Font via fontTools:
```python
from fontTools.ttLib import TTFont
font = TTFont('.../JetBrainsMonoNerdFont-Regular.ttf')
cmap = font.getBestCmap()
# All tested codepoints returned True for (cp in cmap)
```

### Fontconfig
- `fc-match -s :charset=E711` correctly returns JetBrainsMono Nerd Font
- System fontconfig defaults set to Nerd Font variants — no effect
- `fonts.fontconfig.defaultFonts.monospace = [ "JetBrainsMono Nerd Font" ]` in NixOS config

## Root Cause Analysis

Rofi 2.0 source (`source/view.c`) creates mode-switcher buttons with:
```c
state->modes[j] = textbox_create(
    WIDGET(state->sidebar_bar), WIDGET_TYPE_MODE_SWITCHER, "button",
    TB_AUTOHEIGHT, ...
    mode_get_display_name(mode), 0.5, 0.5);
```

Only `TB_AUTOHEIGHT` is passed — `TB_MARKUP` is NOT set. This means buttons use
`pango_layout_set_text()` (plain text), and Pango's font fallback for PUA
codepoints in plain text mode does not work correctly. The button `font` property
in the theme may not override the font used by the underlying Pango layout, or
Pango itself refuses to render PUA codepoints without explicit font shaping hints.

This appears to be a combination of:
1. Rofi 2.0 not fully supporting per-widget font overrides for mode-switcher buttons
2. Pango not performing font fallback into PUA ranges for plain text rendering
3. No way to pass Pango markup through the `-display-*` CLI flags or `configuration { display-* }` theme properties

## Current Workaround

Using short ASCII text labels: Apps, Win, Act, Clip, Calc, Find, Media, Svc, Keys, Time

## Potential Future Solutions

1. **Patch rofi source**: Add `TB_MARKUP` flag to mode-switcher button creation, then use
   Pango `<span font="...">` markup in display names
2. **Upstream fix**: File issue on https://github.com/lbonn/rofi or https://github.com/davatorium/rofi
   requesting PUA font support in mode-switcher buttons
3. **Custom widget replacement**: Replace mode-switcher with custom textbox widgets that DO
   render icons (confirmed working), but these are not clickable to switch modes
4. **Alternative launcher**: Consider Anyrun, Walker, or other Wayland launchers that may
   handle this better
5. **Rofi plugin**: Write a custom rofi plugin that renders an icon-based tab bar

## Files Affected

- `private_dot_config/polybar/scripts/executable_wm-actions.sh` — unified command palette launcher
- `private_dot_config/rofi/config/wm-actions.rasi` — command palette theme
- `system_nixos/machines/shared/system-common.nix` — fontconfig defaults (added but untested)
