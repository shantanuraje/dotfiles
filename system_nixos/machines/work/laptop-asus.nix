# Work Configuration - HP Desktop
# Office workstation with static networking and RealSense support

{ config, pkgs, lib, ... }:

{
  imports = [
    # Shared system configuration (common settings, packages, etc.)
    ./machines/shared/system-common.nix
    # Hardware configuration
    ./hardware-configuration.nix
  ];

  # Machine-specific identification
  networking.hostName = "nixos";

  # Work-specific networking - Static IP configuration
  networking.networkmanager.enable = true;
  networking = {
    useDHCP = false;
    interfaces.eno2 = {
      useDHCP = false;
      ipv4.addresses = [ { address = "192.168.2.3"; prefixLength = 24; } ];
    };
  };
  
  systemd.network = {
    enable = true;
    networks."10-eno2" = {
      matchConfig.Name = "eno2";
      address = [ "192.168.2.2/24" ];
      routes = [
        { Destination = "192.168.2.0/24"; Gateway = "192.168.2.1"; }
      ];
    };
  };
  systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;

  # Work security - Disable autologin (override shared setting)
  services.displayManager.autoLogin.enable = lib.mkForce false;

  # Work-specific audio configuration (PipeWire instead of PulseAudio)
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # # Work-specific additional packages
  # environment.systemPackages = with pkgs; [
  #   # Work-specific additions
  #   discord  # For team communication
  #   bottom   # Better top/htop for monitoring
  #   pulseaudio  # For polybar pulseaudio module support
  # ];

  # RealSense camera support for work
  services.udev.extraRules = ''
    # RealSense udev rules
    SUBSYSTEM=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b3a", MODE="0666", GROUP="video"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b3b", MODE="0666", GROUP="video"
  '';

  # Reload udev rules on system rebuild
  systemd.services.udevadm-trigger = {
    enable = true;
    wantedBy = [ "multi-user.target" ];
    script = ''
      udevadm control --reload
      udevadm trigger
    '';
  };

  # Display configuration for dual monitor setup
  # This laptop has Intel UHD 630 + NVIDIA GTX 1650
  # Using Intel driver with NVIDIA offload for better compatibility
  services.xserver = {
    # Use modesetting driver (works with both Intel and NVIDIA)
    videoDrivers = [ "modesetting" ];

    # Configure displays - eDP-1 as primary, HDMI-1-1 vertical to the right
    displayManager.sessionCommands = ''
      # Wait a moment for displays to be detected
      sleep 2
      # Configure monitors - laptop screen primary, external monitor vertical on right
      ${pkgs.xorg.xrandr}/bin/xrandr --output eDP-1 --primary --mode 1920x1080 --pos 0x0 --rotate normal || true
      ${pkgs.xorg.xrandr}/bin/xrandr --output HDMI-1-1 --mode 1920x1080 --pos 1920x0 --rotate right --right-of eDP-1 || true
    '';
  };

  # Create a systemd service to configure displays after X starts
  systemd.user.services.configure-displays = {
    description = "Configure dual monitor setup";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.xorg.xrandr}/bin/xrandr --output eDP-1 --primary --mode 1920x1080 --pos 0x0 --rotate normal && ${pkgs.xorg.xrandr}/bin/xrandr --output HDMI-1-1 --mode 1920x1080 --pos 1920x0 --rotate right --right-of eDP-1'";
      RemainAfterExit = true;
    };
  };

  # Enable NVIDIA support with offloading (better for laptops)
  hardware.nvidia = {
    # Use NVIDIA only when needed (better battery life)
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };

      # Bus IDs for Intel and NVIDIA GPUs
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };

    # Use proprietary drivers for better compatibility
    open = false;

    # Enable modesetting
    modesetting.enable = true;

    # Power management for better battery life
    powerManagement.enable = true;
    powerManagement.finegrained = true;
  };
}