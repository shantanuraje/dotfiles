# RealVNC Server package definition
# Downloads and installs RealVNC Server from official .deb package

{ pkgs }:

let
  # RealVNC Server deb file - fetched from official source
  realvncDebPath = pkgs.fetchurl {
    url = "https://downloads.realvnc.com/download/file/vnc.files/VNC-Server-7.16.0-Linux-x64.deb";
    sha256 = "0hpdlc3apld991vn7i4c9yfjd4vsqpc8ka1k6gjs33020r8is0jk";
  };
in
pkgs.stdenv.mkDerivation rec {
  pname = "realvnc-server";
  version = "7.16.0";

  src = realvncDebPath;

  nativeBuildInputs = with pkgs; [
    dpkg
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = with pkgs; [
    xorg.libX11
    xorg.libXext
    xorg.libXtst
    xorg.libXfixes
    xorg.libXdamage
    xorg.libXrandr
    xorg.libXcursor
    xorg.libXi
    xorg.libXrender
    gtk2-x11
    glib
    libGL
    systemd
    pam
    cups
    zlib
    libgcrypt
    stdenv.cc.cc.lib
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src . || true
    dpkg-deb --fsys-tarfile $src | tar -x --no-same-permissions --no-same-owner
    runHook postUnpack
  '';

  installPhase = ''
    mkdir -p $out
    cp -r usr/* $out/

    # Fix setuid binaries (NixOS doesn't allow setuid in nix store)
    chmod -s $out/bin/Xvnc || true
    chmod -s $out/bin/vncserver-x11 || true

    # Create wrappers for binaries that might need PATH
    for binary in $out/bin/*; do
      if [ -f "$binary" ] && [ -x "$binary" ]; then
        wrapProgram "$binary" --prefix PATH : $out/bin || true
      fi
    done
  '';

  meta = with pkgs.lib; {
    description = "RealVNC Server - Remote access software";
    homepage = "https://www.realvnc.com/";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
}
