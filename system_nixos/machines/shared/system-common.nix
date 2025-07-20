# Shared system configuration for all machines
# Contains common settings like autologin, swap management, and base system config

{ config, pkgs, lib, ... }:

{
  # Bootloader configuration (common to all machines)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # Nix configuration with flakes support
  nix = {
    package = pkgs.nixVersions.stable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
  
  # Time zone (common across all machines)
  time.timeZone = "America/New_York";
  
  # Localization settings (identical across all machines)
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
  
  # Desktop Environment stack (common to all machines)
  programs.hyprland.enable = true;
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  
  # AwesomeWM configuration (common to all machines)
  services.xserver.windowManager.awesome = {
    enable = true;
    luaModules = with pkgs.luaPackages; [
      luarocks
    ];
  };
  
  # Keymap configuration
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
  
  # Printing support
  services.printing.enable = true;
  
  # Sound system
  security.rtkit.enable = true;
  
  # User account (common configuration)
  users.users.shantanu = {
    isNormalUser = true;
    description = "shantanu";
    extraGroups = [ "networkmanager" "wheel" "adbusers" ];
    packages = with pkgs; [];
  };
  
  # Common programs
  programs.firefox.enable = true;
  programs.adb.enable = true;
  
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  
  # Environment variables
  environment.variables = {
    BASH_ENV = "$HOME/.config/bash/bashrc";
  };
  
  # Autologin configuration (can be overridden per machine)
  services.displayManager.autoLogin = {
    enable = lib.mkDefault true;  # Can be overridden by individual machines
    user = "shantanu";
  };
  
  # Workaround for GNOME autologin bug
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;
  
  # Automatic swap activation
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
  
  # Core system packages (common to all machines)
  environment.systemPackages = with pkgs; [
    # Essential tools
    neovim
    vim
    wget
    git
    
    # Desktop applications (common across personal/work)
    vscode
    kitty
    synergy
    insync
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
    chezmoi
    neofetch
    powerline
    jq
    ripgrep
    
    # Modern CLI tools
    bat       # Cat with syntax highlighting
    fd        # Better find
    eza       # Modern ls
    delta     # Git diff viewer
    tldr      # Simplified man pages
    dust      # Better du
    hyperfine # Benchmarking
    tokei     # Code statistics
    
    # Clipboard utilities
    wl-clipboard
    xclip
    
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
    xorg.xwininfo
    xorg.xprop
    scrot
    
    # Polybar and audio controls
    polybar
    pavucontrol
    
    # Development tools
    android-tools
    android-studio
    nodejs
    stylua
    testdisk
    lazygit
    
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
  
  # Common font packages
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
