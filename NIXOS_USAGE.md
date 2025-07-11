# NixOS Configuration Management

Your NixOS system configuration is now managed alongside your dotfiles in chezmoi.

## 📁 Structure

```
~/.local/share/chezmoi/
├── system_nixos/                    # NixOS configuration files
│   ├── configuration.nix           # Main system configuration  
│   ├── flake.nix                   # Nix flake configuration
│   ├── flake.lock                  # Flake lock file
│   ├── hardware-configuration.nix  # Hardware-specific settings
│   └── gemini-cli.nix              # Custom module
├── scripts/
│   └── deploy-nixos.sh             # Manual deployment script
└── ... (your dotfiles)
```

## 🚀 Workflow

### 1. Edit NixOS Configuration
```bash
# Edit main configuration
chezmoi edit system_nixos/configuration.nix

# Or edit directly
nvim ~/.local/share/chezmoi/system_nixos/configuration.nix
```

### 2. Deploy Changes
```bash
# Option A: Manual deployment (recommended)
~/.local/share/chezmoi/scripts/deploy-nixos.sh

# Option B: Copy and rebuild manually
sudo cp ~/.local/share/chezmoi/system_nixos/* /etc/nixos/
sudo nixos-rebuild switch
```

### 3. Commit Changes
```bash
chezmoi cd
git add system_nixos/
git commit -m "update nixos configuration"
git push
```

## 🛡️ Safety Features

- **Automatic backups**: Each deployment creates `/tmp/nixos-backup-TIMESTAMP`
- **Validation**: Configuration is validated before applying
- **Rollback**: Failed deployments restore from backup
- **Version control**: All changes tracked in git

## 🔧 Useful Aliases

Add these to your `.bashrc`:
```bash
alias nixos-edit='chezmoi edit system_nixos/configuration.nix'
alias nixos-deploy='~/.local/share/chezmoi/scripts/deploy-nixos.sh'
alias nixos-commit='chezmoi cd && git add system_nixos/ && git commit'
```

## 🆘 Troubleshooting

**Deployment fails:**
- Check error message in terminal
- Backup is automatically restored
- Fix configuration and try again

**Files out of sync:**
```bash
# Check differences
sudo diff -r /etc/nixos/ ~/.local/share/chezmoi/system_nixos/

# Update chezmoi source from /etc/nixos
sudo cp /etc/nixos/* ~/.local/share/chezmoi/system_nixos/
```

**Emergency restore:**
```bash
# List available backups
ls -la /tmp/nixos-backup-*

# Restore from backup
sudo cp /tmp/nixos-backup-TIMESTAMP/* /etc/nixos/
sudo nixos-rebuild switch
```

## 📋 Quick Commands

```bash
# Edit configuration
chezmoi edit system_nixos/configuration.nix

# Deploy changes  
~/.local/share/chezmoi/scripts/deploy-nixos.sh

# Test configuration
sudo nixos-rebuild dry-build

# Emergency rollback
sudo nixos-rebuild switch --rollback
```