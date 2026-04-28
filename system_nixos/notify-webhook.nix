# Webhook receiver for ntfy action buttons.
#
# Listens on tailnet (port 9099). Authenticates action POSTs via shared
# Bearer token at ~/.config/notify/webhook-token. Dispatches to allowlisted
# actions defined in ~/.config/notify/webhook-actions.yaml.
#
# Token + actions config are NOT in the Nix store (chezmoi-managed in
# ~/.config/notify/, mode 600). The service runs as user `shantanu` so it
# can sudo (with NOPASSWD entries below) and read the user's config dir.

{ config, pkgs, lib, ... }:

let
  notifyPython = pkgs.python3.withPackages (ps: with ps; [ pyyaml ]);
in
{
  systemd.services.notify-webhook = {
    description = "ntfy action-button webhook receiver";
    after = [ "network.target" "ntfy-sh.service" "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      User = "shantanu";
      Group = "users";
      ExecStart = "${notifyPython}/bin/python3 /home/shantanu/.local/share/chezmoi/system_scripts/webhook/server.py";
      Restart = "on-failure";
      RestartSec = "5s";

      # The receiver writes audit logs to ~/.local/state/notify-webhook/
      # and reads tokens/configs from ~/.config/notify/. Both under the
      # user's home, which is protected by ProtectHome=read-only — but we
      # need write access to ~/.local/state. ReadWritePaths grants that.
      ProtectHome = lib.mkDefault "read-only";
      ReadWritePaths = [
        "/home/shantanu/.local/state/notify-webhook"
        "/home/shantanu/.local/state/notify-snooze"
        # Hermes writes ~/.hermes/logs/agent.log when invoked. Without write
        # access here, `hermes-chat` action fails with `Errno 30 Read-only
        # file system`.
        "/home/shantanu/.hermes"
        # Same defensive whitelist for vault writes. The receiver itself
        # doesn't write to the vault, but `process-inbox` and other Claude
        # actions might.
        "/home/shantanu/Documents/personal"
        # ~/.cache for any tool that warms a cache during exec.
        "/home/shantanu/.cache"
      ];

      # Hardening
      NoNewPrivileges = false;  # need to sudo for some actions
      ProtectSystem = "strict";
      PrivateTmp = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      ProtectControlGroups = true;
      RestrictSUIDSGID = true;
      RestrictRealtime = true;

      # Resource limits
      MemoryMax = "256M";
      TasksMax = 64;

      # Logging
      StandardOutput = "journal";
      StandardError = "journal";
    };

    # Make sure state dirs exist before service starts
    preStart = ''
      mkdir -p /home/shantanu/.local/state/notify-webhook
      mkdir -p /home/shantanu/.local/state/notify-snooze
      chown -R shantanu:users /home/shantanu/.local/state/notify-webhook
      chown -R shantanu:users /home/shantanu/.local/state/notify-snooze
    '';

    environment = {
      # Defaults; can override in ~/.config/notify/ if needed
      NTFY_BASE_URL = "http://beelink-ser8-desktop:8090";
      WEBHOOK_BIND_HOST = "100.116.242.38";
      WEBHOOK_BIND_PORT = "9099";
      # Path to find common tools (sudo, systemctl, nix-collect-garbage, claude)
      PATH = lib.mkForce "/run/current-system/sw/bin:/run/wrappers/bin:/home/shantanu/.nix-profile/bin";
    };
  };

  # Tailnet-only access — same pattern as other services
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 9099 ];

  # Narrow sudoers entries for actions that need root.
  # Each entry is locked down to a specific binary + allowed flag.
  security.sudo.extraRules = [
    {
      users = [ "shantanu" ];
      commands = [
        # Garbage collection
        { command = "/run/current-system/sw/bin/nix-collect-garbage -d";  options = [ "NOPASSWD" "SETENV" ]; }
        { command = "/run/current-system/sw/bin/nix-store --optimise";    options = [ "NOPASSWD" ]; }
        # Service restarts (only the specific units we expose as actions)
        { command = "/run/current-system/sw/bin/systemctl restart x11vnc";                   options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/systemctl restart novnc";                    options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/systemctl restart vncserver-x11-serviced";   options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/systemctl restart ntfy-sh";                  options = [ "NOPASSWD" ]; }
        # Restart the receiver itself — needed by deploy-nixos.sh auto-refresh
        # so post-deploy can pick up server.py edits without manual sudo.
        { command = "/run/current-system/sw/bin/systemctl restart notify-webhook";           options = [ "NOPASSWD" ]; }
      ];
    }
  ];
}
