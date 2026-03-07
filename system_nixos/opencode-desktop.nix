# OpenCode Desktop - AI coding assistant (Tauri/WebKitGTK app)
# Pre-built binary from GitHub releases (desktop beta)
# https://github.com/anomalyco/opencode

{ lib, stdenv, fetchurl, dpkg, autoPatchelfHook, wrapGAppsHook3
, gtk3, webkitgtk_4_1, libsoup_3, glib, gdk-pixbuf, cairo, gcc
, copyDesktopItems
}:

stdenv.mkDerivation rec {
  pname = "opencode-desktop";
  version = "1.2.21";

  src = fetchurl {
    url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-desktop-linux-amd64.deb";
    hash = "sha256-8mDUsKjBBRO0Lp81BHjwYGLGQFw5Zk6IieyFUK+axzg=";
  };

  nativeBuildInputs = [ dpkg autoPatchelfHook wrapGAppsHook3 ];

  buildInputs = [
    gtk3
    webkitgtk_4_1
    libsoup_3
    glib
    gdk-pixbuf
    cairo
    gcc.cc.lib
  ];

  unpackPhase = ''
    dpkg-deb -x $src .
  '';

  installPhase = ''
    mkdir -p $out/bin $out/share
    cp -r usr/share/* $out/share/
    install -Dm755 usr/bin/OpenCode $out/bin/OpenCode

    # Fix .desktop file paths
    substituteInPlace $out/share/applications/OpenCode.desktop \
      --replace-fail "Exec=OpenCode" "Exec=$out/bin/OpenCode"
  '';

  meta = with lib; {
    description = "OpenCode Desktop - AI coding assistant";
    homepage = "https://github.com/anomalyco/opencode";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "OpenCode";
  };
}
