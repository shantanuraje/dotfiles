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
    nixosConfigurations.samsung-laptop-personal = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit claude-desktop-linux-flake; };
      modules = [
        ./configuration.nix
		#       ({ pkgs, ... }: {
		#         nixpkgs.overlays = [
		#           (final: prev: {
		#             awesome-git = prev.awesome.overrideAttrs (oldAttrs: {
		#               src = awesome-git;
		#               version = "git";
		# patches = [];
		#        cmakeFlags = (oldAttrs.cmakeFlags or []) ++ [
		#                 "-DGENERATE_DOC=OFF"
		#                 "-DGENERATE_MANPAGES=OFF"
		#   #"-DLUA_LIBRARY=${prev.lua5_3}/lib/liblua.so"
		#               ];
		# #NIX_CFLAGS_COMPILE = "-DAWESOME_IGNORE_LGI=1";
		#               dontBuild = false;
		#        #buildInputs = (builtins.filter (pkg: !(prev.lib.hasPrefix "lua" pkg.name or ""))
		#      #oldAttrs.buildInputs) ++ [
		#          #prev.lua5_3  # Use Lua 5.3 instead of 5.2
		#        #];
		#        # Make sure cmake finds the right Lua
		#        #cmakeFlags = old.cmakeFlags ++ [ "-DLUA_LIBRARY=${prev.lua5_3}/lib/liblua.so" ];		
		# buildPhase = ''
		#                 make awesome
		#               '';
		#             });
		#           })
		#         ];
		#       })
      ];
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
