# Personal Samsung Galaxy Book Configuration
# Hardware: SAMSUNG ELECTRONICS CO., LTD. NP930QCG-K01US
# Environment: Personal laptop with full development setup

{ config, pkgs, claude-desktop-linux-flake, ... }:
let
  # gemini-cli = pkgs.callPackage ./gemini-cli.nix {};  # Commented out - using nixpkgs version instead
in
{
  imports = [
    # Shared system configuration (common settings, base packages, etc.)
    ./machines/shared/system-common.nix
    # Base hardware scan
    ./hardware-configuration.nix
  ];

  # Machine-specific configuration
  networking.hostName = "beelink-ser8-desktop";
  
  # Personal laptop uses DHCP (simple networking)
  networking.networkmanager.enable = true;
  
   # Add this block to override the default kernel with version 6.6
  nixpkgs.overlays = [
    (self: super: {
      # Use the known working kernel package
      linuxPackages = super.linuxPackages_6_6;
    })
  ];
  
  # # Personal-specific packages (additions to the base set from system-common.nix)
  # environment.systemPackages = with pkgs; [
  #   # Personal development and creative tools
  #   discord
  #   obsidian
  #   google-chrome
    
  #   # Creative and productivity apps (personal setup)
  #   shotwell
  #   bambu-studio
  #   libsForQt5.okular
  #   realvnc-vnc-viewer
  #   iwd
  #   zellij
  #   libreoffice-qt
  #   inkscape
  #   libei
    


  #   # PulseAudio volume control
  #   pulsemixer
    
  #   # Hash generation tools for package maintenance
  #   nix-prefetch-git
  #   nix-prefetch-github
  # ];
}
