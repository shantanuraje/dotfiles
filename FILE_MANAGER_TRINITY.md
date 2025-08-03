# File Manager Trinity - Complete GUI-Free Setup

## Overview
Ultimate terminal file manager configuration featuring three specialized tools, each optimized for different workflows and use cases.

## The Trinity

### 🚀 **nnn** - Speed Champion
**Philosophy**: Minimal, fast, efficient
- **Startup**: ~20ms (fastest)
- **Memory**: <10MB
- **Interface**: Single-pane with 4 contexts
- **Best for**: Daily file operations, quick navigation

### ⚡ **lf** - Miller Columns Master  
**Philosophy**: Go-based performance with vi-like control
- **Startup**: ~50ms (very fast)
- **Memory**: ~15MB
- **Interface**: 3-pane Miller columns
- **Best for**: Directory browsing, file operations

### 🎨 **ranger** - Feature Powerhouse
**Philosophy**: Python-based customization and rich previews
- **Startup**: ~200ms (full-featured)
- **Memory**: ~30-50MB
- **Interface**: 3-pane with extensive preview
- **Best for**: File exploration, media management

## Quick Start Commands

### Basic Usage
```bash
# Quick access
n         # nnn (fastest)
lf        # lf (3-pane)
ranger    # ranger (rich)

# Directory shortcuts
nh/lh/rh  # Home directory
nd/ld/rd  # Downloads
np/lp/rp  # Projects
```

### Help and Comparison
```bash
fm-help       # Quick reference
fm-compare    # Detailed comparison
nhelp         # nnn-specific help
```

## Detailed Configurations

### 🚀 **nnn Configuration**

**Location**: `~/.config/nnn/nnn-config.sh`

**Key Features**:
- Auto-installing plugin system
- Smart bookmarks (g + key)
- Session management
- fzf integration
- Terminal multiplexer support

**Essential Commands**:
```bash
n              # Start nnn
np             # nnn with preview (tmux/zellij)
nh             # nnn in home
nf             # Fuzzy directory selection
nsave/nload    # Session management
```

**Contexts**: Use `1`, `2`, `3`, `4` to switch between 4 virtual workspaces

**Plugins**: Press `;` for plugin menu:
- `f` - Fuzzy finder
- `p` - Preview
- `r` - Rename files
- `v` - Image viewer
- `d` - File diff

### ⚡ **lf Configuration**

**Location**: `~/.config/lf/lfrc`

**Key Features**:
- Miller columns (parent/current/preview)
- Vi-like keybindings
- Comprehensive preview script
- Archive operations
- Git integration

**Essential Commands**:
```bash
lf             # Start lf
h/j/k/l        # Vi navigation
space          # Select files
ex             # Extract archives
E              # Edit with nvim
```

**Quick Actions**:
- `zi` - Create zip
- `zt` - Create tar.gz
- `ff` - Fuzzy search
- `gb` - Git branch operations

### 🎨 **ranger Configuration**

**Location**: `~/.config/ranger/rc.conf`

**Key Features**:
- Rich preview system
- Image thumbnails (kitty protocol)
- Version control integration
- Extensive sorting options
- Function key shortcuts

**Essential Commands**:
```bash
ranger         # Start ranger
j/k            # Navigate
space          # Select
yy/dd/pp       # Copy/cut/paste
zh             # Toggle hidden files
```

**Advanced Features**:
- `F1-F10` - Function key shortcuts
- `M` + key - Change line mode
- `o` + key - Sort options
- `z` + key - Toggle settings

## Performance Comparison

| Metric | nnn | lf | ranger |
|--------|-----|----|---------| 
| **Startup Time** | 20ms | 50ms | 200ms |
| **Memory Usage** | 8MB | 15MB | 40MB |
| **File Preview** | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Customization** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Learning Curve** | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |

## Use Case Recommendations

### Choose **nnn** when:
- ✅ Maximum speed is priority
- ✅ Working with large directories
- ✅ Need plugin ecosystem
- ✅ Single-pane workflow preference
- ✅ SSH/remote sessions

### Choose **lf** when:
- ✅ Want Miller columns layout
- ✅ Vi-like keybindings familiar
- ✅ Need balanced speed/features
- ✅ Server mode required
- ✅ Go-based reliability preference

### Choose **ranger** when:
- ✅ Rich preview capabilities needed
- ✅ Python customization required
- ✅ Media file management
- ✅ Extensive configuration desired
- ✅ Learning new tool is acceptable

## Workflow Integration

### Terminal Multiplexers
All three integrate with tmux/zellij:
```bash
np             # nnn with preview pane
# lf automatically uses preview pane
# ranger shows preview in right column
```

### Editor Integration
```bash
# All configured to use nvim
export EDITOR="nvim"

# Quick edit
nedit          # nnn with nvim
# E in lf       
# E in ranger
```

### Git Integration
```bash
# nnn
ngit           # Git file fuzzy search

# lf  
gb             # Git branch operations
gl             # Git log

# ranger
Built-in VCS support with status indicators
```

## Advanced Features

### Session Management (nnn)
```bash
nsave project    # Save current directory
nload project    # Load saved session
nlist           # List all sessions
```

### Bulk Operations
- **nnn**: Select with space, use plugins
- **lf**: Select with space, use commands
- **ranger**: Visual mode with `V`

### Archive Handling
All three support:
- Auto-detection of archive types
- Preview of archive contents
- Extraction commands
- Creation of new archives

### Image Preview
- **nnn**: Via plugins and feh integration
- **lf**: ASCII art and metadata
- **ranger**: Full image thumbnails (kitty protocol)

## Keyboard Shortcuts Cheat Sheet

### Universal (Vi-like)
```
j/k           # Up/down
h/l           # Left/right (back/forward)
gg/G          # Top/bottom
/             # Search
Space         # Select/toggle
```

### File Operations
```
yy            # Copy (ranger/lf)
dd            # Cut (ranger/lf)
pp            # Paste (ranger/lf)
```

### Quick Navigation
```
gh            # Home
gd            # Downloads  
gp            # Projects
gc            # Config
```

## Troubleshooting

### Preview Issues
```bash
# Install missing dependencies
# Already handled by NixOS configuration:
bat highlight w3m mediainfo exiftool
```

### Performance Issues
- **nnn**: Use contexts instead of multiple instances
- **lf**: Disable image preview if slow: `set preview_images false`
- **ranger**: Reduce preview size or disable: `set preview_files false`

### Key Conflicts
Each file manager uses different config files, so no conflicts between them.

## Migration Guide

### From GUI File Managers

**Nautilus/Files users**:
- Bookmarks → `g` + key shortcuts
- Sidebar → Miller columns in lf/ranger
- Properties → `i` command
- Preview → Built-in preview panes

**Finder users**:
- Quick Look → Preview panes
- Tags → Use sessions (nnn) or bookmarks
- Spotlight → Fuzzy search functions

### Between Terminal File Managers

**From Midnight Commander**:
- All three support F1-F10 keys (ranger)
- Dual pane → Miller columns (lf/ranger)
- Menu → Plugin system (nnn) or commands

## Extensions and Plugins

### nnn Plugins (Auto-installed)
Located in `~/.config/nnn/plugins/`:
- 30+ official plugins
- Custom script support
- Auto-updater included

### lf Custom Scripts
Located in `~/.config/lf/`:
- Preview script with all file types
- Cleaner script for cleanup
- Custom commands in lfrc

### ranger Plugins
Located in `~/.config/ranger/plugins/`:
- Python-based plugins
- Rich ecosystem available
- Custom commands support

## Tips and Tricks

### Performance Optimization
1. **Use appropriate tool for task**:
   - Quick ops → nnn
   - Directory browsing → lf  
   - Media exploration → ranger

2. **Disable heavy features when not needed**:
   - Turn off image preview in large image directories
   - Use minimal configs for SSH sessions

3. **Leverage contexts/tabs**:
   - nnn: Use 4 contexts instead of multiple instances
   - lf/ranger: Use tabs for multiple locations

### Workflow Tips
1. **Consistent shortcuts**: All use `g` + key for bookmarks
2. **Shell integration**: All support `!!` for last command
3. **Copy paths**: All support copying file paths to clipboard

## Future Enhancements

### Planned Additions
- [ ] Custom ranger themes
- [ ] lf plugin system expansion
- [ ] Cross-tool session sharing
- [ ] Unified bookmark system
- [ ] Performance monitoring

### Configuration Sync
All configurations are managed by chezmoi for easy deployment across systems.

---

**Quick Reference Card**:
```bash
# The Trinity
n / nnn        # Speed champion (contexts: 1,2,3,4)
lf             # Miller columns (h/j/k/l navigation)  
ranger         # Feature powerhouse (rich previews)

# Universal shortcuts
gh/gd/gp       # Home/Downloads/Projects
space          # Select files
?              # Help
q              # Quit
```

*Last updated: 2025-08-02*