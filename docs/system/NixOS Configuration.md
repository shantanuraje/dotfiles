# NixOS Configuration

> Declarative system configuration with comprehensive hardware support

## 🎯 Overview

The NixOS configuration provides a declarative, reproducible system setup with machine-specific configurations, hardware fixes, and comprehensive package management using Nix flakes.

## ✨ Key Features

### 🏗️ **Declarative Configuration**
- **Single Source of Truth** - All system configuration in `configuration.nix`
- **Reproducible Builds** - Identical systems from same configuration
- **Atomic Updates** - Safe system updates with rollback capability
- **Version Control** - Git-managed system configuration

### 🖥️ **Machine-Specific Support**
- **Home Configuration** - Personal desktop setup
- **Work Configuration** - Professional environment
- **Samsung Galaxy Book** - Hardware-specific fixes and optimizations
- **Modular Design** - Shared and machine-specific modules

### 🔧 **Hardware Integration**
- **Audio Fixes** - Samsung Galaxy Book audio driver fixes
- **Display Management** - Screen layout configuration
- **Power Management** - Laptop-specific power optimizations
- **Input Devices** - Keyboard and touchpad configuration
- **Remote Access** - VNC server configuration for Beelink system

## 🗂️ Configuration Structure

```
system_nixos/
├── configuration.nix             # Main system configuration
├── flake.nix                    # Nix flake configuration
├── flake.lock                   # Dependency lockfile
├── gemini-cli.nix              # Gemini CLI configuration
└── machines/
    ├── home.nix                # Home machine configuration
    ├── work.nix                # Work machine configuration
    ├── home_modular.nix        # Modular home configuration
    ├── work_modular.nix        # Modular work configuration
    ├── personal/               # Personal machine modules
    ├── shared/                 # Shared configuration modules
    └── work/                   # Work-specific modules
```

## 🎮 Machine Detection

### **Automatic Detection**
```bash
# Auto-detect machine type
./system_scripts/auto-detect-machine.sh

# Deploy with auto-detection
./system_scripts/deploy-nixos.sh
```

### **Manual Configuration**
```bash
# Home machine
sudo nixos-rebuild switch --flake .#home

# Work machine
sudo nixos-rebuild switch --flake .#work
```

## 🔧 Core Components

### **Base System**
```nix
# Core system packages
environment.systemPackages = with pkgs; [
  # Essential tools
  git chezmoi curl wget
  
  # Development
  neovim code-server
  
  # Desktop environment
  awesome rofi polybar
  
  # Terminal and utilities
  kitty alacritty tmux
];
```

### **Hardware Configuration**
```nix
# Hardware-specific settings
hardware = {
  # Audio fixes for Samsung Galaxy Book
  pulseaudio.enable = true;
  
  # Graphics support
  opengl.enable = true;
  
  # Power management
  acpilight.enable = true;
};
```

### **Services Configuration**
```nix
services = {
  # Display manager
  xserver = {
    enable = true;
    displayManager.lightdm.enable = true;
    windowManager.awesome.enable = true;
  };
  
  # Audio
  pipewire.enable = true;
  
  # Network
  networkmanager.enable = true;
};
```

## 🎨 Desktop Environment

### **AwesomeWM Configuration**
- **Window Manager** - Tiling window manager with custom config
- **Polybar Integration** - Modern status bar replacing wibar
- **Rofi Launcher** - Application launcher and menu system
- **Catppuccin Theme** - Consistent theming across all applications

### **Terminal Setup**
- **Kitty** - Primary terminal emulator with GPU acceleration
- **Alacritty** - Alternative terminal with minimal configuration
- **Shell** - Bash with custom aliases and functions
- **Font** - JetBrains Mono Nerd Font for icon support

## 🔧 Hardware Fixes

### **Samsung Galaxy Book Audio Fix**
```nix
# Audio driver fixes
boot.extraModprobeConfig = ''
  options snd-hda-intel model=dell-headset-multi
'';

# HDA verb commands for audio routing
systemd.services.samsung-audio-fix = {
  description = "Samsung Galaxy Book Audio Fix";
  after = [ "sound.target" ];
  script = ''
    # 200+ HDA verb commands for proper audio routing
    ${pkgs.alsa-utils}/bin/hda-verb /dev/snd/hwC0D0 0x20 0x500 0x2b
    # ... additional commands
  '';
};
```

### **Display Configuration**
```nix
# Multiple monitor support
services.xserver.displayManager.sessionCommands = ''
  ${pkgs.xorg.xrandr}/bin/xrandr --output HDMI-1 --auto --primary
  ${pkgs.xorg.xrandr}/bin/xrandr --output eDP-1 --auto --right-of HDMI-1
'';
```

## 🚀 Deployment

### **Safe Deployment Script**
```bash
#!/bin/bash
# deploy-nixos.sh

# Pre-deployment checks
echo "🔍 Running pre-deployment checks..."
./system_scripts/get-system-info.sh

# Test configuration
echo "🧪 Testing configuration..."
sudo nixos-rebuild dry-build --flake .#$(hostname)

# Deploy with backup
echo "🚀 Deploying system..."
sudo nixos-rebuild switch --flake .#$(hostname)
```

### **Rollback Capability**
```bash
# List available generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rollback to previous generation
sudo nixos-rebuild switch --rollback
```

## 📊 Package Management

### **Nix Flakes**
```nix
{
  description = "Personal NixOS configuration";
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
  };
  
  outputs = { self, nixpkgs, home-manager }: {
    nixosConfigurations = {
      home = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./machines/home.nix ];
      };
    };
  };
}
```

### **Custom Packages**
```nix
# Custom package definitions
environment.systemPackages = with pkgs; [
  # Custom gemini-cli package
  (callPackage ./gemini-cli.nix {})
  
  # Development tools
  nodejs yarn python3
  
  # System utilities
  htop btop neofetch
];
```

## 🛠️ Maintenance

### **Update System**
```bash
# Update flake inputs
nix flake update

# Rebuild and switch
sudo nixos-rebuild switch --flake .#$(hostname)

# Clean old generations
sudo nix-collect-garbage -d
```

### **System Information**
```bash
# Get system info
./system_scripts/get-system-info.sh

# Check hardware
lshw -short
```

## 🔍 Troubleshooting

### **Common Issues**

#### **Build Failures**
- **Cause** - Dependency conflicts or missing packages
- **Solution** - Check flake.lock and update inputs
- **Debug** - Use `nix-build` for detailed error messages

#### **Audio Not Working**
- **Cause** - Missing or incorrect audio drivers
- **Solution** - Check Samsung audio fix service status
- **Debug** - `systemctl status samsung-audio-fix`

#### **Display Issues**
- **Cause** - Monitor configuration or driver problems
- **Solution** - Check xrandr commands and display scripts
- **Debug** - Test display scripts manually

### **Debug Commands**
```bash
# Check system status
systemctl status

# Hardware info
lshw -short

# Audio debugging
aplay -l && amixer

# Display debugging
xrandr --verbose
```

## 🔮 Future Enhancements

### **Planned Features**
- **Home Manager Integration** - User-level package management
- **Secrets Management** - Encrypted configuration secrets
- **Cross-Platform Support** - Non-NixOS compatibility
- **Automated Testing** - CI/CD for configuration changes

### **System Improvements**
- **Performance Optimization** - System tuning and optimization
- **Security Hardening** - Enhanced security configuration
- **Backup System** - Automated system backup
- **Monitoring** - System health monitoring

## 🔗 Related Documentation

- **[[Hardware Fixes]]** - Hardware-specific fixes and drivers
- **[[System Scripts]]** - Automation and utility scripts
- **[[VNC_Setup.md]]** - VNC server setup for remote access
- **[[../polybar/Polybar Overview]]** - Desktop environment setup
- **[[../project/Development Progress]]** - Current development status

---

*The NixOS configuration provides a robust, declarative system setup with comprehensive hardware support and safe deployment practices.*
