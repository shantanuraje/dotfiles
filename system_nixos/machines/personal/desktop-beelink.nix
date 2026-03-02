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

    # Fix noto-fonts-subset build failure in libreoffice (nixpkgs#495219)
    # Upstream fix: PR#494721 (on master, not yet on nixos-unstable)
    # Remove this overlay once nixpkgs channel includes commit b097075bf24c
    (final: prev: {
      libreoffice-qt = prev.libreoffice-qt-fresh;
    })

    # Obsidian 1.12.4 with CLI support fix
    # Upstream nixpkgs blocked on #489339: Wayland flags conflict with new CLI parser
    # This overlay bumps version and fixes the wrapper to handle both GUI and CLI modes
    (final: prev: {
      obsidian = prev.obsidian.overrideAttrs (old: rec {
        version = "1.12.4";
        src = prev.fetchurl {
          url = "https://github.com/obsidianmd/obsidian-releases/releases/download/v${version}/obsidian-${version}.tar.gz";
          hash = "sha256-cusm388SP44HvoCD90+gRfQAxx7B/mTlirkdnMCEyN4=";
        };
        installPhase =
          let
            electron = prev.electron;
            commandLineArgs = "";
          in
          ''
            runHook preInstall
            mkdir -p $out/bin

            # Custom wrapper that conditionally applies Wayland flags
            # Obsidian 1.12+ has a CLI parser that intercepts --ozone-platform as a command
            # Only pass Wayland/Electron flags when launching in GUI mode (no subcommands)
            cat > $out/bin/obsidian <<'WRAPPER'
            #!/usr/bin/env bash
            CLI_MODE=false
            for arg in "$@"; do
              case "$arg" in
                --help|--version) ;;  # flags, not subcommands
                -*) ;;                # other flags
                *) CLI_MODE=true; break ;;  # first positional arg = subcommand
              esac
            done

            WAYLAND_FLAGS=""
            if [ "$CLI_MODE" = "false" ] && [ -n "''${NIXOS_OZONE_WL:-}" ] && [ -n "''${WAYLAND_DISPLAY:-}" ]; then
              WAYLAND_FLAGS="--ozone-platform=wayland --enable-wayland-ime=true --wayland-text-input-version=3"
            fi

            exec "${electron}/bin/electron" $out/share/obsidian/app.asar $WAYLAND_FLAGS ${commandLineArgs} "$@"
            WRAPPER
            # Fix: replace $out with actual store path in the wrapper
            sed -i "s|\$out|$out|g" $out/bin/obsidian
            chmod +x $out/bin/obsidian

            install -m 444 -D resources/app.asar $out/share/obsidian/app.asar
            install -m 444 -D resources/obsidian.asar $out/share/obsidian/obsidian.asar
            install -m 444 -D "${old.desktopItem}/share/applications/"* \
              -t $out/share/applications/
            for size in 16 24 32 48 64 128 256 512; do
              mkdir -p $out/share/icons/hicolor/"$size"x"$size"/apps
              magick -background none ${old.icon} -resize "$size"x"$size" $out/share/icons/hicolor/"$size"x"$size"/apps/obsidian.png
            done
            runHook postInstall
          '';
      });
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
