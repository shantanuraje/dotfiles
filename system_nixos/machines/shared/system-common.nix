# Shared system configuration for all machines
# Contains common settings like autologin, swap management, and base system config

{ config, pkgs, lib, nix-ai-tools, kimi-cli, ... }:

let
  # RealVNC Server package
  realvnc-server = pkgs.callPackage ../../realvnc-server.nix {};
  # ZeroClaw - pre-built binary (upstream flake is broken)
  zeroclaw = pkgs.callPackage ../../zeroclaw.nix {};
  # OpenCode Desktop - Tauri app beta
  opencode-desktop = pkgs.callPackage ../../opencode-desktop.nix {};
  # BambuStudio - AppImage wrapper (nixpkgs source build has broken OAuth login)
  bambu-studio = pkgs.callPackage ../../bambu-studio-appimage.nix {};
in

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

  # Raise file descriptor limits for nix-daemon to prevent "Too many open files"
  # during evaluation of large configurations with many flake inputs
  systemd.services.nix-daemon.serviceConfig.LimitNOFILE = lib.mkForce 1048576;
  security.pam.loginLimits = [
    { domain = "*"; type = "soft"; item = "nofile"; value = "524288"; }
    { domain = "*"; type = "hard"; item = "nofile"; value = "1048576"; }
  ];
  
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
  
  # Enable nix-ld for running dynamically linked binaries (e.g. Claude Desktop's bundled CLI)
  programs.nix-ld.enable = true;

  # Desktop Environment stack (common to all machines)
  programs.hyprland.enable = true;
  services.xserver.enable = true;
  services.desktopManager.gnome.enable = true;  # Keep GNOME enabled
  services.displayManager.gdm.enable = lib.mkForce false;  # Override GNOME's auto-enable of GDM
  services.displayManager.defaultSession = "none+awesome";  # Default session for LightDM

  # LightDM with slick-greeter (X11 greeter — VNC can capture login screen)
  # Replaces GDM whose GNOME 49+ greeter is Wayland-only and breaks VNC
  # Random wallpaper is selected at boot via display-setup-script
  services.xserver.displayManager.lightdm = {
    enable = true;
    # display-setup-script runs after X starts, before greeter — picks random wallpaper
    extraSeatDefaults = ''
      display-setup-script=${pkgs.writeShellScript "lightdm-wallpaper" ''
        WALLPAPER_DIR="/home/shantanu/Pictures/wallpapers"
        LINK="/var/run/lightdm-wallpaper.jpg"
        if [ -d "$WALLPAPER_DIR" ]; then
          WP=$(${pkgs.findutils}/bin/find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | ${pkgs.coreutils}/bin/shuf -n1)
          if [ -n "$WP" ]; then
            ${pkgs.coreutils}/bin/cp -f "$WP" "$LINK"
            ${pkgs.coreutils}/bin/chmod 644 "$LINK"
          fi
        fi
      ''}
    '';
    greeters.slick = {
      enable = true;
      extraConfig = ''
        show-a11y=true
        show-keyboard=true
        background=/var/run/lightdm-wallpaper.jpg
      '';
    };
  };
  
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

  # Tailscale VPN — mesh networking for remote access (VNC, SSH, etc.)
  # See docs/system/2026-03-09 Tailscale VPN Setup.md for full documentation
  services.tailscale.enable = true;

  # Prevent Tailscale from injecting permissive iptables rules that bypass NixOS firewall.
  # Without this, Tailscale auto-adds a ts-input chain accepting ALL traffic on tailscale0.
  # With nodivert, we control exactly which ports are reachable via NixOS firewall rules.
  services.tailscale.extraSetFlags = [ "--netfilter-mode=nodivert" ];

  # Loose reverse path filtering — required for Tailscale.
  # Strict mode drops legitimate WireGuard packets due to asymmetric routing.
  networking.firewall.checkReversePath = "loose";

  # Firewall: enabled, selective port exposure on tailscale0
  networking.firewall.enable = true;
  networking.firewall.allowedUDPPorts = [ 41641 ];  # Direct WireGuard peer connections

  # Only allow specific services over Tailscale (defense in depth alongside Tailscale ACLs)
  networking.firewall.interfaces.tailscale0 = {
    allowedTCPPorts = [ 5901 ];  # VNC (x11vnc)
  };

  # Disable upstream debug logging for privacy
  services.tailscale.extraDaemonFlags = [ "--no-logs-no-support" ];

  # systemd-resolved for MagicDNS (hostname-based access between tailnet devices)
  services.resolved.enable = true;
  
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
  programs.firefox.enable = false;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  
  # Environment variables
  environment.variables = {
    BASH_ENV = "$HOME/.config/bash/bashrc";
  };
  
  # Autologin configuration (can be overridden per machine)
  services.displayManager.autoLogin = {
    enable = lib.mkDefault false;
    user = "shantanu";
  };
  
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
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    before = [ "swapfile.swap" ];
    unitConfig = {
      RequiresMountsFor = "/";
    };
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
    openssl
    gh
    
    # Desktop applications (common across personal/work)
    vscode
    kitty
    # synergy  # Disabled: Qt5 deprecation build failure upstream
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
    # neofetch removed from nixpkgs (unmaintained) — using fastfetch instead
    powerline
    jq
    ripgrep
    rclone

    # File Manager Trinity: nnn, lf, ranger + GUI file manager
    lf            # Fast terminal file manager with Miller columns
    ranger        # Python-based file manager with rich features
    nautilus      # GNOME file manager (full-featured GUI)
    
    # File manager enhancement packages
    file          # File type detection and MIME support
    mediainfo     # Media file information for previews  
    w3m           # Text-based web browser for HTML previews
    atool         # Archive handling and extraction
    poppler-utils # PDF preview support (pdftotext)
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
    # termpdfpy       # Terminal PDF viewer (disabled: bibtool build failure)
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
    pandoc    # Universal document converter
    
    # Automation and scripting tools
    expect    # Automate interactive applications
    
    # Clipboard utilities
    wl-clipboard
    xclip
    
    # Wayland/Hyprland ecosystem
    waybar
    rofi
    rofi-calc          # Calculator mode for rofi
    rofimoji           # Emoji/unicode picker for rofi
    haskellPackages.greenclip  # Clipboard history manager for rofi
    libqalculate       # Backend for rofi-calc
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
    noto-fonts-color-emoji
    xorg.xwininfo
    xorg.xprop
    # xorg.xmodmap  # Commented out - interferes with VNC keyboard handling
    scrot
    maim               # Screenshot tool with area selection + clipboard support
    
    # Polybar and audio controls
    polybar
    pavucontrol

    # Eww widgets (calendar popup, system stats, etc.)
    eww
    
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
    bambu-studio
    freecad
    blender
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


    # Kimi Code CLI - AI coding agent
    kimi-cli.packages.${pkgs.system}.default

    # ZeroClaw - lightweight AI assistant infrastructure (pre-built binary)
    zeroclaw

    # Claude Desktop app (via overlay from aaddrick/claude-desktop-debian)
    claude-desktop

    # Claude Code usage monitor (real-time CLI dashboard)
    claude-monitor

    # OpenCode Desktop - AI coding assistant (Tauri beta app)
    opencode-desktop

    # RealVNC Server for remote access (runs on port 5902)
    realvnc-server

    # AI and specialized tools from nix-ai-tools (excluding broken packages)
  ] ++ (builtins.attrValues (removeAttrs nix-ai-tools.packages.${pkgs.system} [
    "coding-agent-search"  # Disabled: upstream tarball download corrupted
    "vibe-kanban"          # Disabled: upstream tarball download corrupted
    "goose-cli"            # Disabled: download failure
    "openclaw"             # Disabled: download failure (still broken)
    "agent-deck"              # Disabled: download failure
    "agent-browser"           # Disabled: download failure
    "flake-inputs"         # Not a package, just a file
    "code"                 # Collides with vscode bin/code
    "codex"                # OpenAI Codex - not needed
    "codex-acp"            # OpenAI Codex ACP variant - not needed
    "zeroclaw"             # Installed via local derivation (upstream flake is broken)
    "cc-switch-cli"        # Disabled: upstream hash mismatch (source changed without hash update)
    "beads-rust"           # Disabled: build failure (vendor staging cp error)
    "bernstein"            # Disabled: upstream tarball 404 (v1.5.12)
  ])) ++ [

    
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
      markdown
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
      # python-docx  # Disabled: upstream cucumber-expressions build failure (uv_build version mismatch)
      # Data visualization and web applications
      plotly
      dash
      dash-bootstrap-components
      # Jupyter and VS Code kernel support
      jupyter
      ipykernel
      ipython
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

  # Default system fonts — Nerd Font variants so glyphs render everywhere
  fonts.fontconfig.defaultFonts = {
    monospace = [ "JetBrainsMono Nerd Font" "FiraCode Nerd Font" ];
    sansSerif = [ "JetBrainsMono Nerd Font" "DejaVu Sans" ];
    serif = [ "DejaVu Serif" ];
  };
  
  # NixOS version
  system.stateVersion = "24.11";

  # RealVNC Server systemd system service
  # Provides remote access via RealVNC cloud relay (no direct TCP port needed)
  # Config is read from /root/.vnc/config.d/vncserver-x11 (Service Mode default)
  # The supervisor daemon (vncserver-x11-serviced) does NOT accept VNC params on CLI
  # To set VNC password: sudo vncpasswd -service
  # To change settings: sudo vncserver-x11 -service -<Param> <Value>
  systemd.services.vncserver-x11-serviced = {
    description = "RealVNC Server in Service Mode daemon";
    after = [ "network.target" "syslog.target" "display-manager.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      # Ensure config directory exists before starting
      ExecStartPre = "${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/mkdir -p /root/.vnc/config.d'";
      ExecStart = "${realvnc-server}/bin/vncserver-x11-serviced -fg";
      # Clean shutdown: kill entire process group so core + agent terminate
      # This ensures the cloud relay gets a proper disconnect signal
      ExecStop = "${pkgs.coreutils}/bin/kill -TERM $MAINPID";
      KillMode = "control-group";
      KillSignal = "SIGTERM";
      TimeoutStopSec = "10";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
