# 🚨 WORK MACHINE SAFETY GUIDE

## CRITICAL ISSUES WHEN PULLING TO WORK MACHINE

### 1. **FLAKE.NX HOSTNAME MISMATCH**
**File**: `system_nixos/flake.nix`
**Problem**: Hardcoded to `samsung-laptop-personal`
**Fix**: Your work machine needs to be added to the flake with its hostname

### 2. **POLYBAR NETWORK INTERFACE**
**Files**: 
- `private_dot_config/polybar/config.ini` (line 277)
- `private_dot_config/polybar/config-rice.ini` (line 219)
**Problem**: Hardcoded to `enp2s0`
**Fix**: Check your work machine's network interface with `ip link show`

### 3. **SAMSUNG-SPECIFIC HARDWARE**
**Files**:
- `system_nixos/machines/shared/hardware/samsung-galaxy-book-audio.nix`
- `system_nixos/machines/personal/laptop-samsung.nix`
**Problem**: Samsung Galaxy Book specific audio fixes
**Fix**: Only import if on Samsung hardware

## SAFE PULL PROCEDURE

### BEFORE PULLING:
1. **Check your work machine hostname**: `hostname`
2. **Check network interface**: `ip link show`
3. **Backup current NixOS config**: `sudo cp -r /etc/nixos /etc/nixos.backup`

### AFTER PULLING:
1. **DO NOT** run `chezmoi apply` on NixOS files immediately
2. **Check** that the flake.nix hostname matches your work machine
3. **Update** polybar network interface to match your work machine
4. **Remove** Samsung-specific imports if not on Samsung hardware

### EMERGENCY ROLLBACK:
If you accidentally break your work machine:
1. `sudo cp -r /etc/nixos.backup/* /etc/nixos/`
2. `sudo nixos-rebuild switch`
3. Or use NixOS rollback: `sudo nixos-rebuild switch --rollback`

## FILES TO REVIEW BEFORE APPLYING:
- `system_nixos/flake.nix` - Change hostname
- `private_dot_config/polybar/config.ini` - Update network interface
- `system_nixos/configuration.nix` - Check hardware imports
- Any file in `system_nixos/machines/personal/` - Personal machine specific

## RECOMMENDATION:
Create a work-specific branch or configuration before pulling to work machine.