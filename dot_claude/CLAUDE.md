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
# Check status
git status

# Add and commit changes
git add .
git commit -m "feat: update configuration"

# Push changes
git push
```

## Testing Commands
- `chezmoi apply --dry-run` - Preview changes before applying
- `chezmoi diff` - Show differences between source and target

## Notes for Claude
- Always run `chezmoi apply --dry-run` before actual apply
- Use conventional commit messages (feat:, fix:, docs:, etc.)
- Test configuration changes in safe environment when possible
- Keep dotfiles organized and well-documented