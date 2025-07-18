# Shared system configuration for all machines
# Contains common settings like autologin and swap management

{ config, pkgs, ... }:

{
  # Autologin configuration for user shantanu
  services.displayManager.autoLogin = {
    enable = true;
    user = "shantanu";
  };
  
  # Workaround for GNOME autologin bug
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;
  
  # Automatic swap activation
  # Enable swap file at /swapfile - NixOS will handle activation automatically
  swapDevices = [
    {
      device = "/swapfile";
      size = 8192; # 8GB swap file
    }
  ];
  
  # If the swapfile doesn't exist yet, create it automatically
  systemd.services.create-swapfile = {
    description = "Create swap file if it doesn't exist";
    wantedBy = [ "swap.target" ];
    before = [ "swap.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "create-swapfile" ''
        if [ ! -f /swapfile ]; then
          echo "Creating swap file..."
          ${pkgs.util-linux}/bin/fallocate -l 8G /swapfile
          chmod 600 /swapfile
          ${pkgs.util-linux}/bin/mkswap /swapfile
          echo "Swap file created successfully"
        fi
      '';
      RemainAfterExit = true;
    };
  };
}
