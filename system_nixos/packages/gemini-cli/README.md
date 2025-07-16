# Gemini CLI for NixOS

A Nix package definition for [Google's Gemini CLI](https://github.com/google-gemini/gemini-cli), enabling easy installation on NixOS systems.

## About Gemini CLI

Gemini CLI is a powerful command-line AI workflow tool developed by Google that:

- 🤖 **AI-Powered Code Analysis**: Leverages AI to understand and analyze large codebases
- 🔄 **Workflow Automation**: Automates repetitive development tasks
- 🎨 **Multimodal App Generation**: Creates applications using AI with support for multiple input types
- 🔗 **Tool Integration**: Connects seamlessly with existing development tools and services
- 📊 **Large Codebase Understanding**: Efficiently processes and queries large projects

## Quick Start

### Method 1: Direct Installation via configuration.nix

1. **Copy the package definition to your NixOS configuration directory:**
   ```bash
   sudo cp gemini-cli.nix /etc/nixos/
   ```

2. **Update the hashes (required for first-time setup):**
   ```bash
   ./get-gemini-hashes.sh
   ```
   Then manually update the `npmDepsHash` in `gemini-cli.nix` with the hash shown in the output.

3. **Add to your `/etc/nixos/configuration.nix`:**
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

4. **Rebuild your system:**
   ```bash
   sudo nixos-rebuild switch
   ```

### Method 2: Test Before Installing

1. **Update hashes and test build:**
   ```bash
   ./get-gemini-hashes.sh
   # Update npmDepsHash in gemini-cli.nix with the provided hash
   nix-build -E "with import <nixpkgs> {}; callPackage ./gemini-cli.nix {}"
   ```

2. **If build succeeds, proceed with Method 1**

## Files Overview

### `gemini-cli.nix`
The main Nix package definition file containing:
- Package metadata and dependencies
- Build configuration for npm-based projects
- Comprehensive comments explaining each section
- Placeholder hashes that need to be updated

### `get-gemini-hashes.sh`
An automated script that:
- Fetches the correct source hash from GitHub
- Updates `gemini-cli.nix` with the source hash
- Attempts a build to reveal the required npm dependencies hash
- Provides clear instructions for the next steps

## Detailed Installation Guide

### Prerequisites

- NixOS system with Nix package manager
- Internet connection for fetching dependencies
- `nix-prefetch-github` available (usually included in nixpkgs)

### Step-by-Step Process

1. **Clone or download this repository:**
   ```bash
   git clone <this-repo-url>  # or copy files manually
   cd gemini-cli-nixos
   ```

2. **Make the hash script executable:**
   ```bash
   chmod +x get-gemini-hashes.sh
   ```

3. **Run the hash updater script:**
   ```bash
   ./get-gemini-hashes.sh
   ```
   This will output something like:
   ```
   ✅ Source hash obtained: sha256-abc123...
   ✅ Source hash updated in gemini-cli.nix
   
   🔄 Building package to determine npm dependencies hash...
   --- BUILD OUTPUT ---
   got: sha256-def456...
   
   📝 Next steps:
   1. Copy the hash from the 'got:' line above
   2. Replace the npmDepsHash placeholder in gemini-cli.nix with this hash
   ...
   ```

4. **Update the npm dependencies hash:**
   Edit `gemini-cli.nix` and replace:
   ```nix
   npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
   ```
   with:
   ```nix
   npmDepsHash = "sha256-def456...";  # Use the hash from step 3
   ```

5. **Test the build:**
   ```bash
   nix-build -E "with import <nixpkgs> {}; callPackage ./gemini-cli.nix {}"
   ```
   If successful, you'll see a `result` symlink created.

6. **Install system-wide:**
   ```bash
   sudo cp gemini-cli.nix /etc/nixos/
   ```

7. **Update your NixOS configuration:**
   Add to `/etc/nixos/configuration.nix`:
   ```nix
   { config, pkgs, ... }:
   let
     gemini-cli = pkgs.callPackage ./gemini-cli.nix {};
   in
   {
     environment.systemPackages = with pkgs; [
       gemini-cli
       # ... other packages
     ];
   }
   ```

8. **Rebuild and switch:**
   ```bash
   sudo nixos-rebuild switch
   ```

### Verification

After installation, verify that Gemini CLI is available:
```bash
gemini --help
```

## Usage

Once installed, you can use Gemini CLI with commands like:

```bash
# Basic usage
gemini

# Get help
gemini --help

# Example workflow commands (refer to official documentation for complete usage)
gemini analyze codebase
gemini generate app
```

For complete usage instructions, see the [official Gemini CLI documentation](https://github.com/google-gemini/gemini-cli#usage).

## Troubleshooting

### Hash Mismatch Errors
If you encounter hash mismatch errors:
1. Re-run `./get-gemini-hashes.sh`
2. Ensure you've updated both hashes in `gemini-cli.nix`
3. Clear any cached builds: `nix-collect-garbage`

### Build Failures
- Ensure you have a stable internet connection
- Check that `nodejs` is available in your nixpkgs
- Verify the GitHub repository is accessible

### Permission Issues
- Ensure the script is executable: `chmod +x get-gemini-hashes.sh`
- Use `sudo` when copying files to `/etc/nixos/`

## Updating Gemini CLI

To update to a newer version of Gemini CLI:

1. Update the `version` field in `gemini-cli.nix`
2. Optionally change `rev` to a specific tag instead of "main"
3. Re-run `./get-gemini-hashes.sh`
4. Update the `npmDepsHash` as before
5. Rebuild your system

## Contributing

Contributions are welcome! Please:
- Test any changes thoroughly
- Update documentation as needed
- Follow Nix packaging best practices

## License

This Nix package definition is provided as-is. Gemini CLI itself is licensed under the Apache License 2.0.

## See Also

- [Official Gemini CLI Repository](https://github.com/google-gemini/gemini-cli)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Nixpkgs Manual](https://nixos.org/manual/nixpkgs/stable/)