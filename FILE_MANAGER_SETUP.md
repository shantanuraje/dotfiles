# Enhanced File Manager Configuration

**Last Updated**: August 3, 2025  
**Status**: ✅ Active Configuration

## Overview

This configuration provides a hybrid file management approach that combines the best of CLI and GUI file managers. The setup includes three terminal-based file managers (nnn, lf, ranger) with enhanced CLI tool integration, plus full GNOME desktop integration.

## File Managers Available

### CLI File Managers
- **nnn** (`fm`) - Fastest, with plugins and bookmarks
- **lf** (`fml`) - Miller columns layout, fast navigation  
- **ranger** (`fmr`) - Rich preview system, vi-like keybindings

### GUI File Manager
- **nautilus** (`fmg`) - Full-featured GNOME file manager

## Smart File Opening Hierarchy

CLI file managers use an intelligent hierarchy that tries CLI tools first, then falls back to GUI programs:

### Text Files
1. `$EDITOR` (vim/nvim) - Primary editor
2. VS Code - Development editor
3. GNOME Text Editor - GUI fallback

### Images
1. `chafa` - Terminal image viewer with color
2. `viu` - Alternative terminal image viewer
3. `feh` - Minimal image viewer
4. `eog` - GNOME image viewer (fallback)

### Video/Audio
1. `mpv` - Terminal-capable media player
2. `vlc` - Full-featured media player
3. GNOME defaults (via xdg-open)

### PDF Documents
1. `termpdf` - Terminal PDF viewer
2. `zathura` - Minimal PDF viewer
3. `mupdf` - Lightweight PDF viewer
4. `evince` - GNOME PDF viewer (fallback)

### Archives
1. CLI listing tools (`unzip -l`, `tar -tf`, `7z l`)
2. `file-roller` - GNOME archive manager (fallback)

## Quick CLI Aliases

```bash
# File managers
fm          # nnn (CLI)
fmr         # ranger (CLI)  
fml         # lf (CLI)
fmg         # nautilus (GUI)

# File viewers
img file.jpg       # View image in terminal with chafa
imgv file.jpg      # View image with viu
pdf file.pdf       # Open PDF with zathura
pdfterm file.pdf   # View PDF in terminal
video file.mp4     # Play video with mpv
audio file.mp3     # Play audio with mpv

# Archive operations
zipls archive.zip  # List zip contents
tarls archive.tar  # List tar contents
7zls archive.7z    # List 7z contents
```

## Configuration Files

### NixOS System Packages
- **Location**: `system_nixos/machines/shared/system-common.nix`
- **Includes**: All CLI tools + GNOME programs
- **Key additions**: `chafa`, `viu`, `termpdf`, `mupdf`, `p7zip`, `unrar`

### File Manager Configurations

#### nnn Configuration
- **Config**: `private_dot_config/nnn/nnn-config.sh`
- **Opener**: `private_dot_config/nnn/executable_nnn-opener.sh`
- **Features**: Plugins, bookmarks, smart file opening

#### lf Configuration  
- **Config**: `private_dot_config/lf/lfrc`
- **Features**: Miller columns, enhanced open command

#### ranger Configuration
- **Config**: `private_dot_config/ranger/rifle.conf` (pre-existing)
- **Features**: Already prioritizes CLI tools via rifle system

### MIME Associations
- **Config**: `private_dot_config/mimeapps.list`
- **Purpose**: Sets system-wide defaults for GUI applications

## Workflow Examples

### Enhanced Terminal Experience
```bash
# Browse files with nnn
fm

# In nnn: Press Enter on image → chafa displays in terminal
# In nnn: Press Enter on PDF → termpdf opens in terminal
# In nnn: Press Enter on video → mpv plays in terminal
```

### Full Desktop Integration
```bash
# Browse files with nautilus
fmg

# Right-click any file → Full "Open With" context menu
# Double-click uses GNOME defaults
```

### Hybrid Workflow
```bash
# Quick file operations in terminal
fm                    # Browse with nnn
img photo.jpg         # Quick image preview
pdf document.pdf      # Quick PDF view

# Complex operations in GUI
fmg                   # Switch to nautilus for drag-drop, etc.
```

## Installation Status

### Required Packages
- ✅ **CLI Tools**: `chafa`, `viu`, `termpdf`, `mupdf`, `p7zip`, `unrar`
- ✅ **File Managers**: `nnn`, `lf`, `ranger`, `nautilus`
- ✅ **GNOME Programs**: `eog`, `gedit`, `gnome-text-editor`, `evince`, `file-roller`
- ✅ **Media Players**: `mpv`, `vlc`

### Configuration Status
- ✅ **nnn**: Smart opener configured
- ✅ **lf**: Enhanced open command with CLI hierarchy
- ✅ **ranger**: Uses existing rifle.conf (already optimized)
- ✅ **MIME**: System defaults set for GUI integration
- ✅ **Aliases**: CLI shortcuts configured

## Benefits

1. **Terminal Efficiency**: CLI file managers with enhanced tool integration
2. **GUI Compatibility**: Full GNOME desktop integration when needed
3. **Smart Fallbacks**: No broken file associations - always works
4. **Best of Both**: Enhanced CLI experience + full GUI functionality
5. **No Dependencies**: CLI tools complement rather than replace GUI programs

## Usage Notes

- Use CLI file managers (`fm`/`fmr`/`fml`) for terminal-focused work
- Use GUI file manager (`fmg`) for desktop integration tasks
- All file types have appropriate viewers with intelligent fallbacks
- CLI tools enhance the experience without breaking GUI workflows

This configuration provides seamless file management across both terminal and desktop environments.