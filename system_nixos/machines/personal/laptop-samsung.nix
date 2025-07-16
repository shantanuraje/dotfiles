# Personal Samsung Galaxy Book Configuration
# Hardware: SAMSUNG ELECTRONICS CO., LTD. NP930QCG-K01US
# Environment: Personal laptop with full development setup

{ config, pkgs, claude-desktop-linux-flake, ... }:
let
  gemini-cli = pkgs.callPackage ./gemini-cli.nix {};
in
{
  imports = [
    # Hardware-specific audio fix
    ./machines/shared/hardware/samsung-galaxy-book-audio.nix
    # Base hardware scan
    ./hardware-configuration.nix
  ];

  # Machine identification
  networking.hostName = "samsung-laptop-personal";
  
  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # Nix configuration  
  nix = {
    package = pkgs.nixVersions.stable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
  
  # Networking
  networking.networkmanager.enable = true;
  
  # Time zone
  time.timeZone = "America/New_York";
  
  # Localization
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
  
  # Desktop Environment - Full multi-environment setup for personal use
  programs.hyprland.enable = true;
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  
  # AwesomeWM configuration
  services.xserver.windowManager.awesome = {
    enable = true;
    luaModules = with pkgs.luaPackages; [
      luarocks
    ];
  };
  
  # Keymap
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
  
  # Printing
  services.printing.enable = true;
  
  # Sound is handled by hardware module (PulseAudio + Samsung audio fix)
  security.rtkit.enable = true;
  
  # User account
  users.users.shantanu = {
    isNormalUser = true;
    description = "shantanu";
    extraGroups = [ "networkmanager" "wheel" "adbusers" ];
    packages = with pkgs; [];
  };
  
  # Firefox and Android support
  programs.firefox.enable = true;
  programs.adb.enable = true;
  
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  
  # Environment variables
  environment.variables = {
    BASH_ENV = "$HOME/.config/bash/bashrc";
  };
  
  # Personal laptop package set - includes everything for development and personal use
  environment.systemPackages = with pkgs; [
    # Core system tools
    neovim
    vim  
    wget
    git
    
    # Desktop applications (personal setup includes everything)
    vscode
    kitty
    synergy
    insync
    obsidian
    google-chrome
    firefox
    discord
    
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
    
    # Modern CLI tools for productivity
    bat       # Cat with syntax highlighting
    fd        # Better find
    eza       # Modern ls
    delta     # Git diff viewer
    tldr      # Simplified man pages
    dust      # Better du
    hyperfine # Benchmarking
    tokei     # Code statistics
    
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
    #redshift
    xorg.xwininfo
    xorg.xprop
    
    # Polybar and audio controls
    polybar
    pavucontrol
    # Note: pulseaudio provided by hardware module
    
    # Development tools
    android-tools
    android-studio
    nodejs
    stylua
    testdisk
    lazygit
    
    # Creative and productivity apps (personal setup)
    # gimp
    shotwell
    bambu-studio
    libsForQt5.okular
    realvnc-vnc-viewer
    iwd
    zellij
    libreoffice-qt
    inkscape
    libei
    
    # AI and specialized tools (personal environment)
    claude-desktop-linux-flake.packages.${pkgs.system}.claude-desktop
    claude-code
    # gemini-cli  # Temporarily disabled - npm dependency hash needs fixing
    pulsemixer
    
    # Hash generation tools for package maintenance
    nix-prefetch-git
    nix-prefetch-github
    
    # Python development environment
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
  
  # NixOS version
  system.stateVersion = "24.11";
}