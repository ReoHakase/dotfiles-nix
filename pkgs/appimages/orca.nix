{
  lib,
  fetchurl,
  appimageTools,
  stdenv,
  autoPatchelfHook,
  makeWrapper,
  pkgs,
}:

let
  pname = "orca-ide";
  version = "1.4.216";
  src = fetchurl {
    url = "https://github.com/stablyai/orca/releases/download/v${version}/orca-linux.AppImage";
    hash = "sha256-JWU6PuA+0pGKd4FPRBj9AOBGYnmZA2LSNm1N5IaQPFI=";
  };
  contents = appimageTools.extractType2 {
    inherit pname version src;
  };
in
stdenv.mkDerivation {
  inherit pname version;
  src = contents;
  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];
  # Ubuntu 24.04 restricts unprivileged namespaces, so wrapType2's bubblewrap
  # cannot start. Extract with appimageTools and patch ELF dependencies instead.
  buildInputs = (appimageTools.defaultFhsEnvArgs.multiPkgs pkgs) ++ [
    pkgs.gtk3
    pkgs.libsecret
    pkgs.libdbusmenu-gtk3
    stdenv.cc.cc.lib
  ];
  dontBuild = true;
  dontStrip = true;
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib/orca" "$out/bin"
    cp -a . "$out/lib/orca/"
    # Use the upstream CLI, not Electron's --version or desktop argument parser.
    makeWrapper "$out/lib/orca/resources/bin/orca-ide" "$out/bin/orca-ide" \
      --prefix PATH : ${
        lib.makeBinPath [
          pkgs.xorg-server
          pkgs.procps
          pkgs.git
          pkgs.systemd
        ]
      }
    runHook postInstall
  '';

  meta = {
    description = "Orca agent runtime and CLI (official AppImage)";
    homepage = "https://github.com/stablyai/orca";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "orca-ide";
  };
}
