{
  lib,
  stdenv,
  fetchurl,
  undmg,
}:

stdenv.mkDerivation {
  pname = "openscreen";
  version = "2.1.2";

  src = fetchurl {
    url = "https://github.com/getopenscreen/openscreen/releases/download/v2.1.2/Openscreen-macOS-Apple-Silicon-2.1.2.dmg";
    hash = "sha256-ExPTN2yiv/Xer/yBFOeGjkVF5blYKHc+MHbVahWnD04=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [ undmg ];
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/Applications"
    cp -R Openscreen.app "$out/Applications/"

    mkdir -p "$out/bin"
    ln -s "$out/Applications/Openscreen.app/Contents/MacOS/Openscreen" "$out/bin/openscreen"

    runHook postInstall
  '';

  meta = {
    description = "Free, open-source screen recorder and editor";
    homepage = "https://getopenscreen.com";
    changelog = "https://github.com/getopenscreen/openscreen/releases/tag/v2.1.2";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    mainProgram = "openscreen";
    platforms = [ "aarch64-darwin" ];
  };
}
