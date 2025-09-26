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
  services.desktopManager.gnome.enable = true;  # Keep GNOME enabled
  
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
  # TEMPORARILY DISABLED: GDM autologin causing boot hang at graphical target
  # Error: pam_unix helper binary execve failed
  services.displayManager.autoLogin = {
    enable = lib.mkDefault false;  # Temporarily disabled to fix boot issues
    user = "shantanu";
  };
  
  # Workaround for GNOME autologin bug (keeping disabled for consistency)
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;
  
  # Automatic swap activation
  swapDevices = [
    {
      device = "/swapfile";
      size = 16384; # 16GB swap file
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
          ${pkgs.util-linux}/bin/fallocate -l 16G /swapfile
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
    pciutils  # Hardware information tools (lspci, etc.)
    chezmoi
    neofetch
    powerline
    jq
    ripgrep
    
    # File Manager Trinity: nnn, lf, ranger + GUI file manager
    lf            # Fast terminal file manager with Miller columns
    ranger        # Python-based file manager with rich features
    nautilus      # GNOME file manager (full-featured GUI)
    
    # File manager enhancement packages
    file          # File type detection and MIME support
    mediainfo     # Media file information for previews  
    w3m           # Text-based web browser for HTML previews
    atool         # Archive handling and extraction
    poppler_utils # PDF preview support (pdftotext)
    ffmpegthumbnailer  # Video thumbnail generation
    highlight     # Syntax highlighting for code files
    tree          # Directory tree visualization
    imagemagick   # Image manipulation and thumbnails
    exiftool      # Image metadata extraction
    
    # Additional preview tools
    odt2txt       # OpenDocument text extraction
    catdoc        # MS Word document conversion
    xlsx2csv      # Excel file conversion
    djvulibre     # DjVu document support
    
    # Essential GUI applications for file opening
    mpv           # Lightweight video player
    vlc           # Full-featured media player
    eog           # GNOME image viewer
    gedit         # Simple text editor
    gnome-text-editor  # Modern GNOME text editor
    zathura       # Lightweight PDF viewer
    p7zip         # 7zip archive support
    
    # Additional CLI tools for enhanced terminal file managers
    mupdf         # Minimal PDF viewer
    lynx          # Text-based web browser
    w3m           # Text-based web browser with image support
    viu           # Terminal image viewer
    chafa         # Terminal image viewer with better color
    termpdfpy       # Terminal PDF viewer
    unrar         # RAR archive support
    zip           # ZIP creation/extraction
    
    # MIME type support and file associations
    shared-mime-info  # MIME database
    desktop-file-utils  # Desktop file utilities
    
    # Modern CLI tools
    bat       # Cat with syntax highlighting
    fd        # Better find
    eza       # Modern ls
    delta     # Git diff viewer
    tldr      # Simplified man pages
    dust      # Better du
    hyperfine # Benchmarking
    tokei     # Code statistics
    glow      # Terminal markdown renderer
    
    # Clipboard utilities
    wl-clipboard
    xclip
    
    # Wayland/Hyprland ecosystem
    waybar
    rofi
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
    # xorg.xmodmap  # Commented out - interferes with VNC keyboard handling
    scrot
    
    # Polybar and audio controls
    polybar
    pavucontrol
    
    # Development tools
    android-tools
    android-studio
    nodejs
    yarn           # Package manager for React Native
    watchman       # File watching service for React Native
    openjdk17      # Java 17 for Android builds
    unzip          # For extracting packages
    curl           # HTTP client for API calls
    # Use 'npx expo' instead of deprecated expo-cli package
    stylua
    testdisk
    lazygit
    arduino-ide    # Arduino IDE for embedded development

    discord  # For team communication
    bottom   # Better top/htop for monitoring
    pulseaudio  # For polybar pulseaudio module support
    # PulseAudio volume control
    pulsemixer

    # Personal development and creative tools
    obsidian
    google-chrome
    
    # Creative and productivity apps (personal setup)
    shotwell
    # bambu-studio  # Temporarily disabled to test libsoup issue
    # libsForQt5.okular
    realvnc-vnc-viewer
    iwd
    zellij
    libreoffice-qt
    inkscape
    libei
    
    # Hash generation tools for package maintenance
    nix-prefetch-git
    nix-prefetch-github
    
    # OCR and text recognition
    tesseract
    
    # Qt platform plugins for PyQt5 applications
    qt5.qtbase
    qt5.qtx11extras


    # AI and specialized tools (personal environment)
    # claude-desktop-linux-flake.packages.${pkgs.system}.claude-desktop  # Disabled due to persistent hash mismatch
    claude-code
    gemini-cli  # Using nixpkgs version

    
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
      pyyaml
      networkx
      # Computer vision and image processing packages
      opencv4
      numpy
      pytesseract
      scikit-image
      matplotlib
      # GUI toolkit with platform support
      pyqt5
      pyqt5-sip
      # Document processing
      python-docx
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
