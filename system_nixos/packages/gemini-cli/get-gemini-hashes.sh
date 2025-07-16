#!/usr/bin/env bash

# Gemini CLI Hash Updater Script
# This script automatically fetches and updates the required hashes for the Nix package
# 
# Usage: ./get-gemini-hashes.sh
# 
# This script performs the following steps:
# 1. Fetches the source hash from GitHub using nix-prefetch-github
# 2. Updates the gemini-cli.nix file with the correct source hash
# 3. Attempts to build the package to get the npm dependencies hash
# 4. The build will fail but display the correct npmDepsHash to use
#
# After running this script, you'll need to manually update the npmDepsHash
# in gemini-cli.nix with the value shown in the error message.

# Exit on any error
set -e

echo "🔄 Getting source hash from GitHub..."
echo "   Fetching latest commit hash from google-gemini/gemini-cli repository..."

# Use nix-prefetch-github to get the source hash
# This ensures we get the correct SHA256 hash for the latest commit on main branch
SRC_HASH=$(nix-prefetch-github google-gemini gemini-cli --rev main | grep sha256 | cut -d'"' -f4)

echo "✅ Source hash obtained: $SRC_HASH"

# Update the gemini-cli.nix file with the actual source hash
# This replaces the placeholder hash with the real one
echo "🔄 Updating gemini-cli.nix with source hash..."
sed -i "s/hash = \"sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=\";/hash = \"$SRC_HASH\";/" gemini-cli.nix

echo "✅ Source hash updated in gemini-cli.nix"

echo ""
echo "🔄 Building package to determine npm dependencies hash..."
echo "   Note: This build will intentionally fail to show the correct npmDepsHash"
echo "   Look for the line that says 'got:' in the output below"
echo ""

# Attempt to build the package
# This will fail because the npmDepsHash is still a placeholder
# But the error message will contain the correct hash that we need
echo "--- BUILD OUTPUT ---"
nix-build -E "with import <nixpkgs> {}; callPackage ./gemini-cli.nix {}" 2>&1 | grep "got:" | tail -n1 || true

echo ""
echo "📝 Next steps:"
echo "   1. Copy the hash from the 'got:' line above"
echo "   2. Replace the npmDepsHash placeholder in gemini-cli.nix with this hash"
echo "   3. Try building again with: nix-build -E \"with import <nixpkgs> {}; callPackage ./gemini-cli.nix {}\""
echo "   4. Once successful, copy gemini-cli.nix to /etc/nixos/ and update your configuration"