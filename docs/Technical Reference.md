# Technical Reference

This document provides technical details and reference information for the dotfiles project components.

## 🗂️ Configuration Files Reference

### Core System Files

| File | Purpose | Location |
|------|---------|----------|
| `private_dot_bashrc` | Bash shell configuration | `~/.bashrc` |
| `dot_bash_aliases` | Command aliases | `~/.bash_aliases` |
| `dot_profile` | Shell environment variables | `~/.profile` |
| `dot_vimrc` | Vim editor configuration | `~/.vimrc` |
| `dot_ripgreprc` | Ripgrep search configuration | `~/.ripgreprc` |

### Application Configurations

| Application | Config Location | Key Features |
|-------------|-----------------|--------------|
| AwesomeWM | `private_dot_config/awesome/` | Window management, keybindings |
| Hyprland | `private_dot_config/hypr/` | Wayland compositor |
| Kitty | `private_dot_config/kitty/` | Terminal emulator |
| Polybar | `private_dot_config/polybar/` | Status bar |
| Rofi | `private_dot_config/rofi/` | Application launcher |
| Neovim | `private_dot_config/nvim/` | Text editor |
| Zellij | `private_dot_config/zellij/` | Terminal multiplexer |

## 🎨 Theme System

### Catppuccin Macchiato Colors
```
Base:        #24273a
Mantle:      #1e2030
Crust:       #181926
Text:        #cad3f5
Subtext1:    #b8c0e0
Subtext0:    #a5adcb
Overlay2:    #939ab7
Overlay1:    #8087a2
Overlay0:    #6e738d
Surface2:    #5b6078
Surface1:    #494d64
Surface0:    #363a4f
Blue:        #8aadf4
Lavender:    #b7bdf8
Sapphire:    #7dc4e4
Sky:         #91d7e3
Teal:        #8bd5ca
Green:       #a6da95
Yellow:      #eed49f
Peach:       #f5a97f
Maroon:      #ee99a0
Red:         #ed8796
Mauve:       #c6a0f6
Pink:        #f5bde6
```

### Font Configuration
- **Primary**: JetBrains Mono Nerd Font
- **Fallback**: Noto Sans, Font Awesome
- **Terminal**: JetBrains Mono (14pt)
- **UI**: JetBrains Mono (12pt)

## 🖥️ Window Management

### AwesomeWM Layout System
```lua
-- Default layouts
awful.layout.layouts = {
    awful.layout.suit.tile,
    awful.layout.suit.floating,
    awful.layout.suit.max,
    awful.layout.suit.magnifier,
}

-- Tag configuration
for i = 1, 10 do
    awful.tag.add(i, {
        layout = awful.layout.layouts[1],
        gap_single_client = false,
        gap = 4,
    })
end
```

### Hyprland Configuration
```ini
# Gaps
gaps_in = 4
gaps_out = 8

# Borders
border_size = 2
col.active_border = rgba(8aadf4ee) rgba(a6da95ee) 45deg
col.inactive_border = rgba(363a4fee)

# Animations
animations {
    enabled = yes
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
}
```

## 🔧 System Integration

### NixOS Configuration Structure
```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager }: {
    nixosConfigurations = {
      personal = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          ./machines/personal/configuration.nix
        ];
      };
    };
  };
}
```

### Chezmoi Integration
```bash
# Template example
{{ if eq .chezmoi.hostname "work-machine" }}
# Work-specific configuration
{{ else }}
# Personal configuration
{{ end }}
```

## 📊 Polybar Modules

### Core Modules
| Module | Function | Dependencies |
|--------|----------|--------------|
| `cpu` | CPU usage monitoring | `sysstat` |
| `memory` | RAM usage display | Built-in |
| `temperature` | Thermal monitoring | `lm-sensors` |
| `filesystem` | Disk usage | Built-in |
| `network` | Network status | `NetworkManager` |
| `battery` | Power management | `upower` |
| `date` | Clock and calendar | Built-in |
| `pulseaudio` | Audio control | `PulseAudio` |

### Custom Scripts
```bash
# Window count script
#!/bin/bash
awesome-client '
local count = 0
for s in screen do
    for _, c in pairs(s.clients) do
        if c.minimized then
            count = count + 1
        end
    end
end
print(count)
'
```

## 🚀 Performance Optimization

### Picom Configuration
```ini
# Shadows
shadow = true;
shadow-radius = 12;
shadow-opacity = 0.75;
shadow-offset-x = -15;
shadow-offset-y = -15;

# Fading
fading = true;
fade-in-step = 0.03;
fade-out-step = 0.03;
fade-delta = 5;

# Transparency
inactive-opacity = 0.95;
active-opacity = 1.0;
frame-opacity = 1.0;

# Blur
blur-background = true;
blur-method = "dual_kawase";
blur-strength = 3;
```

### Optimization Settings
- **Compositor**: Hardware acceleration enabled
- **Fonts**: Preloaded and cached
- **Scripts**: Optimized for minimal resource usage
- **Animations**: Balanced performance and aesthetics

## 🔐 Security Considerations

### Sensitive Information
- Use chezmoi templates for machine-specific data
- Keep API keys and tokens in separate files
- Never commit passwords or personal information
- Use environment variables for sensitive configs

### File Permissions
```bash
# Secure files
chmod 600 ~/.ssh/config
chmod 700 ~/.gnupg/
chmod 600 ~/.netrc

# Executable scripts
chmod +x ~/.local/bin/*
chmod +x ~/.screenlayout/*.sh
```

## 🐛 Troubleshooting

### Common Issues
1. **Polybar not starting**: Check awesome integration
2. **Fonts not loading**: Verify font cache
3. **Rofi themes broken**: Check theme path
4. **Keybindings not working**: Verify awesome config

### Debugging Commands
```bash
# Check awesome configuration
awesome -k

# Test polybar configuration
polybar --config=~/.config/polybar/config.ini example

# Monitor system resources
htop
journalctl -f

# Check font installation
fc-list | grep -i jetbrains
```

## 📋 Version Compatibility

### Supported Versions
- **NixOS**: 23.11+
- **AwesomeWM**: 4.3+
- **Polybar**: 3.6+
- **Hyprland**: 0.35+
- **Kitty**: 0.26+

### Dependencies
```nix
# Required packages
environment.systemPackages = with pkgs; [
  awesome
  polybar
  kitty
  rofi
  picom
  feh
  pulseaudio
  networkmanager
  upower
  lm_sensors
];
```

## 🔄 Maintenance Scripts

### Automated Tasks
```bash
# Update system
sudo nixos-rebuild switch

# Update dotfiles
chezmoi apply

# Clean package cache
nix-collect-garbage -d

# Update font cache
fc-cache -fv
```

---

*This technical reference is maintained alongside the codebase. Update it when making significant changes to the system configuration.*
