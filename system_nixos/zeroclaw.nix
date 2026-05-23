# ZeroClaw - lightweight AI assistant infrastructure
# Pre-built binary from GitHub releases (upstream flake is broken)
# https://github.com/zeroclaw-labs/zeroclaw

{ lib, stdenv, fetchurl, autoPatchelfHook, openssl, gcc }:

stdenv.mkDerivation rec {
  pname = "zeroclaw";
  version = "0.7.5";

  src = fetchurl {
    url = "https://github.com/zeroclaw-labs/zeroclaw/releases/download/v${version}/zeroclaw-x86_64-unknown-linux-gnu.tar.gz";
    hash = "sha256-i8gnao2Prvs+SoJPM4dpKedGb2Mu58U2OTY2ihry5Pc=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ openssl gcc.cc.lib ];

  installPhase = ''
    install -Dm755 zeroclaw $out/bin/zeroclaw
  '';

  meta = with lib; {
    description = "Fast, small, and fully autonomous AI assistant infrastructure";
    homepage = "https://github.com/zeroclaw-labs/zeroclaw";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "zeroclaw";
  };
}
