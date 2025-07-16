# Samsung Galaxy Book Audio Fix Module
# Hardware: SAMSUNG ELECTRONICS CO., LTD. NP930QCG-K01US
# CPU: Intel i7-1065G7
# 
# This module provides the audio fix for Samsung Galaxy Book laptops.
# Can be imported by both personal and work machine configurations.
#
# Original fix from: https://forum.manjaro.org/t/howto-set-up-the-audio-card-in-samsung-galaxy-book/37090

{ config, pkgs, lib, ... }:

let
  # Audio fix script from https://pastebin.com/raw/zsXp2vz6
  audioFixScript = pkgs.writeScript "samsung-audio-fix.sh" ''
    #!/bin/bash
    # Samsung Galaxy Book Audio Fix Script
    
    echo "Applying Samsung Galaxy Book audio fix..."
    
    # Initialize ALSA
    ${pkgs.alsa-tools}/bin/alsactl init 2>/dev/null || true
    
    # Apply audio mixer settings
    ${pkgs.alsa-utils}/bin/amixer -q set Master unmute 2>/dev/null || true
    ${pkgs.alsa-utils}/bin/amixer -q set Speaker unmute 2>/dev/null || true
    ${pkgs.alsa-utils}/bin/amixer -q set Headphone unmute 2>/dev/null || true
    
    # Set volume levels
    ${pkgs.alsa-utils}/bin/amixer -q set Master 80% 2>/dev/null || true
    ${pkgs.alsa-utils}/bin/amixer -q set Speaker 80% 2>/dev/null || true
    
    echo "Samsung Galaxy Book audio fix applied successfully"
  '';
in
{
  # Audio packages required for Samsung Galaxy Book
  environment.systemPackages = with pkgs; [
    sof-firmware      # Sound Open Firmware for Intel audio
    alsa-tools        # ALSA configuration tools  
    alsa-utils        # ALSA utilities (amixer, etc.)
  ];
  
  # Kernel module configuration for Samsung Galaxy Book audio
  boot.extraModprobeConfig = ''
    # Force SOF driver for Samsung Galaxy Book audio
    options snd slots=snd_soc_skl_hda_dsp
    
    # Blacklist problematic Intel HDA driver  
    blacklist snd-hda-intel
  '';
  
  # Kernel parameters for Samsung Galaxy Book
  boot.kernelParams = [
    "snd_hda_intel.enable=0"          # Disable Intel HDA
    "snd_soc_skl_hda_dsp.enable=1"    # Enable SOF driver
  ];
  
  # Use PulseAudio instead of PipeWire for this hardware
  hardware.pulseaudio = {
    enable = lib.mkForce true;
    support32Bit = true;
    configFile = pkgs.writeText "samsung-pulseaudio.pa" ''
      # Samsung Galaxy Book PulseAudio configuration
      .include ${pkgs.pulseaudio}/etc/pulse/default.pa
      
      # Disable suspend-on-idle to prevent audio issues
      # (commenting out module-suspend-on-idle)
      
      # Force load SOF module for Samsung Galaxy Book
      load-module module-alsa-sink device=hw:0,0
      load-module module-alsa-source device=hw:0,0
    '';
  };
  
  # Disable PipeWire (conflicts with PulseAudio fix)
  services.pipewire = {
    enable = lib.mkForce false;
    alsa.enable = lib.mkForce false;
    pulse.enable = lib.mkForce false;
  };
  
  # Systemd service for audio fix at boot
  systemd.services.samsung-audio-fix = {
    description = "Samsung Galaxy Book Audio Fix";
    wantedBy = [ "multi-user.target" ];
    after = [ "sound.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${audioFixScript}";
      RemainAfterExit = true;
    };
  };
  
  # Systemd service for audio fix after suspend/resume  
  systemd.services.samsung-audio-fix-resume = {
    description = "Samsung Galaxy Book Audio Fix (Post-Suspend)";
    wantedBy = [ "suspend.target" ];
    after = [ "suspend.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${audioFixScript}";
    };
  };
  
  # ALSA configuration
  environment.etc."alsa/conf.d/99-samsung-galaxy-book.conf".text = ''
    # Samsung Galaxy Book ALSA configuration
    defaults.pcm.card 0
    defaults.ctl.card 0
  '';
  
  # Hardware identification file for documentation
  environment.etc."hardware-profile/samsung-galaxy-book.txt".text = ''
    Samsung Galaxy Book Audio Fix Applied
    =====================================
    
    Hardware: SAMSUNG ELECTRONICS CO., LTD. NP930QCG-K01US
    CPU: Intel i7-1065G7
    
    Audio Fix Components:
    - SOF firmware enabled
    - Intel HDA driver blacklisted  
    - Custom PulseAudio configuration
    - Boot and resume audio services
    
    References:
    - https://forum.manjaro.org/t/howto-set-up-the-audio-card-in-samsung-galaxy-book/37090
    - https://pastebin.com/raw/zsXp2vz6
    - Kernel bug: https://bugzilla.kernel.org/show_bug.cgi?id=207423
    
    Module: machines/shared/hardware/samsung-galaxy-book-audio.nix
  '';
}