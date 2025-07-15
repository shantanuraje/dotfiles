# Personal Dotfiles Configuration

A comprehensive, well-organized dotfiles repository managed with [chezmoi](https://chezmoi.io/) for consistent development environment across systems.

## 🚀 Quick Start

```bash
# Install dotfiles
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply https://github.com/your-username/dotfiles

# Or if already cloned
chezmoi init && chezmoi apply
```

## 📁 Repository Structure

```
~/.local/share/chezmoi/
├── README.md                     # This comprehensive documentation
├── NIXOS_USAGE.md               # NixOS-specific instructions
├── dot_claude/                  # Claude AI assistant configuration
│   └── CLAUDE.md               # Global Claude instructions
├── dot_profile                  # Shell profile configuration
├── dot_vimrc                   # Vim editor configuration
├── private_dot_bashrc          # Bash shell configuration (private)
├── dot_screenlayout/           # Display layout scripts
│   ├── executable_home-desktop.sh    # Home display setup
│   └── executable_work-desktop.sh    # Work display setup
├── dot_termux/                 # Termux Android terminal config
│   ├── font.ttf               # Custom font
│   └── private_colors.properties  # Color scheme (private)
├── private_dot_config/         # Application configurations (private)
│   ├── awesome/               # AwesomeWM window manager
│   ├── hypr/                  # Hyprland wayland compositor
│   ├── kitty/                 # Kitty terminal emulator
│   ├── neofetch/              # System information tool
│   ├── nnn/                   # Terminal file manager
│   ├── nvim/                  # Neovim editor
│   ├── ranger/                # Ranger file manager
│   ├── rofi/                  # Application launcher
│   ├── waybar/                # Status bar for wayland
│   └── zellij/                # Terminal multiplexer
├── scripts/                    # Utility scripts
│   ├── deploy-nixos.sh        # NixOS deployment automation
│   └── test-deploy-nixos.sh   # NixOS deployment testing
└── system_nixos/              # NixOS system configuration
    ├── configuration.nix      # Main system config
    ├── flake.nix             # Nix flake configuration
    ├── flake.lock            # Flake dependency lock
    ├── hardware-configuration.nix  # Hardware-specific settings
    └── gemini-cli.nix        # Custom Gemini CLI module
```

## 🔧 Configuration Overview

### 🖥️ Desktop Environment
- **Window Managers**: AwesomeWM (X11) + Hyprland (Wayland)
- **Theme**: Catppuccin Macchiato throughout all applications
- **Compositor**: Picom (for AwesomeWM) / Built-in (Hyprland)
- **Status Bar**: Native AwesomeWM wibar / Waybar (Hyprland)
- **Launcher**: Rofi with custom themes

### 🔤 Terminal & Shell
- **Terminal**: Kitty with Catppuccin themes
- **Shell**: Bash with custom configurations
- **Multiplexer**: Zellij for session management
- **File Manager**: nnn (terminal) + ranger (full-featured)

### ✏️ Editors
- **Primary**: Neovim with comprehensive plugin setup
  - LSP support, autocompletion, Git integration
  - Claude Code integration for AI assistance
  - Custom keybindings and themes
- **Fallback**: Vim with essential configuration

### 🛠️ System Management
- **OS**: NixOS with flake-based configuration
- **Package Manager**: Nix with reproducible builds
- **Dotfiles Manager**: Chezmoi for templating and deployment
- **Display**: Custom screen layout scripts for different setups

## 🚀 Usage

### Chezmoi Operations
```bash
# Apply all configurations
chezmoi apply

# Preview changes before applying
chezmoi apply --dry-run

# Edit a managed file
chezmoi edit ~/.bashrc

# Add new file to management
chezmoi add ~/.config/newfile

# Check differences
chezmoi diff

# Update from git repository
chezmoi update
```

### NixOS Management
```bash
# Edit system configuration
chezmoi edit system_nixos/configuration.nix

# Test deployment (dry-run)
bash ~/.local/share/chezmoi/scripts/test-deploy-nixos.sh

# Deploy changes with automatic backup
bash ~/.local/share/chezmoi/scripts/deploy-nixos.sh

# Check configuration differences
sudo diff -r /etc/nixos/ ~/.local/share/chezmoi/system_nixos/
```

### Development Workflow
```bash
# Navigate to source directory
chezmoi cd

# Check status
git status

# Commit changes
git add .
git commit -m "feat: update configuration"
git push

# Exit back to home directory
exit
```

## 🎨 Themes & Styling

All applications use the **Catppuccin Macchiato** color scheme for consistency:

- **Primary Colors**: Deep purple backgrounds with warm accents
- **Accent Color**: Cyan/green for highlights and active elements
- **Typography**: JetBrains Mono and Nerd Font variants
- **Effects**: Rounded corners, blur effects, subtle shadows

### Customization
To change themes system-wide:
1. Update color definitions in theme files
2. Modify application-specific theme configurations
3. Apply changes with `chezmoi apply`

## 🔐 Security & Privacy

- **Private files**: Prefixed with `private_` for restricted permissions
- **Secrets management**: Sensitive data excluded from version control
- **Backup safety**: Automatic backups before system changes
- **Version control**: All changes tracked and reversible

## ⚡ Key Features

### Automation
- **One-command deployment**: Complete environment setup
- **Automatic backups**: Safe system modifications
- **Testing framework**: Validate changes before applying
- **Cross-platform**: Works on multiple Linux distributions

### Consistency
- **Unified theming**: Matching colors across all applications
- **Synchronized keybindings**: Same shortcuts everywhere
- **Shared configurations**: Common settings templated

### Maintainability
- **Modular structure**: Easy to add/remove components
- **Documentation**: Comprehensive guides for each component
- **Testing**: Safe deployment with rollback capabilities
- **Version control**: Full history and change tracking

## 📋 Application Configurations

### AwesomeWM (X11 Window Manager)
- **File**: `private_dot_config/awesome/rc.lua`
- **Features**: Tiling layout, custom widgets, vim-style navigation
- **Theme**: Catppuccin Macchiato with custom styling
- **Keybindings**: Identical to Hyprland for consistency

### Hyprland (Wayland Compositor)
- **File**: `private_dot_config/hypr/hyprland.conf`
- **Features**: Modern wayland compositor with animations
- **Effects**: Blur, rounded corners, smooth transitions
- **Integration**: Native Waybar support

### Kitty Terminal
- **File**: `private_dot_config/kitty/kitty.conf`
- **Features**: GPU acceleration, ligatures, multiple tabs
- **Themes**: Full Catppuccin theme collection
- **Performance**: Optimized for speed and responsiveness

### Neovim Editor
- **File**: `private_dot_config/nvim/init.lua`
- **Features**: LSP, autocompletion, Git integration, AI assistance
- **Plugins**: Carefully curated plugin ecosystem
- **Performance**: Lazy loading for fast startup

### Zellij Multiplexer
- **File**: `private_dot_config/zellij/config.kdl`
- **Features**: Modern terminal multiplexer with layouts
- **Integration**: Seamless with terminal workflow
- **Theming**: Matches overall color scheme

## 🛠️ System Requirements

### Minimum Requirements
- Linux distribution with systemd
- Git for version control
- Curl for installation scripts

### Recommended for Full Features
- NixOS (for system configuration management)
- Wayland support (for Hyprland)
- X11 support (for AwesomeWM fallback)
- Modern GPU (for compositor effects)

### Package Dependencies
Most dependencies are automatically managed through:
- NixOS system configuration
- Application-specific package lists
- Automated installation scripts

## 🆘 Troubleshooting

### Common Issues

**Chezmoi not applying changes:**
```bash
# Check for conflicts
chezmoi diff
# Force apply
chezmoi apply --force
```

**NixOS deployment fails:**
```bash
# Check syntax
sudo nixos-rebuild dry-build
# Restore from backup
sudo cp /tmp/nixos-backup-TIMESTAMP/* /etc/nixos/
```

**Missing applications:**
```bash
# Install missing dependencies
cd ~/.config/awesome && ./install-packages.sh
```

**Theme not applying:**
```bash
# Clear cache and reapply
rm -rf ~/.cache/chezmoi
chezmoi apply
```

### Getting Help
1. Check application-specific README files
2. Review configuration syntax
3. Test changes in isolation
4. Use backup and rollback features

## 🔄 Updates & Maintenance

### Regular Maintenance
```bash
# Update dotfiles
chezmoi update

# Upgrade system (NixOS)
sudo nixos-rebuild switch --upgrade

# Update flake dependencies
cd ~/.local/share/chezmoi && nix flake update
```

### Adding New Configurations
```bash
# Add new dotfile
chezmoi add ~/.config/newapp/config

# Edit and customize
chezmoi edit ~/.config/newapp/config

# Apply changes
chezmoi apply
```

## 🤖 AI Integration

This dotfiles repository includes Claude AI integration for:
- **Automated documentation**: Keep docs up-to-date with changes
- **Configuration assistance**: Help with complex setups
- **Maintenance tasks**: Automate common operations
- **Troubleshooting**: Intelligent problem solving

### Claude Configuration
- **Global instructions**: Stored in `dot_claude/CLAUDE.md`
- **Context awareness**: Understands repository structure
- **Safe operations**: Follows security best practices
- **Documentation updates**: Automatically maintains accuracy

## 📊 Statistics

- **Total configurations**: 15+ applications
- **Themes supported**: Unified Catppuccin across all apps
- **Platforms**: NixOS, Arch Linux, Ubuntu compatible
- **Update frequency**: Continuously maintained
- **Backup strategy**: Automatic with rollback support

## 🏗️ Architecture

### Configuration Philosophy
1. **Reproducibility**: Same setup on any compatible system
2. **Modularity**: Independent components that work together
3. **Security**: Private data protection and safe defaults
4. **Performance**: Optimized for speed and efficiency
5. **Maintainability**: Easy to update and extend

### Technology Stack
- **Management**: Chezmoi for templating and deployment
- **Version Control**: Git with conventional commits
- **System**: NixOS for declarative configuration
- **Testing**: Automated validation and dry-run capabilities
- **AI**: Claude integration for maintenance assistance

---

## 📄 License

This configuration is maintained for personal use. Individual components may have their own licenses.

## 🤝 Contributing

While this is a personal dotfiles repository, suggestions and improvements are welcome through issues and discussions.

---

**Happy configuring!** 🎉