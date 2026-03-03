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
  
  # x11vnc - shares existing X11 session for LAN remote access
  # Starts at boot as a systemd service (available at LightDM login screen)
  # Port: 5901 | Auth: ~/.vnc/passwd
  # To set up password: x11vnc -storepasswd ~/.vnc/passwd
  # LightDM auth file: /var/run/lightdm/root/:0
  systemd.services.x11vnc = {
    description = "x11vnc - shared X11 session VNC server";
    after = [ "display-manager.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = let
        x11vnc-start = pkgs.writeShellScript "x11vnc-start" ''
          AUTH_FILE="/var/run/lightdm/root/:0"

          # Wait up to 30s for LightDM auth file to appear
          for i in $(${pkgs.coreutils}/bin/seq 1 30); do
            [ -f "$AUTH_FILE" ] && break
            ${pkgs.coreutils}/bin/sleep 1
          done

          if [ ! -f "$AUTH_FILE" ]; then
            echo "LightDM auth file not found after 30s" >&2
            exit 1
          fi

          export DISPLAY=:0
          export XAUTHORITY="$AUTH_FILE"
          exec ${pkgs.x11vnc}/bin/x11vnc -display :0 -auth "$AUTH_FILE" -rfbport 5901 -forever -loop -noxdamage -repeat -shared -rfbauth /home/shantanu/.vnc/passwd
        '';
      in "${x11vnc-start}";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

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
