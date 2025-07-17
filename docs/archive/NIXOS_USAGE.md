# NixOS Configuration Management

Your NixOS system configuration is now managed alongside your dotfiles in chezmoi.

## 📁 Structure

```
~/.local/share/chezmoi/
├── system_nixos/                    # NixOS configuration files
│   ├── machines/                   # Machine-specific configurations
│   │   ├── home.nix               # Home workstation config
│   │   ├── work.nix               # Work workstation config  
│   │   ├── home_modular.nix       # (Future: modular home config)
│   │   └── work_modular.nix       # (Future: modular work config)
│   ├── configuration.nix           # Current/legacy main config
│   ├── flake.nix                   # Nix flake configuration
│   ├── flake.lock                  # Flake lock file
│   ├── hardware-configuration.nix  # Hardware-specific settings
│   └── gemini-cli.nix              # Custom module
├── system_scripts/
│   ├── deploy-nixos.sh             # Machine-selective deployment
│   └── test-deploy-nixos.sh        # Machine-selective testing
└── ... (your dotfiles)
```

## 🚀 Multi-Machine Workflow

### 1. Edit Machine-Specific Configuration
```bash
# Edit home machine configuration
chezmoi edit system_nixos/machines/home.nix

# Edit work machine configuration  
chezmoi edit system_nixos/machines/work.nix

# Or edit directly
nvim ~/.local/share/chezmoi/system_nixos/machines/home.nix
nvim ~/.local/share/chezmoi/system_nixos/machines/work.nix
```

### 2. Test Changes (Recommended)
```bash
# Test deployment with machine selection
~/.local/share/chezmoi/system_scripts/test-deploy-nixos.sh
```
*Script will prompt you to select which machine configuration to test*

### 3. Deploy Changes
```bash
# Deploy with machine selection (recommended)
~/.local/share/chezmoi/system_scripts/deploy-nixos.sh
```
*Script will prompt you to select which machine configuration to deploy*

**How it works:**
- Selected machine config is copied as `configuration.nix` to `/etc/nixos/`
- Other shared files (flake.nix, gemini-cli.nix, etc.) are copied normally
- System rebuilds using the selected configuration

### 4. Commit Changes
```bash
chezmoi cd
git add system_nixos/
git commit -m "update nixos configuration"
git push
```

## 🛠️ Modern CLI Tools

The system includes modern alternatives to traditional Unix tools for enhanced productivity:

### File Operations
- **`bat`** - Cat clone with syntax highlighting and Git integration
- **`eza`** - Modern ls replacement with better formatting and icons  
- **`fd`** - Simple, fast alternative to find
- **`dust`** - Better du alternative with visual disk usage

### Text Processing & Search
- **`ripgrep` (rg)** - Fast text search (already configured)
- **`tldr`** - Simplified man pages with practical examples

### Git Operations
- **`delta`** - Syntax-highlighting pager for git diffs

### System Monitoring  
- **`bottom`** - Cross-platform graphical process/system monitor

### Development Tools
- **`tokei`** - Count your code quickly
- **`hyperfine`** - Command-line benchmarking tool

These tools are automatically available after deployment and provide better UX than traditional alternatives.

## 🏠 Machine Configurations

### Home Machine (`machines/home.nix`)
- **Networking**: DHCP (automatic)
- **Desktop**: Full multi-environment (Hyprland + AwesomeWM + GNOME)
- **Packages**: Complete development environment with all tools
- **Features**: 
  - Android development (ADB)
  - AI tools (Claude, Gemini CLI)
  - Creative tools (GIMP, Bambu Studio)
  - Modern CLI tools
  - Python development stack

### Work Machine (`machines/work.nix`)  
- **Networking**: Static IP (192.168.2.2/24) 
- **Desktop**: Same as home (Hyprland + AwesomeWM + GNOME)
- **Packages**: Same as home + work-specific tools
- **Security**: Auto-login disabled
- **Hardware**: RealSense camera support with udev rules
- **Features**: All home features + office-specific requirements

### Future Modular Configs
- **`home_modular.nix`** - Modular version for easier maintenance
- **`work_modular.nix`** - Modular version with shared components

## 🛡️ Safety Features

- **Automatic backups**: Each deployment creates `/tmp/nixos-backup-TIMESTAMP`
- **Validation**: Configuration is validated before applying
- **Rollback**: Failed deployments restore from backup
- **Version control**: All changes tracked in git

## 🔧 Useful Aliases

Add these to your `.bashrc`:
```bash
alias nixos-edit='chezmoi edit system_nixos/configuration.nix'
alias nixos-deploy='~/.local/share/chezmoi/system_scripts/deploy-nixos.sh'
alias nixos-commit='chezmoi cd && git add system_nixos/ && git commit'
```

## 🆘 Troubleshooting

**Deployment fails:**
- Check error message in terminal
- Backup is automatically restored
- Fix configuration and try again

**Files out of sync:**
```bash
# Check differences
sudo diff -r /etc/nixos/ ~/.local/share/chezmoi/system_nixos/

# Update chezmoi source from /etc/nixos
sudo cp /etc/nixos/* ~/.local/share/chezmoi/system_nixos/
```

**Emergency restore:**
```bash
# List available backups
ls -la /tmp/nixos-backup-*

# Restore from backup
sudo cp /tmp/nixos-backup-TIMESTAMP/* /etc/nixos/
sudo nixos-rebuild switch
```

## 📋 Quick Commands

```bash
# Edit configuration
chezmoi edit system_nixos/configuration.nix

# Deploy changes  
~/.local/share/chezmoi/system_scripts/deploy-nixos.sh

# Test configuration
sudo nixos-rebuild dry-build

# Emergency rollback
sudo nixos-rebuild switch --rollback
```