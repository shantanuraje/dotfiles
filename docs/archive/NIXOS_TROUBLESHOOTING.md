# NixOS Deployment Troubleshooting Guide

## Common Issues and Solutions

### 1. Hardware Configuration Errors

#### Error: `access to absolute path '/nix/store/hardware-configuration.nix' is forbidden`

**Cause**: Machine configuration is trying to import hardware-configuration.nix from wrong location.

**Solution**:
```bash
# 1. Restore original hardware config to /etc/nixos/
sudo cp /tmp/nixos-backup-*/hardware-configuration.nix /etc/nixos/

# 2. Ensure machine configs use relative path:
# In machines/*.nix files:
imports = [ ./hardware-configuration.nix ];  # NOT ../hardware-configuration.nix
```

**Prevention**: Always use paths relative to `/etc/nixos/` in machine configurations.

### 2. Package Hash Mismatches

#### Error: `hash mismatch in fixed-output derivation`

**Cause**: Package source has changed but hash in package definition is outdated.

**Solutions**:

**Option A - Update the hash:**
```nix
# In the package definition (e.g., gemini-cli.nix)
fetchFromGitHub {
  # ... other config ...
  sha256 = "NEW_HASH_FROM_ERROR_MESSAGE";
}
```

**Option B - Temporarily disable package:**
```nix
environment.systemPackages = with pkgs; [
  # problematic-package  # Disabled due to hash mismatch - DATE
];
```

**Option C - Update flake inputs:**
```bash
cd system_nixos
nix flake update specific-input-name
# or
nix flake update  # updates all inputs
```

### 3. Build Failures (autotools, compilation errors)

#### Error: Package fails to build with autotools/compilation errors

**Cause**: Usually indicates issues with nixos-unstable channel having broken packages.

**Solutions**:

**Option A - Switch to stable channel:**
```nix
# In flake.nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";  # Use stable
};
```

**Option B - Temporarily disable problematic packages:**
```nix
environment.systemPackages = with pkgs; [
  # redshift   # Build issues in unstable - 2025-07-15
  # gimp       # Autotools problems - 2025-07-15
];
```

**Option C - Use alternative packages:**
```nix
environment.systemPackages = with pkgs; [
  gammastep    # Use instead of redshift
  krita        # Use instead of gimp
];
```

### 4. Flake Lock Issues

#### Error: Various hash/version conflicts after copying config

**Cause**: `flake.lock` file contains pinned versions that may be incompatible with new system.

**Solution**:
```bash
cd system_nixos
rm flake.lock
nix flake lock
```

**Prevention**: Consider regenerating flake.lock on each deployment rather than copying it.

### 5. Import Path Issues

#### Error: `file 'X' was not found in the Nix search path`

**Cause**: Import paths are incorrect for the deployment context.

**Common Mistakes**:
```nix
# WRONG - paths relative to chezmoi structure
imports = [ ../hardware-configuration.nix ];
gemini-cli = pkgs.callPackage ../gemini-cli.nix {};

# CORRECT - paths relative to /etc/nixos/
imports = [ ./hardware-configuration.nix ];
gemini-cli = pkgs.callPackage ./gemini-cli.nix {};
```

**Solution**: Always write import paths as if the file is in `/etc/nixos/`.

## Systematic Debugging Approach

### Step 1: Identify Error Category
- Hardware/import errors → Check paths and hardware config
- Hash mismatches → Update hashes or disable packages  
- Build failures → Check channel, disable problematic packages
- Flake errors → Regenerate flake.lock

### Step 2: Isolate the Problem
```bash
# Test configuration without applying
sudo nixos-rebuild dry-build --flake /etc/nixos

# If it fails, start commenting out packages until it builds
# Then re-enable packages one by one to find the culprit
```

### Step 3: Apply Appropriate Solution
- Use solutions from sections above based on error type
- Document what you disabled and why (with dates)
- Re-test periodically to re-enable packages when fixed

### Step 4: Verify and Document
```bash
# Once working, apply the configuration
sudo nixos-rebuild switch --flake /etc/nixos

# Document what was changed/disabled for future reference
```

## Useful Commands

### Testing and Validation
```bash
# Test build without applying changes
sudo nixos-rebuild dry-build --flake /etc/nixos

# Check flake configuration
nix flake check /etc/nixos

# Show what would be built
nix flake show /etc/nixos
```

### Debugging and Logs
```bash
# Show full build trace
nix --option show-trace true build /etc/nixos#nixosConfigurations.nixos.config.system.build.toplevel

# Get detailed logs for failed build
nix log /nix/store/failed-derivation-path

# Check system status
systemctl status
```

### Rollback and Recovery
```bash
# List previous generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# Or boot into previous generation from GRUB menu
```

## Prevention Strategies

1. **Test configurations** before deploying to important systems
2. **Keep stable channel option** ready for quick fallback
3. **Document disabled packages** with dates and reasons
4. **Monitor upstream** NixOS channels for package status
5. **Backup working configurations** before major changes
6. **Use version pinning** for critical packages that must work

## Emergency Recovery

If system becomes unbootable:

1. **Boot from NixOS installer/live USB**
2. **Mount the system** (`sudo mount /dev/sdXY /mnt`)
3. **Restore from backup** or edit configuration
4. **Reinstall from working config** (`nixos-install --root /mnt`)

Remember: NixOS generations provide built-in rollback capability through GRUB menu!
