# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  #nix.settings.experimental-features = ["nix-command" "flakes"];
  nix = {
    package = pkgs.nixVersions.stable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
  networking = {
    useDHCP = false;
    interfaces.enp2s0 = {
      useDHCP = false;
      ipv4.addresses = [ { address = "192.168.2.2"; prefixLength = 24; } ];
    };
   # routes = [
   #    { address = "192.168.2.0"; prefixLength = 24; via = "192.168.2.1"; }
   # ];
   #  #defaultGateway = "192.168.2.1";
    #   staticRoutes = [
    #   { address = "0.0.0.0"; prefixLength = 0; via = "192.168.2.1"; } # Persistent default route
    # ];
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

  # networking.extraConfig = ''
  #   ip route add 192.168.2.0/24 via 192.168.2.1 dev enp2s0
  # '';
  # # networking.extraConfig = ''
  #   ip route add default via 192.168.2.1 dev enp2s0
  # '';  
  #

  #networking.defaultGateway = "192.168.2.1";

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  #services.xserver.displayManager.xwayland.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.shantanu = {
    isNormalUser = true;
    description = "shantanu";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
    #  thunderbird
    ];
  };

  # Enable automatic login for the user.
  services.displayManager.autoLogin.enable = false;
  services.displayManager.autoLogin.user = "shantanu";

  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
        vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    vscode
    google-chrome
    synergy
    kitty
    neovim
    impala 
    obsidian
    wget
    wl-clipboard
    git
    gparted
    waybar
    rofi-wayland
    swaybg
    dunst
    fzf    
    playerctl
    wlogout
    swaylock
    networkmanagerapplet
    nnn
    brightnessctl
    fastfetch
    gotop
    gcc
    bluetuith
    libei
    inkscape
    # librealsense-gui
    usbutils    
    
    # Optional: Polybar and dependencies (for AwesomeWM if needed)
    polybar
    pavucontrol
    pulseaudio  # For polybar pulseaudio module support
    pamixer
    
    # Other applications
    libreoffice-qt
    claude-code
  ];

  # # Add udev rules for RealSense
  # systemd.udev.extraRules = ''
  #   # RealSense udev rules
  #   SUBSYSTEM=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b3a", MODE="0666", GROUP="video"
  #   SUBSYSTEM=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b3b", MODE="0666", GROUP="video"
  # '';
  #
  # # Ensure that udev rules are properly triggered
  # systemd.udev.reloadRules = true;
  #
  # Add RealSense udev rules as a text block
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

  # # Define the RealSense udev rules file
  # environment.etc."udev/rules.d/99-realsense-libusb.rules".source = pkgs.librealsense.config.ubiquiti.rules;
  #
  # # Reload udev rules after changing
  # systemd.services.udevadm-trigger = {
  #   enable = true;
  #   wantedBy = [ "multi-user.target" ];
  #   script = ''
  #     udevadm control --reload
  #     udevadm trigger
  #   '';
  # };
  # # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };
  #programs.hypr.enable = true;
  programs.hyprland.enable = true;
  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}