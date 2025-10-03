{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-ai-tools.url = "github:numtide/nix-ai-tools";
    # awesome-git = {
    #   url = "github:awesomeWM/awesome";
    #   flake = false;
    # };
  };

  outputs = { self, nixpkgs, nix-ai-tools, ... }: {
    nixosConfigurations = {
      # Multiple host configurations - nixos-rebuild automatically uses current hostname
      samsung-laptop-personal = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit nix-ai-tools; };
        modules = [
          ./configuration.nix
        ];
      };
      
      # Beelink desktop configuration
      beelink-ser8-desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit nix-ai-tools; };
        modules = [
          ./configuration.nix
        ];
      };
      
      # Default fallback configuration
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit nix-ai-tools; };
        modules = [
          ./configuration.nix
        ];
      };
    };
  };

  # outputs = { self, nixpkgs, claude-desktop-linux-flake, ... }: {
  #   nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
  #     system = "x86_64-linux";
  #     specialArgs = { inherit claude-desktop-linux-flake; };
  #     modules = [ 
  #       ./configuration.nix 
  #       ({ pkgs, ... }: {
  #         nixpkgs.overlays = [
  #           (final: prev: {
  #             awesome-git = prev.awesome.overrideAttrs {
  #               src = awesome-git;
  #               version = "git";
  #             };
  #           })
  #     ];
  #   };
  # };
}
