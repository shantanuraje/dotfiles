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
    # ntfy action-button webhook receiver (port 9099 on tailnet)
    ./notify-webhook.nix
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
        version = "1.12.7";
        src = prev.fetchurl {
          url = "https://github.com/obsidianmd/obsidian-releases/releases/download/v${version}/obsidian-${version}.tar.gz";
          hash = "sha256-/L4IsRHZwf2wm5wIlSsG4cgpxiFj66JYTEtOyFm+B50=";
        };
        installPhase =
          let
            electron = prev.electron;
            # Tell Electron's safeStorage to use libsecret (gnome-keyring) instead of
            # the default "basic" plaintext backend. Without this, the Obsidian
            # Keychain plugin reports "encryption not available" even though
            # gnome-keyring-daemon is running and org.freedesktop.secrets is on D-Bus.
            commandLineArgs = "--password-store=gnome-libsecret";
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

  # ──────────────────────────────────────────────────────────────────────
  # VNC / noVNC firewall rules
  #
  # Earlier this file had `networking.firewall.allowedTCPPorts = [ 5901 ]`,
  # which was interface- and address-family-agnostic. Because this host has
  # globally-routable IPv6 addresses on enp1s0/wlp2s0 and x11vnc binds dual
  # stack, that rule exposed 5901 to the public internet via IPv6. Confirmed
  # via audit on 2026-04-26 (see docs/system/VNC_Setup.md). The rule below
  # restricts LAN access to the IPv4 LAN subnet only and leaves IPv6
  # untouched (no extraCommandsForIPv6 → no IPv6 firewall opening). Tailnet
  # access is provided separately on `tailscale0` in system-common.nix.
  # ──────────────────────────────────────────────────────────────────────
  networking.firewall.extraCommands = ''
    # Allow x11vnc (5901) and noVNC (6080) from local LAN (IPv4 only)
    iptables -I nixos-fw -p tcp -s 192.168.1.0/24 --dport 5901 -j nixos-fw-accept
    iptables -I nixos-fw -p tcp -s 192.168.1.0/24 --dport 6080 -j nixos-fw-accept
  '';
  networking.firewall.extraStopCommands = ''
    iptables -D nixos-fw -p tcp -s 192.168.1.0/24 --dport 5901 -j nixos-fw-accept 2>/dev/null || true
    iptables -D nixos-fw -p tcp -s 192.168.1.0/24 --dport 6080 -j nixos-fw-accept 2>/dev/null || true
  '';

  # ──────────────────────────────────────────────────────────────────────
  # noVNC — browser-based VNC client (HTML5/WebSocket → x11vnc on :5901)
  # Reach at http://beelink-ser8-desktop:6080/vnc.html from tailnet or LAN.
  # Auth is the same VNC password as ~/.vnc/passwd (websockify is a dumb
  # proxy; the noVNC client speaks the RFB handshake end-to-end with x11vnc).
  # ──────────────────────────────────────────────────────────────────────
  systemd.services.novnc = {
    description = "noVNC — websockify proxy serving noVNC HTML to x11vnc :5901";
    after = [ "x11vnc.service" "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.python3Packages.websockify}/bin/websockify --web=${pkgs.novnc}/share/webapps/novnc 6080 127.0.0.1:5901";
      Restart = "on-failure";
      RestartSec = "5s";
      DynamicUser = true;
    };
  };
  
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

  # ntfy-sh self-hosted notification server
  # Exposed on tailnet only (port opened in services.tailscale firewall block above
  # via system-common.nix list merge). Reach at http://beelink-ser8-desktop:8090
  # from any tailnet device. No auth/TLS — tailnet ACLs are the access boundary.
  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "http://beelink-ser8-desktop:8090";
      listen-http = ":8090";
      behind-proxy = false;
      cache-file = "/var/lib/ntfy-sh/cache.db";
      cache-duration = "12h";
      attachment-cache-dir = "/var/lib/ntfy-sh/attachments";
      # Expose /metrics endpoint (Prometheus format) — counters for topics,
      # subscribers, messages. Lights up the "Metrics" panel in the web/app
      # dashboard. Doesn't expose message contents, just aggregate counters.
      enable-metrics = true;
      # auth-default-access defaults to "read-write" (open). Tailnet ACLs are
      # the access boundary. To tighten: set "deny-all" and `ntfy user add`.
    };
  };

  # (CLI is installed by the ntfy-sh module itself — `ntfy` available system-wide.)

  # Tailnet ports opened on this host (merges with system-common.nix list).
  # 8090 = ntfy-sh, 6080 = noVNC websockify proxy.
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 8090 6080 ];
}
