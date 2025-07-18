# Personal Samsung Galaxy Book Configuration
# Hardware: SAMSUNG ELECTRONICS CO., LTD. NP930QCG-K01US
# Environment: Personal laptop with full development setup

{ config, pkgs, claude-desktop-linux-flake, ... }:
let
  gemini-cli = pkgs.callPackage ./gemini-cli.nix {};
in
{
  imports = [
    # Shared system configuration (common settings, base packages, etc.)
    ./machines/shared/system-common.nix
    # Hardware-specific audio fix
    ./machines/shared/hardware/samsung-galaxy-book-audio.nix
    # Base hardware scan
    ./hardware-configuration.nix
  ];

  # Machine-specific configuration
  networking.hostName = "samsung-laptop-personal";
  
  # Personal laptop uses DHCP (simple networking)
  networking.networkmanager.enable = true;
  
  # Personal-specific packages (additions to the base set from system-common.nix)
  environment.systemPackages = with pkgs; [
    # Personal development and creative tools
    discord
    obsidian
    google-chrome
    
    # Creative and productivity apps (personal setup)
    shotwell
    bambu-studio
    libsForQt5.okular
    realvnc-vnc-viewer
    iwd
    zellij
    libreoffice-qt
    inkscape
    libei
    
    # AI and specialized tools (personal environment)
    claude-desktop-linux-flake.packages.${pkgs.system}.claude-desktop
    claude-code
    pulsemixer
    
    # Hash generation tools for package maintenance
    nix-prefetch-git
    nix-prefetch-github
  ];
}