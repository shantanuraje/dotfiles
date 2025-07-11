#!/bin/bash
# Installation script for AwesomeWM setup matching Hyprland configuration

echo "Installing AwesomeWM and required packages..."

# Check if we're on NixOS
if command -v nix-env &> /dev/null; then
    echo "Detected NixOS - Installing packages with nix-env..."
    
    # Install packages via nix-env
    nix-env -iA nixpkgs.awesome \
                nixpkgs.picom \
                nixpkgs.feh \
                nixpkgs.playerctl \
                nixpkgs.brightnessctl \
                nixpkgs.pamixer \
                nixpkgs.acpi \
                nixpkgs.lm_sensors \
                nixpkgs.libnotify \
                nixpkgs.papirus-icon-theme \
                nixpkgs.i3lock \
                nixpkgs.scrot \
                nixpkgs.xorg.xwininfo \
                nixpkgs.xorg.xprop
    
    echo "Packages installed via nix-env!"
    echo ""
    echo "For a complete NixOS setup, add these to your configuration.nix:"
    echo ""
    cat << 'EOF'
environment.systemPackages = with pkgs; [
  awesome
  picom
  feh
  playerctl
  brightnessctl
  pamixer
  acpi
  lm_sensors
  libnotify
  papirus-icon-theme
  i3lock
  scrot
  xorg.xwininfo
  xorg.xprop
];

# Enable X11 and set awesome as window manager
services.xserver = {
  enable = true;
  windowManager.awesome = {
    enable = true;
    luaModules = with pkgs.luaPackages; [
      luarocks
    ];
  };
};
EOF
    echo ""
    echo "Note: lain and freedesktop libraries are already installed in ~/.config/awesome/"

elif command -v pacman &> /dev/null; then
    echo "Detected Arch Linux - Installing packages with pacman..."
    
    sudo pacman -S --needed awesome picom feh playerctl brightnessctl pamixer \
                            acpi lm_sensors libnotify papirus-icon-theme \
                            i3lock scrot xorg-xwininfo xorg-xprop
    
    # Install AUR packages if yay is available
    if command -v yay &> /dev/null; then
        yay -S --needed lain-git
    else
        echo "Install 'yay' AUR helper to get lain widgets"
    fi

elif command -v apt &> /dev/null; then
    echo "Detected Debian/Ubuntu - Installing packages with apt..."
    
    sudo apt update
    sudo apt install awesome picom feh playerctl brightnessctl pamixer \
                     acpi lm-sensors libnotify-bin papirus-icon-theme \
                     i3lock scrot x11-utils
    
    echo "Note: You may need to manually install lain widgets from GitHub"

elif command -v dnf &> /dev/null; then
    echo "Detected Fedora - Installing packages with dnf..."
    
    sudo dnf install awesome picom feh playerctl brightnessctl pamixer \
                     acpi lm_sensors libnotify papirus-icon-theme \
                     i3lock scrot xorg-x11-utils
    
    echo "Note: You may need to manually install lain widgets from GitHub"

else
    echo "Unsupported package manager. Please install packages manually:"
    echo "awesome, picom, feh, playerctl, brightnessctl, pamixer"
    echo "acpi, lm_sensors, libnotify, papirus-icon-theme"
    echo "i3lock, scrot, xwininfo, xprop"
fi

echo ""
echo "Installation complete!"
echo ""
echo "To use AwesomeWM:"
echo "1. Log out of your current session"
echo "2. At the login screen, select 'Awesome' as your window manager"
echo "3. Log in"
echo ""
echo "Your AwesomeWM configuration matches your Hyprland setup with:"
echo "- Catppuccin Macchiato theme"
echo "- Same keybindings (Super key as modifier)"
echo "- Blur, shadows, and rounding effects via picom"
echo "- Same applications (kitty, dolphin, rofi)"
echo "- Matching widgets and status bar"