# Gemini CLI - Nix Package Definition
# A command-line AI workflow tool by Google that connects to your tools,
# understands your code, and accelerates your workflows.
#
# This package definition allows installation of gemini-cli through NixOS
# configuration.nix or nix-env.

{ lib, buildNpmPackage, fetchFromGitHub, nodejs }:

buildNpmPackage rec {
  # Package metadata
  pname = "gemini-cli";
  version = "1.0.0";  # Update this when new versions are released

  # Source configuration
  # Fetches the source code directly from the official Google Gemini CLI repository
  src = fetchFromGitHub {
    owner = "google-gemini";
    repo = "gemini-cli";
    rev = "main";  # Using main branch - can be changed to specific tag/commit
    # IMPORTANT: This hash must be updated using get-gemini-hashes.sh script
    # The placeholder value below will cause build to fail until updated
    hash = "sha256-bWDX+fSl1foh8KQ1KHFrm9QkQkta4jtM4BrA=";
  };

  # NPM dependencies hash
  # This hash ensures reproducible builds by validating the npm dependencies
  # IMPORTANT: This must be updated after running the initial build attempt
  # Nix will provide the correct hash in the error message when it fails
  npmDepsHash = "sha256-qimhi2S8fnUbIq2MPU1tlvj5k9ZChY7kzxLrYqy9FXI=";

  # Build dependencies
  # Node.js is required as gemini-cli is a TypeScript/JavaScript application
  buildInputs = [ nodejs ];

  # Disable broken symlink check since this package has internal workspace symlinks
  dontFixup = false;
  preFixup = ''
    # Remove broken symlinks that are created during the build process
    find $out -type l -exec test ! -e {} \; -delete || true
  '';

  # Package metadata for Nix package manager
  meta = with lib; {
    description = "A command-line AI workflow tool that connects to your tools, understands your code and accelerates your workflows";
    longDescription = ''
      Gemini CLI is a powerful command-line tool developed by Google that leverages
      AI to enhance development workflows. It can query and edit large codebases,
      generate applications using multimodal AI, automate operational tasks, and
      integrate with various development tools and services.
      
      Key features:
      - AI-powered code analysis and editing
      - Multimodal application generation
      - Workflow automation
      - Integration with development tools
      - Large codebase understanding
    '';
    homepage = "https://github.com/google-gemini/gemini-cli";
    changelog = "https://github.com/google-gemini/gemini-cli/releases";
    license = licenses.asl20;  # Apache License 2.0
    maintainers = [ ];  # Add maintainer info here if desired
    platforms = platforms.all;  # Should work on all platforms supported by Node.js
    mainProgram = "gemini";  # The main executable name
  };
}
