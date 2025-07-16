# Gemini CLI Manual for NixOS

## Table of Contents
1. [Installation](#installation)
2. [Configuration](#configuration)
3. [Usage](#usage)
4. [Maintenance](#maintenance)
5. [Advanced Topics](#advanced-topics)
6. [Troubleshooting](#troubleshooting)

## Installation

### Prerequisites
- NixOS system with Nix package manager
- Internet connection
- Basic knowledge of NixOS configuration

### Standard Installation Process

#### Step 1: Prepare the Package
```bash
# Navigate to the gemini-cli-nixos directory
cd /path/to/gemini-cli-nixos

# Ensure scripts are executable
chmod +x get-gemini-hashes.sh
```

#### Step 2: Update Package Hashes
```bash
# Run the hash updater script
./get-gemini-hashes.sh
```

Expected output:
```
🔄 Getting source hash from GitHub...
   Fetching latest commit hash from google-gemini/gemini-cli repository...
✅ Source hash obtained: sha256-[hash]
✅ Source hash updated in gemini-cli.nix

🔄 Building package to determine npm dependencies hash...
   Note: This build will intentionally fail to show the correct npmDepsHash
   Look for the line that says 'got:' in the output below

--- BUILD OUTPUT ---
got: sha256-[npm-hash]

📝 Next steps:
   1. Copy the hash from the 'got:' line above
   2. Replace the npmDepsHash placeholder in gemini-cli.nix with this hash
   ...
```

#### Step 3: Update npm Dependencies Hash
Edit `gemini-cli.nix` and replace the placeholder:
```nix
# Before:
npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

# After:
npmDepsHash = "sha256-[actual-hash-from-step-2]";
```

#### Step 4: Verify Build
```bash
# Test the package builds correctly
nix-build -E "with import <nixpkgs> {}; callPackage ./gemini-cli.nix {}"
```

If successful, you should see a `result` symlink created.

#### Step 5: Install System-Wide
```bash
# Copy the package definition to NixOS configuration directory
sudo cp gemini-cli.nix /etc/nixos/
```

## Configuration

### Method 1: Direct Package Import
Add to your `/etc/nixos/configuration.nix`:

```nix
{ config, pkgs, ... }:
let
  gemini-cli = pkgs.callPackage ./gemini-cli.nix {};
in
{
  environment.systemPackages = with pkgs; [
    gemini-cli
    # your other packages...
  ];
}
```

### Method 2: Using Overlay
Create `/etc/nixos/overlays/gemini-cli.nix`:

```nix
self: super: {
  gemini-cli = super.callPackage ./gemini-cli.nix {};
}
```

Then in your `configuration.nix`:
```nix
{
  nixpkgs.overlays = [
    (import ./overlays/gemini-cli.nix)
  ];
  
  environment.systemPackages = with pkgs; [
    gemini-cli
  ];
}
```

### Method 3: User-Level Installation
```bash
# Install for current user only
nix-env -f ./gemini-cli.nix -i
```

### Applying Configuration
```bash
# Rebuild and switch to new configuration
sudo nixos-rebuild switch
```

## Usage

### Basic Commands

#### Getting Help
```bash
# Display help information
gemini --help

# Show version
gemini --version
```

#### Configuration Setup
```bash
# Initial setup (if required by gemini-cli)
gemini config

# Set API keys or configuration options
gemini config set api-key "your-api-key"
```

### Common Workflows

#### Code Analysis
```bash
# Analyze current directory
gemini analyze .

# Analyze specific files
gemini analyze src/main.js

# Analyze with specific query
gemini query "find all functions that handle user input"
```

#### Code Generation
```bash
# Generate application
gemini generate app --type web --framework react

# Generate specific components
gemini generate component --name UserProfile --type react
```

#### Workflow Automation
```bash
# Run automated workflow
gemini workflow run deployment

# Create custom workflow
gemini workflow create --name "my-workflow" --config workflow.yml
```

### Environment Variables

Set environment variables in your NixOS configuration:

```nix
{
  environment.variables = {
    GEMINI_API_KEY = "your-api-key";
    GEMINI_CONFIG_DIR = "/home/user/.config/gemini";
  };
}
```

Or in your shell configuration:
```bash
export GEMINI_API_KEY="your-api-key"
export GEMINI_CONFIG_DIR="$HOME/.config/gemini"
```

## Maintenance

### Updating Gemini CLI

#### Method 1: Update to Latest Main Branch
1. Re-run the hash updater:
   ```bash
   ./get-gemini-hashes.sh
   ```

2. Update the npm dependencies hash in `gemini-cli.nix`

3. Rebuild:
   ```bash
   sudo nixos-rebuild switch
   ```

#### Method 2: Update to Specific Version
1. Edit `gemini-cli.nix`:
   ```nix
   {
     version = "2.0.0";  # Update version
     src = fetchFromGitHub {
       owner = "google-gemini";
       repo = "gemini-cli";
       rev = "v2.0.0";    # Use specific tag instead of "main"
       hash = "sha256-..."; # Will need to be updated
     };
   }
   ```

2. Follow the hash update process

### Cleaning Up
```bash
# Remove old build artifacts
nix-collect-garbage

# Remove old system generations
sudo nix-collect-garbage -d
```

### Backup Configuration
```bash
# Backup your configuration
sudo cp /etc/nixos/configuration.nix /etc/nixos/configuration.nix.backup
sudo cp /etc/nixos/gemini-cli.nix /etc/nixos/gemini-cli.nix.backup
```

## Advanced Topics

### Custom Build Options

Modify `gemini-cli.nix` to customize the build:

```nix
buildNpmPackage rec {
  # ... other options ...
  
  # Custom build phases
  preBuild = ''
    # Custom pre-build commands
    echo "Starting custom build..."
  '';
  
  postInstall = ''
    # Custom post-install commands
    wrapProgram $out/bin/gemini \
      --set NODE_ENV production
  '';
  
  # Custom npm install flags
  npmInstallFlags = [ "--production" "--ignore-scripts" ];
}
```

### Using Development Version

To use the development version of Gemini CLI:

```nix
{
  src = fetchFromGitHub {
    owner = "google-gemini";
    repo = "gemini-cli";
    rev = "develop";  # or specific commit hash
    hash = "sha256-...";
  };
}
```

### Cross-Platform Considerations

If you need to limit platforms:

```nix
{
  meta = with lib; {
    # ... other meta attributes ...
    platforms = platforms.linux;  # Linux only
    # platforms = platforms.darwin;  # macOS only
    # platforms = platforms.unix;    # Unix-like systems
  };
}
```

### Integration with Development Shells

Create a `shell.nix` for development:

```nix
{ pkgs ? import <nixpkgs> {} }:
let
  gemini-cli = pkgs.callPackage ./gemini-cli.nix {};
in
pkgs.mkShell {
  buildInputs = [
    gemini-cli
    pkgs.nodejs
    pkgs.git
  ];
  
  shellHook = ''
    echo "Development shell with Gemini CLI ready!"
    gemini --version
  '';
}
```

## Troubleshooting

### Common Issues

#### Hash Mismatch Errors
**Problem**: Build fails with hash mismatch
```
error: hash mismatch in fixed-output derivation
```

**Solution**:
1. Re-run `./get-gemini-hashes.sh`
2. Ensure you copied the correct hash
3. Clear nix store: `nix-collect-garbage`

#### Network/Download Issues
**Problem**: Cannot fetch from GitHub
```
error: unable to download 'https://github.com/...'
```

**Solutions**:
- Check internet connection
- Verify GitHub is accessible
- Try using a different DNS server
- Check if behind corporate firewall

#### Build Failures
**Problem**: Build fails during npm install
```
error: build of derivation failed
```

**Solutions**:
1. Check Node.js version compatibility
2. Verify npm dependencies are available
3. Check build logs: `nix-build --verbose`
4. Try cleaning: `nix-collect-garbage`

#### Runtime Issues
**Problem**: Gemini CLI installed but not working
```
command not found: gemini
```

**Solutions**:
1. Verify installation: `which gemini`
2. Check PATH: `echo $PATH`
3. Restart shell or re-source profile
4. Verify system rebuild: `sudo nixos-rebuild switch`

### Debug Mode

Enable debug output:
```bash
# Debug nix build
nix-build --verbose ./gemini-cli.nix

# Debug gemini-cli itself
gemini --debug [command]
```

### Getting Help

1. **Check logs**: System logs in `/var/log/` or user logs with `journalctl`
2. **NixOS community**: https://discourse.nixos.org/
3. **Gemini CLI issues**: https://github.com/google-gemini/gemini-cli/issues
4. **Nix documentation**: https://nixos.org/manual/

### Reporting Issues

When reporting issues, include:
- NixOS version: `nixos-version`
- Nix version: `nix --version`
- Complete error messages
- Steps to reproduce
- Contents of `gemini-cli.nix` (if modified)

## Appendix

### File Structure
```
gemini-cli-nixos/
├── README.md              # Main documentation
├── MANUAL.md             # This file
├── gemini-cli.nix        # Nix package definition
└── get-gemini-hashes.sh  # Hash updater script
```

### Useful Commands Reference
```bash
# Package management
nix-build -E "with import <nixpkgs> {}; callPackage ./gemini-cli.nix {}"
nix-env -f ./gemini-cli.nix -i
nix-collect-garbage

# System management
sudo nixos-rebuild switch
sudo nixos-rebuild test
nixos-version

# Debugging
nix-build --verbose
nix-store --verify
```