# Nix "Too Many Open Files" Error

## Problem

`sudo nixos-rebuild switch` fails during evaluation with:

```
error: opening directory "/nix/store": Too many open files
```

This occurs when the Nix client process exhausts its file descriptor limit while scanning `/nix/store` during flake evaluation. The store directory can contain tens of thousands of entries, and combined with lock files and flake input evaluation, the process hits the per-process open file limit.

## Root Cause

There are **two** file descriptor limits at play:

1. **nix-daemon** (systemd service) -- handles builds. Its limit is set via `systemd.services.nix-daemon.serviceConfig.LimitNOFILE` (default: 1048576 on NixOS).
2. **nix client** (the `nix build` process invoked by `nixos-rebuild`) -- handles evaluation. When run via `sudo`, it inherits limits from the root shell session, which may default to a low soft limit (1024) unless PAM limits are configured.

The bug was partially fixed in [Nix 2.24.5 (PR #15205)](https://github.com/NixOS/nix/pull/15205), which auto-raises the soft limit to match the hard limit. However, large configurations with many flake inputs can still trigger it if the hard limit itself is too low.

## Symptoms

- Happens during `sudo nixos-rebuild switch` or `sudo nixos-rebuild test`
- Error always references `/nix/store`
- More likely with many flake inputs or a large nix store (30k+ paths)
- `nix-collect-garbage` does **not** fix it (it's a limit issue, not a space issue)

## Fix (Applied)

In `system-common.nix`:

```nix
# Raise file descriptor limits for nix-daemon
systemd.services.nix-daemon.serviceConfig.LimitNOFILE = lib.mkForce 1048576;

# Raise limits for all users (ensures sudo nixos-rebuild gets high limits)
security.pam.loginLimits = [
  { domain = "*"; type = "soft"; item = "nofile"; value = "524288"; }
  { domain = "*"; type = "hard"; item = "nofile"; value = "1048576"; }
];
```

## Immediate Workaround

If you can't deploy the config change (because the build itself fails), temporarily raise the limit for the current command:

```bash
sudo sh -c 'ulimit -n 1048576 && nixos-rebuild switch'
```

## Verification

After deployment, verify limits are applied:

```bash
# Check user limits
ulimit -n        # soft limit (should be 524288)
ulimit -Hn       # hard limit (should be 1048576)

# Check nix-daemon limits
systemctl show nix-daemon.service | grep LimitNOFILE

# Check current system-wide file descriptor usage
cat /proc/sys/fs/file-nr    # allocated / unused / max
```

## References

- [NixOS/nix #6007](https://github.com/NixOS/nix/issues/6007) -- original report, daemon lock files
- [NixOS/nix #8684](https://github.com/NixOS/nix/issues/8684) -- `nix develop` variant, fixed in 2.24.5
- [NixOS/nixpkgs #220990](https://github.com/NixOS/nixpkgs/issues/220990) -- build failure from staging
- [NixOS Discourse: How to address "Too many open files"](https://discourse.nixos.org/t/how-to-the-address-the-too-many-open-files-issue/51646)
- [Nix PR #15205](https://github.com/NixOS/nix/pull/15205) -- auto-raise soft limit to hard limit
