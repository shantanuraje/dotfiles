# Required Packages for AwesomeWM Setup

## Core Dependencies
- awesome (window manager)
- kitty (terminal - already installed)
- rofi (application launcher - already installed)
- dolphin (file manager - already installed)

## Status Bar & Widgets
- lain (awesome widgets library)
- vicious (system monitoring widgets)

## Theming & Visual
- picom (compositor for shadows/transparency/blur)
- feh (wallpaper setting)
- papirus-icon-theme (icons)

## System Integration  
- playerctl (media controls)
- brightnessctl (brightness control)
- pamixer or pulseaudio-utils (volume control)
- acpi (battery info)
- lm_sensors (temperature monitoring)

## Notifications
- notify-send/libnotify (notifications)

## Fonts
- ttf-codenewroman-nerd (already using this font)
- noto-fonts-emoji

## Optional Enhancements
- redshift (blue light filter)
- xorg-xwininfo (window info)
- xorg-xprop (window properties)

## Installation Commands (NixOS)
Add to your configuration.nix:

```nix
environment.systemPackages = with pkgs; [
  awesome
  picom
  feh
  papirus-icon-theme
  playerctl
  brightnessctl
  pamixer
  acpi
  lm_sensors
  libnotify
  noto-fonts-emoji
  redshift
  xorg.xwininfo
  xorg.xprop
];

# Enable X11 and AwesomeWM
services.xserver = {
  enable = true;
  windowManager.awesome = {
    enable = true;
    luaModules = with pkgs.luaPackages; [
      luarocks
    ];
  };
};
```

**Note**: `lain` and `vicious` are not in nixpkgs but are already included in your ~/.config/awesome/ directory.