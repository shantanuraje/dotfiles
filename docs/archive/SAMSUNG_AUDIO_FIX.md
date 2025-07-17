# Samsung Galaxy Book Audio Fix for NixOS

## Hardware Compatibility
- **Model**: SAMSUNG ELECTRONICS CO., LTD. NP930QCG-K01US
- **CPU**: Intel i7-1065G7
- **Audio Issue**: Speakers not working, shows "dummy output"
- **Working Solution**: Tested on Ubuntu 20.04 with kernel 5.8

## Problem Description
Samsung Galaxy Book laptops with Intel i7-1065G7 CPUs have audio issues on Linux where:
- Speakers are not detected or show as "dummy output"
- Intel HDA driver conflicts with the required SOF (Sound Open Firmware) driver
- Audio works in Ubuntu but fails in other distributions without specific configuration

## NixOS Solution Architecture

### File Locations in Dotfiles Repository
```
~/.local/share/chezmoi/
├── system_nixos/machines/
│   ├── personal/
│   │   └── laptop-samsung.nix              # Main Samsung laptop config
│   └── shared/hardware/
│       └── samsung-galaxy-book-audio.nix   # Audio fix hardware module
├── system_scripts/
│   └── auto-detect-machine.sh              # Hardware detection script
└── SAMSUNG_AUDIO_FIX.md                    # This documentation file
```

### Hardware Module: samsung-galaxy-book-audio.nix
**Location**: `~/.local/share/chezmoi/system_nixos/machines/shared/hardware/samsung-galaxy-book-audio.nix`

This reusable module contains:
- SOF firmware installation and configuration
- Intel HDA driver blacklisting
- Custom PulseAudio configuration
- Systemd services for boot and resume audio fixes
- ALSA configuration for Samsung hardware

### Machine Configuration: laptop-samsung.nix  
**Location**: `~/.local/share/chezmoi/system_nixos/machines/personal/laptop-samsung.nix`

This machine-specific config imports the hardware module and provides:
- Personal environment setup (full app suite, Claude, development tools)
- Samsung-specific hostname: `samsung-laptop-personal`
- Complete desktop environment (Hyprland + AwesomeWM + GNOME)

## Technical Implementation

### 1. Kernel Module Configuration
```nix
boot.extraModprobeConfig = ''
  # Force SOF driver for Samsung Galaxy Book audio
  options snd slots=snd_soc_skl_hda_dsp
  
  # Blacklist problematic Intel HDA driver  
  blacklist snd-hda-intel
'';

boot.kernelParams = [
  "snd_hda_intel.enable=0"          # Disable Intel HDA
  "snd_soc_skl_hda_dsp.enable=1"    # Enable SOF driver
];
```

### 2. Required Packages
```nix
environment.systemPackages = with pkgs; [
  sof-firmware      # Sound Open Firmware for Intel audio
  alsa-tools        # ALSA configuration tools  
  alsa-utils        # ALSA utilities (amixer, etc.)
];
```

### 3. PulseAudio Override
```nix
hardware.pulseaudio = {
  enable = lib.mkForce true;
  support32Bit = true;
  configFile = pkgs.writeText "samsung-pulseaudio.pa" ''
    .include ${pkgs.pulseaudio}/etc/pulse/default.pa
    
    # Disable suspend-on-idle to prevent audio issues
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
```

### 4. Systemd Services
```nix
# Boot-time audio fix
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

# Post-suspend audio fix  
systemd.services.samsung-audio-fix-resume = {
  description = "Samsung Galaxy Book Audio Fix (Post-Suspend)";
  wantedBy = [ "suspend.target" ];
  after = [ "suspend.target" ];
  serviceConfig = {
    Type = "oneshot";
    ExecStart = "${audioFixScript}";
  };
};
```

## Deployment Instructions

### Automatic Hardware Detection
```bash
cd ~/.local/share/chezmoi
bash system_scripts/auto-detect-machine.sh
```

Expected output for Samsung Galaxy Book:
```
[AUTO-DETECT] Detected: Samsung Galaxy Book NP930QCG-K01US
→ Recommended: personal/laptop-samsung (with audio fix)
→ Hardware module: samsung-galaxy-book-audio.nix
```

### Deploy Configuration
```bash
# Test deployment first
echo "3" | bash ~/.local/share/chezmoi/system_scripts/test-deploy-nixos.sh

# Deploy if test passes
echo "3" | bash ~/.local/share/chezmoi/system_scripts/deploy-nixos.sh
```

### Manual Deployment
```bash
# Copy configuration manually
sudo cp ~/.local/share/chezmoi/system_nixos/machines/personal/laptop-samsung.nix /etc/nixos/configuration.nix

# Copy hardware module
sudo mkdir -p /etc/nixos/shared/hardware
sudo cp ~/.local/share/chezmoi/system_nixos/machines/shared/hardware/samsung-galaxy-book-audio.nix /etc/nixos/shared/hardware/

# Copy other required files
sudo cp ~/.local/share/chezmoi/system_nixos/{flake.nix,flake.lock,gemini-cli.nix} /etc/nixos/

# Rebuild system
sudo nixos-rebuild switch
```

## Verification Steps

After deployment, verify the audio fix:

### 1. Check Audio Devices
```bash
# List audio devices
aplay -l

# Check PulseAudio status
pulseaudio --check -v
```

### 2. Test Audio Output
```bash
# Test speaker output
speaker-test -t wav -c 2

# Check mixer settings
alsamixer
```

### 3. Verify Services
```bash
# Check audio fix services
systemctl status samsung-audio-fix
systemctl status samsung-audio-fix-resume

# Check if SOF driver is loaded
lsmod | grep snd_soc_skl_hda_dsp
```

### 4. Check Kernel Modules
```bash
# Verify Intel HDA is blacklisted
lsmod | grep snd_hda_intel  # Should return nothing

# Verify SOF driver is active
dmesg | grep -i sof
```

## Troubleshooting

### Audio Still Not Working
1. **Reboot required**: The kernel module changes require a reboot
2. **Check module conflicts**: `lsmod | grep snd` to see loaded modules
3. **Verify PulseAudio**: `pulseaudio --kill && pulseaudio --start`
4. **Check ALSA**: `sudo alsactl restore`

### Service Failures
```bash
# Check service logs
journalctl -u samsung-audio-fix
journalctl -u samsung-audio-fix-resume

# Manually run audio fix
sudo /nix/store/*/bin/samsung-audio-fix.sh
```

### Rollback if Needed
```bash
# Rollback to previous configuration
sudo nixos-rebuild --rollback

# Or restore from backup
sudo cp /tmp/nixos-backup-*/configuration.nix /etc/nixos/
sudo nixos-rebuild switch
```

## Extension for Other Machines

### Work Samsung Laptop
Create `~/.local/share/chezmoi/system_nixos/machines/work/laptop-samsung.nix`:
```nix
{ config, pkgs, ... }:
{
  imports = [
    # Same audio fix, different environment
    ../shared/hardware/samsung-galaxy-book-audio.nix
    ../../hardware-configuration.nix
  ];
  
  networking.hostName = "samsung-laptop-work";
  
  # Work-specific packages (no Claude, personal apps, etc.)
  environment.systemPackages = with pkgs; [
    # Work tools only
  ];
}
```

### Other Hardware
Add new modules in `shared/hardware/`:
- `dell-laptop-audio.nix`
- `thinkpad-audio.nix`
- `nvidia-drivers.nix`

## Original Ubuntu Solution Reference

This NixOS solution is based on the working Ubuntu fix from:
- **Primary Source**: [Manjaro Forum - Samsung Galaxy Book Audio Setup](https://forum.manjaro.org/t/howto-set-up-the-audio-card-in-samsung-galaxy-book/37090)
- **Script Source**: [Pastebin TO912.sh](https://pastebin.com/raw/zsXp2vz6)
- **Bug Reports**: 
  - [Kernel Bugzilla #207423](https://bugzilla.kernel.org/show_bug.cgi?id=207423)
  - [Ubuntu Launchpad #1851518](https://bugs.launchpad.net/ubuntu/+source/linux/+bug/1851518)

### Ubuntu Commands Translated to NixOS
| Ubuntu Manual Step | NixOS Declarative Equivalent |
|-------------------|-------------------------------|
| `sudo apt install sof-firmware` | `environment.systemPackages = [ sof-firmware ];` |
| `/etc/modprobe.d/sof.conf` | `boot.extraModprobeConfig` |
| `/etc/modprobe.d/blacklist.conf` | `boot.extraModprobeConfig` |
| Manual service creation | `systemd.services.*` |
| Edit `/etc/pulse/default.pa` | `hardware.pulseaudio.configFile` |

## Documentation Maintenance

This documentation is automatically maintained by the dotfiles update system:
```bash
# Update documentation after changes
bash ~/.local/share/chezmoi/system_scripts/update-docs.sh
```

The audio fix configuration is version controlled with the rest of the dotfiles and will be synchronized across all deployments of the Samsung Galaxy Book configuration.

---

**Last Updated**: Auto-generated by dotfiles documentation system
**Configuration Status**: Active on Samsung Galaxy Book NP930QCG-K01US
**Audio Status**: Working with SOF firmware and PulseAudio configuration