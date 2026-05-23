# OpenCode Desktop - AI coding assistant (Electron app)
# Pre-built binary from GitHub releases
# https://github.com/anomalyco/opencode
#
# Note: as of v1.14 the upstream switched from a Tauri/WebKitGTK single binary
# (usr/bin/OpenCode) to a bundled Electron/Chromium app at /opt/OpenCode/.
# We unpack the .deb, autopatchelf the bundled libraries, and wrap the launch
# binary with --no-sandbox (NixOS forbids SUID inside the nix store, so the
# vendored chrome-sandbox can't be used).

{ lib, stdenv, fetchurl, dpkg, autoPatchelfHook, makeWrapper
, glib, nss, nspr, atk, at-spi2-atk, at-spi2-core, cups, dbus, expat
, libdrm, mesa, libxkbcommon, libnotify, pango, cairo, gtk3, gdk-pixbuf
, alsa-lib, gcc
, xorg
}:

stdenv.mkDerivation rec {
  pname = "opencode-desktop";
  version = "1.14.43";

  src = fetchurl {
    url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-desktop-linux-amd64.deb";
    hash = "sha256-Y+QpPZJRv7QXH/PVKqvFOjBPYJEo8cYU3KvpZ169CMY=";
  };

  nativeBuildInputs = [ dpkg autoPatchelfHook makeWrapper ];

  # Native node addons ship both glibc and musl variants in node_modules; only
  # the glibc ones are loaded on this system, but autopatchelf scans them all.
  autoPatchelfIgnoreMissingDeps = [ "libc.musl-x86_64.so.1" ];

  buildInputs = [
    glib nss nspr atk at-spi2-atk at-spi2-core cups dbus expat
    libdrm mesa libxkbcommon libnotify pango cairo gtk3 gdk-pixbuf
    alsa-lib gcc.cc.lib
    xorg.libX11 xorg.libXcomposite xorg.libXdamage xorg.libXext
    xorg.libXfixes xorg.libXrandr xorg.libxcb xorg.libxshmfence
  ];

  unpackPhase = ''
    dpkg-deb -x $src .
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/opt $out/share $out/bin
    cp -r opt/OpenCode $out/opt/
    cp -r usr/share/* $out/share/

    # SUID chrome-sandbox can't live in the nix store; remove and rely on --no-sandbox
    rm -f $out/opt/OpenCode/chrome-sandbox

    # Wrapper script — vendored Electron binary, --no-sandbox required without
    # a system-level security wrapper. The binary name has an `@` prefix.
    makeWrapper "$out/opt/OpenCode/@opencode-aidesktop" "$out/bin/opencode-desktop" \
      --add-flags "--no-sandbox"

    # Fix .desktop file Exec path
    substituteInPlace $out/share/applications/@opencode-aidesktop.desktop \
      --replace-fail '"/opt/OpenCode/@opencode-aidesktop"' "$out/bin/opencode-desktop"
    runHook postInstall
  '';

  meta = with lib; {
    description = "OpenCode Desktop - AI coding assistant";
    homepage = "https://github.com/anomalyco/opencode";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "opencode-desktop";
  };
}
