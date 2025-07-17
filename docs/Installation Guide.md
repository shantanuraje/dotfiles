# Personal Dotfiles Configuration

> A comprehensive, well-organized dotfiles repository managed with [chezmoi](https://chezmoi.io/) for consistent development environment across systems.

## 🚀 Quick Start

```bash
# Install dotfiles
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply https://github.com/your-username/dotfiles

# Or if already cloned
chezmoi init && chezmoi apply
```

## ✨ Key Features

### 🎨 **Modern Polybar Status Bar**
- **Catppuccin Macchiato** theme with modern aesthetics
- **Interactive Calendar & Clock** - Left/middle/right click for different views
- **Enhanced Window Management** - Restore minimized windows across workspaces
- **System Monitoring** - CPU, memory, temperature, network, and more
- **AwesomeWM Integration** - Seamless workspace management

### 🖥️ **System Integration**
- **NixOS Configuration** - Declarative system management
- **Hardware Fixes** - Samsung Galaxy Book audio fixes
- **Cross-Platform Planning** - Universal Linux system management
- **Automated Deployment** - Safe, tested deployment scripts

### 🛠️ **Development Tools**
- **Chezmoi Management** - Version-controlled dotfiles
- **AI-Assisted Development** - Claude integration for maintenance
- **Comprehensive Documentation** - Well-organized reference system
- **Multiple Environments** - Home, work, and mobile configurations

## 📁 Repository Structure

```
~/.local/share/chezmoi/
├── docs/                        # 📚 Comprehensive documentation
│   ├── README.md               # Main documentation index (MOC)
│   ├── polybar/                # Polybar-specific documentation
│   ├── system/                 # System configuration guides
│   └── project/                # Project management docs
├── private_dot_config/         # 🔧 Application configurations
│   ├── polybar/               # Modern status bar setup
│   ├── awesome/               # AwesomeWM window manager
│   ├── nvim/                  # Neovim editor config
│   ├── kitty/                 # Terminal emulator
│   └── rofi/                  # Application launcher
├── system_nixos/              # 🐧 NixOS system configuration
│   ├── configuration.nix      # Main system config
│   ├── flake.nix             # Nix flake configuration
│   └── machines/             # Machine-specific configs
└── system_scripts/           # 🔧 Automation scripts
    ├── deploy-nixos.sh       # Safe deployment
    └── update-docs.sh        # Documentation maintenance
```

## 🎯 What Makes This Special

### **Polybar Excellence**
- **Interactive Features**: Click calendar for popups, window manager for restoration
- **Beautiful Design**: Modern icons, proper spacing, consistent theming
- **Practical Functionality**: Real system monitoring, workspace management
- **Seamless Integration**: Perfect AwesomeWM integration with no conflicts

### **System Reliability**
- **Safe Deployments**: Automated testing and rollback capabilities
- **Hardware Support**: Tested on Samsung Galaxy Book with audio fixes
- **Documentation First**: Every feature is documented and maintained
- **AI Integration**: Claude assists with development and maintenance

### **Cross-Platform Vision**
- **Universal Goal**: Planning cross-distribution compatibility
- **Modular Design**: Components can be adapted to different systems
- **Best Practices**: Follows established dotfiles management patterns
- **Community Ready**: Well-documented for sharing and contribution

## 📖 Documentation

The documentation is organized as an **Obsidian MOC (Map of Contents)** in the `docs/` directory:

- **[[docs/README.md]]** - Main documentation index
- **[[docs/polybar/]]** - Polybar system documentation
- **[[docs/system/]]** - System configuration guides  
- **[[docs/project/]]** - Project management and development

## 🔧 Quick Commands

```bash
# Deploy system changes
./system_scripts/deploy-nixos.sh

# Update documentation
./system_scripts/update-docs.sh

# Apply dotfiles changes
chezmoi apply

# Test polybar configuration
polybar main -c ~/.config/polybar/config.ini
```

## 🏆 Recent Achievements

- ✅ **Enhanced Calendar System** - Interactive calendar popups with rofi
- ✅ **Window Management** - Robust window restoration across workspaces  
- ✅ **Documentation Overhaul** - Organized MOC-style documentation system
- ✅ **AI Integration** - Claude-assisted development and maintenance
- ✅ **Hardware Support** - Samsung Galaxy Book audio fixes

## 🔮 Future Plans

- 🎯 **Universal Linux Support** - Cross-distribution compatibility
- 🎨 **Enhanced Theming** - More customization options
- 📱 **Mobile Integration** - Termux and mobile-friendly configurations
- 🤖 **AI Enhancement** - Improved AI-assisted management

## 🤝 Contributing

This is a personal dotfiles repository, but the documentation and structure can serve as inspiration for your own setup. See [[docs/project/Contributing.md]] for more information.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**💡 Tip**: Start with the [[docs/README.md]] file for comprehensive navigation and documentation.

*Last Updated: July 17, 2025*
