{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    claude-desktop-linux-flake.url = "github:k3d3/claude-desktop-linux-flake";
    # awesome-git = {
    #   url = "github:awesomeWM/awesome";
    #   flake = false;
    # };
  };

  outputs = { self, nixpkgs, claude-desktop-linux-flake, ... }: {
    nixosConfigurations = {
      # Multiple host configurations - nixos-rebuild automatically uses current hostname
      samsung-laptop-personal = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit claude-desktop-linux-flake; };
        modules = [
          ./configuration.nix
        ];
      };
      
      # Add other hosts here as needed
      # work-machine = nixpkgs.lib.nixosSystem {
      #   system = "x86_64-linux";
      #   specialArgs = { inherit claude-desktop-linux-flake; };
      #   modules = [
      #     ./configuration.nix
      #   ];
      # };
      
      # Default fallback configuration
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit claude-desktop-linux-flake; };
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
