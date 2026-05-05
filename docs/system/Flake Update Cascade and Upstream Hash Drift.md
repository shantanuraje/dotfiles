# Flake Update Cascade and Upstream Hash Drift

A recurring class of deploy failure that we've now hit four times in this
project. This doc describes the pattern, the root causes, the mitigations
already in place, the open improvements, and the runbook for when it
strikes again.

## The pattern

1. You answer `y` to "Update flake inputs (nix flake update)?" at the
   start of `bash deploy-nixos.sh`.
2. The script runs `nix flake update`, which bumps **all** flake inputs to
   their latest revs:
   - `nixpkgs` (touches every package's hash transitively)
   - `nix-ai-tools` (an aggregator of ~96 AI-tool packages)
   - `kimi-cli`, `claude-desktop`, `googleworkspace-cli` (smaller, less risk)
3. The new closure is huge. Hundreds to thousands of `copying path …` lines
   stream from `cache.nixos.org`, often for 30–60 minutes.
4. **Eventually the build hits a derivation whose source has changed but
   whose hash is stale**, either:
   - In one of OUR custom derivations (`hermes-agent-with-web`,
     `bambu-studio-appimage`, `realvnc-server`, `gemini-cli`, …) where we
     hand-pinned a `sha256-…` or `narHash`.
   - Upstream in `nix-ai-tools`, where THEIR package's hash is out of date
     relative to its own source (npm, cargo, github tarball, etc.).
5. The deploy fails with a `hash mismatch in fixed-output derivation` or
   `couldn't fetch …` error.
6. We've spent 30–100 minutes; the system is on the previous generation
   (boot loader untouched — that part is safe); the new generation is
   garbage.

## Real instances we've hit

| Date | Package | Cause | Fix that was applied |
|---|---|---|---|
| 2026-04-26 | `bambu-studio-appimage` | upstream changed AppImage URL/hash | bumped version + new hash |
| 2026-04-26 | `code-review-graph` (`fastmcp` test failures) | upstream tests flaky in pinned nixpkgs | added to disable list |
| 2026-04-26 | `gitagent` | upstream tarball 404 (yanked release) | added to disable list |
| 2026-04-29 | `letta-code` | npm registry HTTP/2 framing error on `@img/sharp-libvips-linux-x64` | added to disable list |
| 2026-05-02 | `hermes-agent-web` | `npmDepsHash` stale after upstream npm-deps changed | bumped hash to new value |

The 2026-05-02 failure cost **102m43s** of deploy time before reporting the
single-line hash mismatch.

## Why "everything rebuilds" feels like a related problem

When you update `nixpkgs`, the closure of nearly every package changes
(because everything depends on glibc/openssl/etc.). Each new store path
needs to be **either downloaded from cache.nixos.org or built locally**.
Most are cache-hits (fast), but the *volume* makes the deploy long. Then
the failure happens at the end, when one truly-local build fails.

This is NOT "Nix being wasteful" — it's working correctly. The closure
genuinely changed; Nix correctly recomputes it. The problem is that
`nix flake update` updates ALL inputs at once, including the one
(`nixpkgs`) that triggers the biggest cascade.

## Mitigations already in place

| In | What | What it does |
|---|---|---|
| `system_nixos/machines/shared/system-common.nix` | Explicit allowlist for nix-ai-tools (14 of 96 packages) | New broken upstream packages don't auto-include themselves into our build |
| `system_nixos/machines/shared/system-common.nix` | `nix.settings.auto-optimise-store = true` | Hardlinks dedupe new fetches; closure size grows slower |
| `system_nixos/machines/shared/system-common.nix` | `nix.gc.automatic = true; --delete-older-than 14d` | Old generations from failed deploys get reaped weekly |
| `system_scripts/deploy-nixos.sh` | Concurrency lockfile | Two stuck deploys can no longer pile on each other |
| `system_scripts/deploy-nixos.sh` | Pre-flight chezmoi conflict check | Aborts before nix even starts if dotfile state diverges |
| `system_scripts/deploy-nixos.sh` | `nix flake update` is **opt-in**, default N | Most deploys skip the cascade entirely |
| `.chezmoiignore` | `system_nixos`, `system_scripts`, `docs` | Prevents source-tree drift looking like real conflicts |

## Open improvements (priority order)

### 1. Per-input updates instead of full `nix flake update`

The deploy prompt currently is binary: `y` (update everything) / `N`
(update nothing). When you really only want to bump one tool, you have to
update them all, triggering the cascade.

**Better workflow**: when you want to bump a tool, do it manually outside
the deploy:

```bash
cd ~/.local/share/chezmoi/system_nixos
nix flake lock --update-input nix-ai-tools     # bumps only that one
nix flake lock --update-input kimi-cli         # or that one
# Don't update nixpkgs unless you specifically want a security/feature bump.
```

Then run the deploy with `N` at the prompt (since the lock is already
updated).

**Better still — change the deploy script** to ask interactively:

```
Update flake inputs?
  [a] all (nix flake update — slow, full cascade)
  [s] select inputs to update (interactive list)
  [n] none (default — recommended)
```

Marked as a TODO; not built yet.

### 2. `inputs.nixpkgs.follows = "nixpkgs"` for all flake inputs

Each external flake currently brings its own pinned `nixpkgs`. So when
`googleworkspace-cli` was added, our closure now contains both:
- our `nixpkgs` (current rev)
- the pinned `nixpkgs` from `googleworkspace-cli` (2026-03-28)
- the pinned `nixpkgs` from `nix-ai-tools` (yet another rev)
- the pinned `nixpkgs` from `kimi-cli` (yet another rev)

Most upstream flakes work fine if forced to use OUR nixpkgs. Add to
`flake.nix`:

```nix
googleworkspace-cli = {
  url = "github:googleworkspace/cli";
  inputs.nixpkgs.follows = "nixpkgs";
};
nix-ai-tools.inputs.nixpkgs.follows = "nixpkgs";
kimi-cli.inputs.nixpkgs.follows = "nixpkgs";
```

Trade-off: an upstream might have pinned to a specific nixpkgs because
they tested against that version. Following ours might cause a build
error. If it does, we revert that specific `follows` line.

The win: subsequent deploys redownload only ONE nixpkgs rev's deltas, not
3–4. Should drop the "1418 copying-path lines" by 60–80%.

Marked as a TODO; not applied yet.

### 3. Replace hand-pinned hashes with `importNpmLock` / `cargoLock` /
   `prefetchGit`

The `hermes-agent-with-web` override pins:

```nix
npmDepsHash = "sha256-…";
```

Every time upstream's `package-lock.json` changes (even by one byte), this
hash is invalid and the deploy fails. The hash is **derived** from the
lock file. There are nixpkgs helpers that compute it at build time:

```nix
hermes-agent-web = pkgs.buildNpmPackage {
  npmDeps = importNpmLock {
    npmRoot = "${nix-ai-tools.packages.${pkgs.system}.hermes-agent.src}/web";
  };
  # … no npmDepsHash needed
};
```

Same idea applies to `cargoLock` (replace `cargoSha256` / `cargoHash`).

Effort: ~10 minutes per package. Should be done for any custom derivation
that fetches its source from a fast-moving upstream.

### 4. Pre-build smoke test before activation

Currently: `sudo nixos-rebuild switch` does evaluation, build, AND
activation in one step. If activation succeeds, you're on the new system;
if any step fails, you're on the old one (which is fine but the failure
came after you committed time).

Better: split into `nixos-rebuild build` (just builds, no activation),
then `nixos-rebuild switch` only if the build succeeded. The build phase
finds hash mismatches the same way switch does, but you can choose to
abort cleanly without the script having printed restart-services / reload-
units lines.

Effort: ~5 lines of bash in `deploy-nixos.sh`. Doesn't make failures
faster, but the failure mode is cleaner (deploy script status reflects
the build phase only).

## Runbook — when it happens again

You're 60+ minutes into a deploy and you see:

```
error: hash mismatch in fixed-output derivation '/nix/store/…-FOO-deps.drv':
         specified: sha256-XXXX
            got:    sha256-YYYY
…
[NIXOS-DEPLOY] Rebuild failed after 102m43s!
```

Steps:

### Step 1: identify the failed package

The first error block names it (e.g., `hermes-agent-web`,
`bambu-studio-appimage`, etc.). Check whether it's:
- **Our custom derivation** in `system_nixos/*.nix` (we pin the hash)
- **An upstream package** in `nix-ai-tools` (they pin the hash)

`grep -l "<failing-package>" /home/shantanu/.local/share/chezmoi/system_nixos/`

### Step 2: if it's our derivation, just paste the new hash

The error message tells you both values:
```
specified: sha256-OLDHASH
got:       sha256-NEWHASH
```

Find the line in our `.nix` file with `OLDHASH`, replace with `NEWHASH`,
commit. Re-run deploy with `N` at the flake-update prompt.

### Step 3: if it's an upstream package we don't actively use

Add it to the disable list in `system_nixos/machines/shared/system-common.nix`
(the explicit allowlist removes from inclusion). Re-run deploy.

```nix
# In the allowlist (now an opt-in keep list), simply leave it OUT.
# Nothing else needed.
```

### Step 4: if it's an upstream package we DO use

Either:
- Wait for upstream to fix (often a few hours to a day)
- Override the package locally with a working version
- Pin to an older `nix-ai-tools` rev where it built cleanly:
  ```bash
  cd ~/.local/share/chezmoi/system_nixos
  nix flake lock --override-input nix-ai-tools \
    "github:numtide/nix-ai-tools/<known-good-rev>"
  ```

### Step 5: clean up wasted state

Failed deploys leave partial derivations in `/nix/store`. Reclaim:

```bash
sudo nix-collect-garbage -d
sudo nix-store --optimise   # if not run recently
```

This is automated weekly via `nix.gc.automatic`, but a manual run after
a big failed cascade gets the disk back faster.

## Defensive workflow checklist

Before saying `y` to `nix flake update`:

- [ ] Do I actually need a fresh nixpkgs? (If not — say no.)
- [ ] Do I have time for a 60+ minute deploy if cache misses cascade?
- [ ] Have I committed any pending dotfile changes? (Failed deploys
      leave the source tree dirty.)
- [ ] Is anyone else on the tailnet doing something that depends on this
      box being responsive?

If any of those are "no", **decline the flake update**. Bump specific
inputs out-of-band (`nix flake lock --update-input <name>`) when needed.

## See also

- `docs/system/Nix Store Hygiene.md` — auto-GC, auto-optimise, allowlist
- `docs/system/Deploy Concurrency.md` — lockfile + recovery
- `docs/system/Notification System — Status and Tech Debt.md` — broader
  operational concerns; section 2.A flagged this exact pattern
- `system_nixos/machines/shared/system-common.nix` — the
  hermes-agent-with-web override that's bitten us twice now
- `system_scripts/deploy-nixos.sh` — where future per-input prompts will live
