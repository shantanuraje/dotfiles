# Claude Dotfiles Manager

## Overview
This is a chezmoi-managed dotfiles repository where Claude assists with configuration management, updates, and git operations.

## Repository Structure
- `dot_*` - Files that will be symlinked to `~/.*`
- `private_dot_*` - Private files (not world-readable)
- `executable_*` - Executable scripts
- Directory structure mirrors target filesystem under `~`

## Common Commands

### Chezmoi Operations
```bash
# Apply changes to home directory
chezmoi apply

# Add new dotfile to management
chezmoi add ~/.config/newfile

# Edit a managed file
chezmoi edit ~/.bashrc

# Check what would change
chezmoi diff

# Update from source directory
chezmoi apply --dry-run
```

### Git Operations
```bash
# Navigate to chezmoi source directory
chezmoi cd

# Check status
git status

# Add and commit changes
git add .
git commit -m "feat: update configuration"

# Push changes
git push
```

### NixOS System Configuration
```bash
# Edit NixOS configuration
chezmoi edit system_nixos/configuration.nix

# Test deployment (dry-run)
bash ~/.local/share/chezmoi/scripts/test-deploy-nixos.sh

# Deploy NixOS changes
bash ~/.local/share/chezmoi/scripts/deploy-nixos.sh

# Check NixOS differences
sudo diff -r /etc/nixos/ ~/.local/share/chezmoi/system_nixos/
```

## Testing Commands
- `chezmoi apply --dry-run` - Preview changes before applying
- `chezmoi diff` - Show differences between source and target
- `bash ~/.local/share/chezmoi/scripts/test-deploy-nixos.sh` - Test NixOS deployment

## Repository Structure
```
~/.local/share/chezmoi/
├── dot_*                    # User dotfiles
├── private_dot_*            # Private user configs  
├── system_nixos/            # NixOS system configurations
│   ├── configuration.nix
│   ├── flake.nix
│   ├── flake.lock
│   ├── hardware-configuration.nix
│   └── gemini-cli.nix
├── scripts/
│   ├── deploy-nixos.sh      # NixOS deployment script
│   └── test-deploy-nixos.sh # NixOS test script
└── NIXOS_USAGE.md          # Detailed NixOS instructions
```

## Workflow for All Configurations
1. **Edit configs**: `chezmoi edit <file>` or edit directly in source
2. **Test changes**: `chezmoi apply --dry-run` for dotfiles, test script for NixOS
3. **Apply dotfiles**: `chezmoi apply`  
4. **Deploy NixOS**: `bash ~/.local/share/chezmoi/scripts/deploy-nixos.sh`
5. **Commit all**: `chezmoi cd && git add . && git commit -m "update configs"`

## Notes for Claude
- Always run `chezmoi apply --dry-run` before actual apply
- Use conventional commit messages (feat:, fix:, docs:, etc.)
- Test configuration changes in safe environment when possible
- Keep dotfiles organized and well-documented
- Never run chezmoi cd and other commands together, always run `chezmoi cd` first, then run next command
- For NixOS: Always test with test-deploy-nixos.sh before actual deployment
- NixOS deployments create automatic backups in /tmp/nixos-backup-*

## Documentation Maintenance
- **CRITICAL**: Always update documentation after any configuration changes
- Run `bash ~/.local/share/chezmoi/scripts/update-docs.sh` after making changes
- Use `--force` flag to force update all documentation
- Validate docs with `--validate` flag before committing
- Check for undocumented configs with `--check` flag
- Documentation files to maintain:
  - `README.md`: Main repository documentation
  - `CONFIGURATION_GUIDE.md`: Detailed file-by-file guide
  - `NIXOS_USAGE.md`: NixOS-specific instructions
  - Application-specific `README.md` files in config directories
- Always update timestamps and statistics when modifying docs
- Keep documentation comprehensive and up-to-date for future reference
- Create backups before major documentation changes
- Ensure all new configurations are properly documented