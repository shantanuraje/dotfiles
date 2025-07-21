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
    interfaces.enp2s0 = {
      useDHCP = false;
      ipv4.addresses = [ { address = "192.168.2.2"; prefixLength = 24; } ];
    };
  };
  
  systemd.network = {
    enable = true;
    networks."10-enp2s0" = {
      matchConfig.Name = "enp2s0";
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
}