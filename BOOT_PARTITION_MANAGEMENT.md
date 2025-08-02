# Boot Partition Management Guide

## Issue Overview
NixOS systems can accumulate multiple kernel versions and boot files, leading to boot partition space exhaustion.

## Current System Status
- **Boot Partition Size**: 256MB (`/dev/nvme0n1p1`)
- **Current Usage**: ~45% after cleanup (143MB available)
- **Bootloader**: systemd-boot

## Common Boot Space Issues

### Problem: "No space left on device" during nixos-rebuild
```
OSError: [Errno 28] No space left on device: '...initrd.efi'
Failed to install bootloader
```

### Root Causes
1. **Small boot partition** - 256MB is minimal for modern NixOS
2. **Multiple kernel versions** - Each kernel + initrd = ~36MB
3. **Orphaned boot files** - Old generations leave behind boot files
4. **Generation accumulation** - Too many system generations

## Immediate Solutions

### 1. Clean Orphaned Boot Files
```bash
# Check current kernel
uname -r

# List boot files
ls -la /boot/EFI/nixos/

# Check active generations
sudo nixos-rebuild list-generations

# Remove orphaned kernel files (example)
sudo rm /boot/EFI/nixos/*6.12.33*
sudo rm /boot/EFI/nixos/*6.12.37*
sudo rm /boot/EFI/nixos/*6.12.38*
```

### 2. Aggressive Generation Cleanup
```bash
# Delete older generations
sudo nix-collect-garbage --delete-older-than 3d

# Or delete specific generations
sudo nix-env --delete-generations 77 78

# Clean up boot entries
sudo nixos-rebuild switch --install-bootloader
```

### 3. Monitor Boot Space
```bash
# Check space regularly
df -h /boot

# Check largest files
sudo du -sh /boot/EFI/nixos/* | sort -hr
```

## Long-term Solutions

### 1. Expand Boot Partition (Recommended)
- **Target Size**: 512MB - 1GB
- **Tools**: GParted, parted, or during fresh install
- **Risk**: Requires careful partition manipulation

### 2. Switch to GRUB Bootloader
- Uses less boot space than systemd-boot
- Better for systems with small boot partitions
- Requires configuration change

### 3. Automated Cleanup Scripts
```bash
# Add to system configuration
boot.loader.systemd-boot.configurationLimit = 5;
nix.gc.automatic = true;
nix.gc.dates = "weekly";
nix.gc.options = "--delete-older-than 7d";
```

## Prevention Strategies

### 1. Regular Maintenance
- Clean up generations weekly
- Monitor boot space usage
- Remove orphaned boot files

### 2. Configuration Limits
```nix
# In configuration.nix
boot.loader.systemd-boot.configurationLimit = 3;
```

### 3. Alternative File Managers
- Consider `lf` or `ranger` with better preview capabilities
- Use `nnn` with plugins for terminal-based file management

## Emergency Recovery

If boot partition becomes completely full:
1. Boot from NixOS live USB
2. Mount existing system
3. Clean up `/boot/EFI/nixos/` manually
4. Rebuild system

## Monitoring Commands
```bash
# Daily checks
df -h /boot
sudo nixos-rebuild list-generations | head -5

# Weekly cleanup
sudo nix-collect-garbage --delete-older-than 7d
```

---
*Last updated: 2025-08-02*
*System: samsung-laptop-personal*