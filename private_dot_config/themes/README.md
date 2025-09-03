# Universal Theme Switcher

A comprehensive theme management system for your desktop environment, supporting seamless theme switching across AwesomeWM, Polybar, Rofi, and Kitty.

## Features

- **🎨 Multiple Popular Themes**: Catppuccin (4 variants), Gruvbox, Nord, Tokyo Night, Dracula
- **🔄 Seamless Switching**: One command changes themes across all applications
- **🖱️ Interactive Selection**: Beautiful Rofi interface for theme browsing
- **⌨️ Keyboard Shortcuts**: Super+Shift+T to open theme selector
- **💾 Persistent Settings**: Remembers your theme choice across reboots
- **🔧 Template System**: Easy to add new themes

## Quick Start

### Switch Themes
```bash
# Interactive selection (recommended)
~/.config/themes/theme-switcher.sh interactive

# Or use the Rofi selector directly
~/.config/themes/rofi-theme-selector.sh

# Apply specific theme
~/.config/themes/theme-switcher.sh apply catppuccin-mocha

# List available themes
~/.config/themes/theme-switcher.sh list
```

### Keyboard Shortcut
Press **Super+Shift+T** in AwesomeWM to open the theme selector.

## Available Themes

| Theme | Description | Best For |
|-------|-------------|----------|
| **Catppuccin Macchiato** | Warm, cozy dark theme with purple accents | Current default, great for long sessions |
| **Catppuccin Mocha** | Dark, elegant theme with blue accents | Clean, professional look |
| **Gruvbox Dark** | Retro groove colors with warm, earthy tones | Vintage aesthetic, easy on eyes |
| **Nord** | Arctic, north-bluish color palette | Minimal, calm, focused work |
| **Tokyo Night** | Dark theme inspired by Tokyo's neon nights | Modern, vibrant development theme |
| **Dracula** | Dark theme with vibrant colors | High contrast, dramatic look |

## Architecture

```
~/.config/themes/
├── themes.json                     # Central theme definitions
├── current_theme                   # Current theme state
├── theme-switcher.sh              # Main switching script
├── rofi-theme-selector.sh         # Interactive Rofi interface
├── templates/                     # Template files
│   ├── awesome-theme.lua.template
│   ├── polybar-config.ini.template
│   ├── rofi-colors.rasi.template
│   └── rofi-app-launcher.rasi.template
└── README.md                      # This file
```

## How It Works

1. **Central Configuration**: All themes defined in `themes.json` with complete color palettes
2. **Template System**: Each application has template files with placeholder variables
3. **Theme Generation**: Switcher script processes templates and generates actual config files
4. **Live Reload**: Applications are automatically reloaded after theme changes

## Theme Components

Each theme affects:
- **AwesomeWM**: Window borders, taglist, widgets, notifications
- **Polybar**: Bar colors, module colors, icons
- **Rofi**: Launcher colors, selection highlighting, borders
- **Kitty**: Terminal colors, background, cursor, selection

## Adding New Themes

1. Add theme definition to `themes.json`:
```json
"new-theme": {
  "name": "New Theme",
  "description": "Description of the theme",
  "colors": {
    "base": "#background-color",
    "text": "#foreground-color",
    "red": "#red-color",
    // ... other color definitions
  }
}
```

2. If needed, add custom Kitty theme file to `~/.config/kitty/themes/`

3. Test with: `theme-switcher.sh apply new-theme`

## Troubleshooting

### Theme Not Applying
- Check if all applications are running
- Verify theme exists: `theme-switcher.sh list`
- Check logs in terminal output

### Colors Look Wrong
- Ensure your terminal supports 24-bit color
- Check if custom Kitty theme file exists for the theme
- Verify template files are not corrupted

### AwesomeWM Not Reloading
- The script uses `awesome-client` to reload AwesomeWM
- If it fails, manually restart AwesomeWM with Super+Ctrl+R

### Polybar Issues
- Polybar is killed and restarted during theme switching
- Check if `~/.config/polybar/launch.sh` exists and is executable

## Integration with Other Tools

- **Chezmoi**: All theme files are managed by chezmoi for version control
- **Git**: Commit theme changes with: `chezmoi cd && git add . && git commit -m "feat: add theme switcher"`
- **NixOS**: Theme dependencies are managed through your NixOS configuration

## Commands Reference

```bash
# Theme management
theme-switcher.sh apply <theme>     # Apply specific theme
theme-switcher.sh list             # List available themes  
theme-switcher.sh current          # Show current theme
theme-switcher.sh interactive      # Interactive selection
theme-switcher.sh help             # Show help

# Rofi selector
rofi-theme-selector.sh             # Launch theme selector
rofi-theme-selector.sh preview <theme> # Preview specific theme
```

## Customization

### Adding New Color Variants
Edit `themes.json` to add new color schemes. The system uses a standardized color mapping:

- `base`: Main background
- `text`: Main foreground/text color
- `surface0`/`surface1`: Secondary backgrounds
- `red`, `green`, `blue`, `yellow`: Accent colors
- `teal`: Primary accent (borders, highlights)
- `mauve`/`purple`: Secondary accent
- `overlay0`: Disabled/muted colors

### Modifying Templates
Templates in `templates/` directory use `{{VARIABLE}}` syntax for color substitution. Modify these to change how themes are applied to each application.

---

*Theme switcher integrated with your chezmoi dotfiles configuration.*