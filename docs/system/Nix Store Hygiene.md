# Nix Store Hygiene — why /nix/store grows and what we do about it

## The problem (what was happening)

Every `bash deploy-nixos.sh` run:
- Pulls fresh source for any input that bumped (`nix-ai-tools`, `kimi-cli`, etc.).
- Builds derivations not present in `cache.nixos.org`. **About 60% of our build artifacts are local-built** (per the deploy log: 60 "building" lines vs 43 "copying path" cache hits in a recent run).
- Adds those derivations to `/nix/store`.
- Old derivations stick around until something garbage-collects them.

Without the optimisations below, `/nix/store` was at **86 GB** with substantial duplication:

```
3.3G android-studio-unwrapped-2025.3.3.7
2.2G rust-vendor-src       \
2.1G rust-src              / two copies of compiler toolchains
2.1G gno-1.4.1             \
2.1G gno-1.4.2             / two versions kept after upgrade
1.7G openclaw-2026.4.25    \
1.5G openclaw-2026.4.24    / same — both pinned by some derivation
1.8G deno-2.7.13-vendor
1.5G libreoffice
```

Combined with no automatic garbage collection and no auto-optimise hardlinks, every flake update added ~5-15 GB and never reclaimed it.

## What we changed

In `system_nixos/machines/shared/system-common.nix`:

```nix
nix.settings.auto-optimise-store = true;

nix.gc = {
  automatic = true;
  dates = "weekly";
  options = "--delete-older-than 14d";
  persistent = true;
};

boot.loader.systemd-boot.configurationLimit = lib.mkDefault 10;
```

In `system_scripts/deploy-nixos.sh`:

- Step 2a now prunes `/tmp/nixos-backup-*` to keep only the last 5.

### `auto-optimise-store = true`

After every store path is added, nix scans for files identical to ones already in the store and replaces duplicates with hardlinks. **Typical savings: 15–25 %** on store size.

Trade-off: small CPU cost on every build. Negligible.

This runs continuously on new additions. To dedupe what's already in the store *right now*, run once:

```bash
sudo nix-store --optimise
```

(Takes a few minutes — scans every file in /nix/store. Only needed once after first enabling the flag; subsequent builds dedupe automatically.)

### `nix.gc.automatic = true`

A weekly systemd timer runs `nix-collect-garbage --delete-older-than 14d`:
- Deletes derivations not referenced by any current generation, user profile, or GC root older than 14 days.
- Won't touch derivations the running system needs.
- `persistent = true` means it runs on next boot if the machine was off when the timer was scheduled.

You can still trigger manually:

```bash
sudo nix-collect-garbage -d        # deep — also deletes old generations
sudo nix-collect-garbage --delete-older-than 7d
```

### `boot.loader.systemd-boot.configurationLimit = 10`

Caps the boot menu to 10 generations. Each generation pins a closure of derivations; pruning generations frees them for GC. Default is unlimited, which is why some systems accumulate dozens of old generations.

### Backup pruning in deploy-nixos.sh

`/tmp/nixos-backup-*` accumulates one directory per deploy. Each is small (~100 KB) but pollutes `/tmp` and persists until the next reboot. Now we keep last 5.

## What we did NOT change (and why)

### Add a Cachix substituter for nix-ai-tools

`nix-ai-tools` (numtide) likely publishes a Cachix cache for its built tools, which would reduce local builds significantly. **Not enabled** because:
- Adding a substituter requires accepting a public key — needs verification that we trust numtide's signing key.
- Numtide's cache is third-party; current setup is `cache.nixos.org` only.
- Worth doing later if local-build volume becomes a real bottleneck.

To enable later:

```nix
nix.settings = {
  substituters = [
    "https://cache.nixos.org/"
    "https://numtide.cachix.org"   # if numtide publishes here — VERIFY first
  ];
  trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "numtide.cachix.org-1:<their-key>"  # get from numtide.cachix.org page
  ];
};
```

Verify the key from `https://numtide.cachix.org` before enabling.

### Pin nix-ai-tools to a known-good rev

Currently the flake follows latest. Each `nix flake update` rebuilds everything in nix-ai-tools. Pinning to a specific rev avoids the churn but means manually bumping when you want updates.

Trade-off: not done because user wants latest tools by default. Document as a fall-back if disk pressure becomes urgent.

### Convert nix-ai-tools `removeAttrs [...]` to allowlist

Currently we use `removeAttrs nix-ai-tools.packages [<failing-list>]` — every new tool numtide adds is auto-included. Each addition is one more local build per deploy.

Better: explicit `keepAttrs` allowlist of tools we *actually use*. Today this would cut maybe 20-30 packages of dead weight. Effort: 15 minutes of mapping. **Worth doing — adding to tech-debt list.**

### Remove android-studio if unused

3.3 GB just sitting there. If you don't actually use Android Studio on this box, removing it is the single biggest win available. (Note: `~/AndroidStudioProjects/` exists per CLAUDE.md, suggesting it IS used.)

## Monitoring

After the next deploy, baseline numbers:

```bash
# /nix/store size
sudo du -sh /nix/store

# Count of derivations
ls /nix/store | wc -l

# Cache hit ratio in last build
LATEST=$(readlink -f ~/.local/state/nixos-deploy/latest.log)
echo "built locally: $(grep -c '^building' "$LATEST")"
echo "cached:        $(grep -c 'copying path' "$LATEST")"

# Last GC run
journalctl -u nix-gc --since "30 days ago" --no-pager | tail
```

## Expected savings

After the next deploy + one-time `nix-store --optimise`:

| Optimisation | Estimated savings |
|---|---|
| auto-optimise-store hardlinks | 12–22 GB (one-time + continuous) |
| Weekly auto-GC of >14d derivations | 5–10 GB per cycle |
| Backup pruning | <1 GB |
| **Total** | **~15–30 GB recovered** |

Won't change the local-build ratio (60% of derivations still build because no Cachix). For that we'd need a numtide substituter or to trim the nix-ai-tools allowlist.

## Action items (manual, after the next deploy)

1. `sudo nix-store --optimise` — one-time dedupe of existing store
2. `sudo nix-collect-garbage --delete-older-than 14d` — first GC run
3. Verify timer: `systemctl list-timers nix-gc` should show next weekly run
4. Re-check `/nix/store` size: `sudo du -sh /nix/store`

## Why this hadn't been set up earlier

NixOS's defaults are conservative — `auto-optimise-store` and `nix.gc.automatic` are both `false` by default. The reasoning is that auto-optimisation has a small CPU overhead and auto-GC could theoretically delete something the user wanted to keep around. In practice, both are safe with the retention policy above and worth turning on for any system that gets regular `nixos-rebuild` runs.

## Related

- `docs/system/Notification System — Status and Tech Debt.md` — section 3 had "no metrics" + this hygiene problem on the same priority list
- `system_nixos/machines/shared/system-common.nix` — where the fix lives
- `system_scripts/deploy-nixos.sh` — backup pruning step
