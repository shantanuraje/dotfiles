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
  
  # Beelink-specific packages
  environment.systemPackages = with pkgs; [
    # VNC server for remote access
    x11vnc
  ];
  
  # VNC Server configuration (x11vnc)
  # Note: x11vnc shares your existing X11 session, not a separate virtual desktop
  # The VNC server is started automatically by AwesomeWM in rc.lua
  # 
  # To set up a VNC password:
  #   x11vnc -storepasswd ~/.vnc/passwd
  #
  # Default configuration in AwesomeWM rc.lua:
  #   Port: 5901
  #   Localhost only (requires SSH tunnel for remote access)
  #   Auth: ~/.vnc/passwd
  #
  # For remote access, use SSH tunnel:
  #   ssh -L 5901:localhost:5901 user@beelink-ser8-desktop
  #   Then connect VNC viewer to localhost:5901

  # Open firewall port for VNC (for LAN access)
  networking.firewall.allowedTCPPorts = [ 5901 ];
  
  # Custom iptables rule for VNC (alternative approach)
  # This creates the exact iptables rule you specified
  # networking.firewall.extraCommands = ''
  #   iptables -I nixos-fw -p tcp --dport 5901 -j nixos-fw-accept
  # '';
  
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
