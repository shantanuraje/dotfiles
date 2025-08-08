# nnn File Manager - GUI-Free Workflow Setup

## Overview
Complete nnn configuration for replacing GUI file managers with a powerful terminal-based solution. Includes plugins, bookmarks, preview capabilities, and seamless integration with your existing workflow.

## Quick Start

After applying chezmoi changes:

```bash
# Basic usage
n              # Start nnn
nn             # Start nnn with hidden files  
np             # Start nnn with preview (in tmux/zellij)

# Quick navigation
nh             # nnn in home directory
nd             # nnn in Downloads
nproj          # nnn in Projects
nchezmoi       # nnn in chezmoi config
nnixos         # nnn in NixOS config

# Get help
nhelp          # Show complete command reference
```

## Key Features Configured

### 🔌 Plugin System
- **Comprehensive plugin set** installed automatically
- **Access**: Press `;` in nnn to see plugin menu
- **Key plugins**:
  - `f` - Fuzzy finder integration
  - `p` - File preview with syntax highlighting  
  - `r` - Batch file renaming
  - `v` - Image viewer integration
  - `d` - File differences and comparisons
  - `n` - Batch operations (nuke)

### 📚 Smart Bookmarks
Press `g` + key in nnn for instant navigation:
- `gh` - Home directory
- `gd` - Downloads
- `gp` - Projects  
- `gc` - Config files
- `gs` - Chezmoi source
- `gn` - NixOS configuration
- `gA` - Android Studio projects

### 🔍 Fuzzy Search Integration (fzf-powered)

**Command-line functions** (use before starting nnn):
```bash
nf             # Fuzzy directory selection with preview → open nnn there
nff            # Fuzzy file search with bat preview → navigate to file location
nrg            # Content search with ripgrep → open nnn at matching file
ngit           # Git file search → navigate to selected git file
```

**In-app search** (inside nnn):
```bash
/              # Search filenames in current directory
;f             # Plugin: fuzzy finder for current directory
;c             # Plugin: fzf directory navigation
```

### 💾 Session Management
```bash
nsave mysession    # Save current directory as session
nload mysession    # Load and start nnn from session
nlist              # List all saved sessions
```

### 🖼️ Preview Support
- **Text files**: Syntax highlighting with bat
- **Images**: Integration with feh/kitty
- **PDFs**: Text extraction with poppler
- **Videos**: Thumbnail generation
- **Archives**: Content listing
- **Media files**: Metadata display

## Configuration Structure

```
~/.config/nnn/
├── nnn-config.sh          # Main configuration (managed by chezmoi)
├── plugins/               # Auto-installed plugin directory
└── sessions/              # Saved directory sessions
```

## Integration with Existing Tools

### Terminal Multiplexers
- **tmux**: `np` creates preview in split pane
- **zellij**: `np` creates preview in new pane  

### Editors
- **Default**: Opens files with nvim (via $EDITOR)
- **Specific**: `nedit` forces nvim, `ncode` uses VS Code

### Version Control
- **Git integration**: `ngit` for fuzzy git file selection
- **Diff support**: Plugin for file comparisons

### File Operations
- **Smart opener**: xdg-open handles file types appropriately  
- **Archive support**: Automatic extraction and browsing
- **Batch operations**: Rename, copy, move multiple files

## Advanced Features

### Color Customization
- **Custom color scheme** optimized for terminal use
- **File type colors** for easy identification
- **Consistent with bat/eza** color themes

### Performance Optimizations
- **Fast startup** with minimal overhead
- **Efficient navigation** with auto-enter directories
- **Smart caching** for quick repeated operations

### Workflow Integration
- **Case-insensitive sorting** for better UX
- **Navigate to last directory** on startup/quit
- **Detail mode** shows file permissions and sizes
- **Hidden file toggle** without restart

## Comparison with GUI File Managers

| Feature | GUI File Manager | nnn Setup |
|---------|------------------|-----------|
| **Speed** | Slow startup | Instant |
| **Keyboard nav** | Limited | Full control |
| **Customization** | Basic themes | Extensive plugins |
| **Preview** | Basic | Syntax highlighting |
| **Batch ops** | Click-heavy | Efficient selection |
| **Integration** | Standalone | Terminal ecosystem |
| **Resource usage** | High memory | Minimal |
| **SSH/Remote** | Not available | Works seamlessly |

## Tips for GUI-Free Workflow

### File Selection
- **Space**: Mark/unmark files for batch operations
- **a**: Select all files in current view
- **A**: Invert selection
- **Tab**: Switch between selection and navigation

### Quick Operations
- **Enter**: Open file/enter directory
- **l**: Open file with default application
- **e**: Edit file with $EDITOR
- **p**: Copy file path to clipboard

### Navigation
- **~**: Go to home directory
- **-**: Go to last visited directory  
- **@**: Show command history
- **g**: Bookmark navigation menu

### Search and Filter
- **/**: Search files in current directory
- **:****: Execute shell command
- **!**: Open shell in current directory

## Troubleshooting

### Plugin Installation Issues
```bash
# Reinstall plugins manually
install_nnn_plugins

# Update existing plugins
update_nnn_plugins
```

### Preview Not Working
- Ensure required packages are installed (handled by NixOS config)
- Check if running in compatible terminal (kitty, alacritty work best)
- For tmux/zellij preview, ensure multiplexer is active

### Performance Issues
- Use `nn` instead of `n` if many hidden files slow down navigation
- Consider increasing terminal scrollback for large directories

## Migration from GUI File Managers

### From Nautilus/Dolphin Users
- **Bookmarks**: Use `g` + key instead of sidebar bookmarks
- **Preview**: Plugin `p` provides similar functionality
- **Properties**: Press `d` for detailed file information

### From Finder Users  
- **Quick Look**: Plugin `p` with enhanced preview
- **Tags**: Use session management instead
- **Spotlight**: Use fuzzy search functions (`nf`, `nrg`)

## Next Steps

1. **Apply configuration**: `chezmoi apply`
2. **Reload shell**: `source ~/.bashrc` 
3. **Start exploring**: `n` and press `?` for help
4. **Try plugins**: Press `;` in nnn
5. **Set bookmarks**: Navigate and use `g` shortcuts

---

**Pro Tip**: Start with basic navigation (`n`, `nh`, `nd`) and gradually incorporate plugins and advanced features as you get comfortable with the interface.

*Last updated: 2025-08-02*