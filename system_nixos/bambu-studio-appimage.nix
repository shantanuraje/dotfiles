# BambuStudio - AppImage wrapper for NixOS
#
# The nixpkgs source-built bambu-studio package has a broken OAuth login
# because the proprietary libbambu_networking.so plugin (downloaded at
# runtime) is compiled for Ubuntu and crashes with ABI incompatibility
# on NixOS (free(): invalid pointer, missing libstdc++/libz).
#
# This package wraps the official Ubuntu 24.04 AppImage instead, which
# bundles compatible libraries. Login and cloud features work correctly.
#
# To update: change version/URL and run nix-prefetch-url on the new
# AppImage URL, then convert hash with: nix-hash --type sha256 --to-sri <hash>
#
# Tracking issues:
#   https://github.com/NixOS/nixpkgs/issues/440951  (login crash)
#   https://github.com/NixOS/nixpkgs/issues/391622  (network library)
#   https://discourse.nixos.org/t/bambu-studio-any-working-method/62272

{ appimageTools, fetchurl, cacert, glib-networking }:

let
  pname = "bambu-studio";
  version = "02.06.00.51";
  # Upstream changed the AppImage naming convention and no longer ships Ubuntu
  # builds for v02.05.00.67 — this asset name includes a build timestamp suffix.
  appimageBuildId = "20260417160415";
in
appimageTools.wrapType2 {
  inherit pname version;

  src = fetchurl {
    url = "https://github.com/bambulab/BambuStudio/releases/download/v${version}/BambuStudio_ubuntu-24.04-v${version}-${appimageBuildId}.AppImage";
    hash = "sha256-CYePefJ7FXcAK+OXsIaNRHkml18BA7um4W2+f6l49zQ=";
  };

  profile = ''
    export SSL_CERT_FILE="${cacert}/etc/ssl/certs/ca-bundle.crt"
    export GIO_MODULE_DIR="${glib-networking}/lib/gio/modules/"
    export WEBKIT_DISABLE_DMABUF_RENDERER=1
  '';

  extraPkgs = pkgs: with pkgs; [
    cacert
    curl
    glib
    glib-networking
    webkitgtk_4_1
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
  ];

  meta = {
    description = "Bambu Studio - 3D printer slicer for Bambu Lab printers (AppImage)";
    homepage = "https://github.com/bambulab/BambuStudio";
    platforms = [ "x86_64-linux" ];
    mainProgram = "bambu-studio";
  };
}
