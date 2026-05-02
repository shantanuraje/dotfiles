{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-ai-tools.url = "github:numtide/nix-ai-tools";
    kimi-cli.url = "github:MoonshotAI/kimi-cli";
    claude-desktop.url = "github:aaddrick/claude-desktop-debian";
    # Google Workspace CLI (`gws` binary) — Rust-based, dynamic command
    # generator for Drive/Gmail/Calendar/etc. Pulled from upstream flake.
    googleworkspace-cli.url = "github:googleworkspace/cli";
    # awesome-git = {
    #   url = "github:awesomeWM/awesome";
    #   flake = false;
    # };
  };

  outputs = { self, nixpkgs, nix-ai-tools, kimi-cli, claude-desktop, googleworkspace-cli, ... }: {
    nixosConfigurations = {
      # Multiple host configurations - nixos-rebuild automatically uses current hostname
      samsung-laptop-personal = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit nix-ai-tools kimi-cli googleworkspace-cli; };
        modules = [
          ./configuration.nix
          { nixpkgs.overlays = [ claude-desktop.overlays.default ]; }
        ];
      };

      # Beelink desktop configuration
      beelink-ser8-desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit nix-ai-tools kimi-cli googleworkspace-cli; };
        modules = [
          ./configuration.nix
          { nixpkgs.overlays = [ claude-desktop.overlays.default ]; }
        ];
      };

      # Default fallback configuration
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit nix-ai-tools kimi-cli googleworkspace-cli; };
        modules = [
          ./configuration.nix
          { nixpkgs.overlays = [ claude-desktop.overlays.default ]; }
        ];
      };
    };
  };

}
