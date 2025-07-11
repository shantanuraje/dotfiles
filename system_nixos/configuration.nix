# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, claude-desktop-linux-flake, ... }:
let
  gemini-cli = pkgs.callPackage ./gemini-cli.nix {};
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  #settings.experimental-features = ["nix-command" "flakes"];
  nix = {
    package = pkgs.nixVersions.stable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
  # Optionally, make sure the swapfile is created if it doesn't exist
  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

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
  
  #Programs
  programs.hyprland.enable = true;
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  #services.xserver.windowManager.awesome.enable = true; 
  services.xserver.windowManager.awesome = {
    enable = true;
    luaModules = with pkgs.luaPackages; [
      luarocks
    ];
  };
  # services.xserver.windowManager.awesome = {
  #   enable = true;
  #   package = pkgs.awesome-git;  
  # };  
  # services.xserver.windowManager.awesome = {
  #   enable = true;
  #   package = pkgs.awesome-git;
  # };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
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

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.shantanu = {
    isNormalUser = true;
    description = "shantanu";
    extraGroups = [ "networkmanager" "wheel" "adbusers"];
    packages = with pkgs; [
    #  thunderbird
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Enable Android Debug Bridge
  programs.adb.enable = true;

  # Add your user to the adbusers group
  # users.users.shantanu.extraGroups = [ "adbusers"];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  
  environment.variables = {
    BASH_ENV = "$HOME/.config/bash/bashrc";
  };
  # List packages installed in system profile. To search, run:
  # $ nix search wget

  # in inputs
  #inputs.claude-desktop-linux-flake.url = "github:k3d3/claude-desktop-linux-flake";

  # # in outputs, under `environment.systemPackages`
  # environment.systemPackages = [
  #   inputs.claude-desktop-linux-flake.packages.${pkgs.system}.default
  # ];
  #

  environment.systemPackages = with pkgs; [
    neovim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    vscode
    kitty
    synergy
    insync
    obsidian
    google-chrome
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
    impala 
    iwd
    zellij
    nodejs
    libsForQt5.okular
    stylua
    bambu-studio
    testdisk
    hyprshot
    waynergy
    realvnc-vnc-viewer
    dunst 
    lazygit
    libnotify
    gimp
    shotwell
    wshowkeys
    usbutils 
    wl-clipboard
    xclip
    waynergy
    discord
    chezmoi
    neofetch
    powerline
    jq

    claude-desktop-linux-flake.packages.${pkgs.system}.claude-desktop
    claude-code
    gemini-cli
    pulsemixer

    picom
    feh
    # lain
    # vicious
    papirus-icon-theme
    playerctl
    brightnessctl
    pamixer
    acpi
    lm_sensors
    libnotify
    noto-fonts-emoji
    redshift
    xorg.xwininfo
    xorg.xprop

    #python3
    (python3.withPackages (ps: with ps; [
      requests
      beautifulsoup4
      pandas
      pillow
      selenium
      webdriver-manager
      curl-cffi
      playwright
      playwright-browsers
    ]))    
    


    nodejs
    android-tools
    android-studio
 ];

  fonts.packages = with pkgs; [
    font-awesome
    material-design-icons
    
    jetbrains-mono
    fira-code
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.ubuntu-mono
  ];


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:
  #services.dunst.enable = true;

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}
