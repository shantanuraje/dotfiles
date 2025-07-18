# Work Configuration - Modular Version  
# Office workstation with static networking and RealSense support

{ config, pkgs, lib, ... }:
let
  # gemini-cli = pkgs.callPackage ./gemini-cli.nix {};
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./machines/shared/system-common.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  nix = {
    package = pkgs.nixVersions.stable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # Work networking - Static IP configuration
  networking.hostName = "nixos";
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

  # Desktop Environment - Same as home (with AwesomeWM)
  programs.hyprland.enable = true;
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  
  # AwesomeWM configuration (same as home)
  services.xserver.windowManager.awesome = {
    enable = true;
    luaModules = with pkgs.luaPackages; [
      luarocks
    ];
  };

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
  };

  # Define a user account
  users.users.shantanu = {
    isNormalUser = true;
    description = "shantanu";
    extraGroups = [ "networkmanager" "wheel" "adbusers"];
    packages = with pkgs; [];
  };

  # Work security - Auto-login disabled
  services.displayManager.autoLogin.enable = false;
  services.displayManager.autoLogin.user = "shantanu";

  # Workaround for GNOME autologin
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # Install firefox.
  programs.firefox.enable = true;

  # Enable Android Debug Bridge
  programs.adb.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  
  environment.variables = {
    BASH_ENV = "$HOME/.config/bash/bashrc";
  };

  # Merged package set - all packages from both configs
  environment.systemPackages = with pkgs; [
    # Core editors and tools
    neovim
    vim
    wget
    git

    # Desktop applications
    vscode
    kitty
    synergy
    insync
    obsidian
    google-chrome
    firefox

    # System utilities
    gparted
    fzf    
    networkmanagerapplet
    nnn
    brightnessctl
    fastfetch
    gotop
    gcc
    bluetuith
    impala 
    usbutils 
    wl-clipboard
    xclip
    chezmoi
    neofetch
    powerline
    jq
    ripgrep
    
    # Modern CLI tools for improved productivity
    bat       # Cat clone with syntax highlighting
    fd        # Better find alternative
    eza       # Modern ls replacement
    delta     # Git diff viewer
    tldr      # Simplified man pages
    dust      # Better du alternative
    hyperfine # Command benchmarking
    tokei     # Code statistics
    bottom    # Better top/htop

    # Wayland/Hyprland ecosystem
    waybar
    rofi-wayland
    swaybg
    dunst
    playerctl
    wlogout
    swaylock
    hyprshot
    waynergy

    # AwesomeWM ecosystem
    picom
    feh
    papirus-icon-theme
    pamixer
    acpi
    lm_sensors
    libnotify
    noto-fonts-emoji
    # redshift  # Temporarily disabled due to build issues in nixos-unstable
    xorg.xwininfo
    xorg.xprop
    
    # Polybar and dependencies
    polybar
    pavucontrol
    pulseaudio  # For polybar pulseaudio module support
    pavucontrol # Audio control GUI


    # Development tools
    android-tools
    android-studio
    nodejs
    stylua
    testdisk
    lazygit

    # Creative and productivity
    # gimp  # Temporarily disabled due to build issues in nixos-unstable
    shotwell
    bambu-studio
    libsForQt5.okular
    discord
    realvnc-vnc-viewer
    iwd
    zellij
    libreoffice-qt
    inkscape
    libei

    # AI and specialized tools
    # claude-desktop-linux-flake.packages.${pkgs.system}.claude-desktop
    claude-code
    # gemini-cli  # Temporarily disabled due to hash issues
    pulsemixer

    # Python development environment (merged from both configs)
    (python3.withPackages (ps: with ps; [
      requests
      beautifulsoup4
      pandas
      pillow
      selenium
      webdriver-manager
      curl-cffi
      playwright
    ]))
  ];

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

  # Font packages
  fonts.packages = with pkgs; [
    font-awesome
    material-design-icons
    jetbrains-mono
    fira-code
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.ubuntu-mono
  ];

  # This value determines the NixOS release
  system.stateVersion = "24.11";
}