# BambuStudio on NixOS

> AppImage-based package to work around broken OAuth login in nixpkgs source build

## Problem

The nixpkgs `bambu-studio` package builds from source correctly, but BambuStudio downloads a **proprietary `libbambu_networking.so` plugin** at runtime. This closed-source binary is compiled for Ubuntu and crashes on NixOS due to ABI incompatibility (`free(): invalid pointer`, missing `libstdc++`/`libz`). This breaks OAuth login — the browser callback returns `result=fail`.

### Symptoms
- Login opens browser, authentication succeeds, but app shows "login failed"
- Browser callback URL: `https://bambulab.com/.../studio-callback?result=fail`
- Logs show `self cert not exist` and network module load failures
- `gtk_window_resize: assertion 'width > 0' failed` (WebKit rendering)

### Root Cause
- `libbambu_networking.so` is a proprietary binary compiled for Ubuntu
- It expects `libstdc++.so.6` and `libz.so.1` at FHS paths
- NixOS's library layout causes ABI mismatch and crashes
- The plugin is closed-source ([BambuStudio#2381](https://github.com/bambulab/BambuStudio/issues/2381)), so it cannot be recompiled

## Solution

We use `appimageTools.wrapType2` to wrap the official Ubuntu 24.04 AppImage. This bundles compatible libraries and the network plugin works correctly.

### Package Location
- **Nix file**: `system_nixos/bambu-studio-appimage.nix`
- **Referenced in**: `system_nixos/machines/shared/system-common.nix`
- **Config data**: `~/.config/BambuStudio/`

### Key Environment Variables
The wrapper sets these for proper operation:
- `SSL_CERT_FILE` — points to NixOS CA bundle for HTTPS
- `GIO_MODULE_DIR` — glib-networking TLS backend
- `WEBKIT_DISABLE_DMABUF_RENDERER=1` — prevents GPU rendering crashes

### Extra Packages Bundled
`cacert`, `curl`, `glib`, `glib-networking`, `webkitgtk_4_1`, `gst-plugins-base`, `gst-plugins-good`

## Updating

When a new BambuStudio version is released:

1. Find the Ubuntu 24.04 AppImage URL from [GitHub releases](https://github.com/bambulab/BambuStudio/releases)
2. Prefetch the hash:
   ```bash
   nix-prefetch-url <appimage-url> --type sha256
   nix-hash --type sha256 --to-sri <hash>
   ```
3. Update `version`, `url`, and `hash` in `bambu-studio-appimage.nix`
4. Test and deploy:
   ```bash
   bash ~/.local/share/chezmoi/system_scripts/test-deploy-nixos.sh
   bash ~/.local/share/chezmoi/system_scripts/deploy-nixos.sh
   ```

## Troubleshooting

### Login still fails after fresh install
Clear old config and try again:
```bash
rm -rf ~/.config/BambuStudio
bambu-studio
```

### Printer not discovered on LAN
Add multicast/SSDP firewall rules to configuration.nix:
```nix
networking.firewall.extraCommands = ''
  iptables -I INPUT -m pkttype --pkt-type multicast -j ACCEPT
  iptables -I INPUT -p udp -m udp --match multiport --dports 1990,2021 -j ACCEPT
'';
```

## Tracking Issues
- [nixpkgs#440951](https://github.com/NixOS/nixpkgs/issues/440951) — crash when login to bambu lab cloud
- [nixpkgs#391622](https://github.com/NixOS/nixpkgs/issues/391622) — failed to install network library
- [nixpkgs#427237](https://github.com/NixOS/nixpkgs/issues/427237) — update request
- [BambuStudio#6522](https://github.com/bambulab/BambuStudio/issues/6522) — Cannot login (NixOS)
- [NixOS Discourse](https://discourse.nixos.org/t/bambu-studio-any-working-method/62272) — community workarounds

## Alternatives Considered
| Approach | Status | Why Not |
|----------|--------|---------|
| nixpkgs source build | Broken | Proprietary plugin ABI mismatch |
| Flatpak | Works | Not declarative, breaks Nix philosophy |
| OrcaSlicer (fork) | Works | Different app, less official support |
| SSL_CERT_FILE env var only | Tried | Doesn't fix the plugin crash |
| LD_LIBRARY_PATH override | Untested | May not fix ABI mismatch |
| AppImage + appimageTools | **Working** | Current solution |
