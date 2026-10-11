{
  lib,
  stdenv,
  fetchurl,
  undmg,
  asar,
  nodejs,
  re-plistbuddy,
  darwin,
}:

stdenv.mkDerivation {
  pname = "openscreen";
  version = "1.10.0-pr370";

  src = fetchurl {
    url = "https://github.com/getopenscreen/openscreen/releases/download/v1.10.0/Openscreen-macOS-Apple-Silicon-1.10.0.dmg";
    hash = "sha256-AjB/HTYcmDEpQ6gHoM5A2AfG932VCmG6EWH3jY7QUAk=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [
    asar
    darwin.sigtool
    nodejs
    re-plistbuddy
    undmg
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/Applications"
    cp -R Openscreen.app "$out/Applications/"

    app="$out/Applications/Openscreen.app"
    resources="$app/Contents/Resources"
    unpacked="$TMPDIR/openscreen-asar"
    chmod -R u+w "$app"

    asar extract "$resources/app.asar" "$unpacked"
    mapfile -t captioningBundles < <(
      grep -rlF '../exporter/wasm/web-demuxer.wasm' "$unpacked/dist/assets"
    )
    if [ "''${#captioningBundles[@]}" -ne 1 ]; then
      echo "expected exactly one captioning bundle with the broken WASM path" >&2
      exit 1
    fi
    substituteInPlace "''${captioningBundles[0]}" \
      --replace-fail '../exporter/wasm/web-demuxer.wasm' './wasm/web-demuxer.wasm'

    asar pack "$unpacked" "$resources/app.asar"

    asarHeaderHash="$(${nodejs}/bin/node -e '
      const crypto = require("crypto");
      const fs = require("fs");
      const archive = fs.readFileSync(process.argv[1]);
      const headerLength = archive.readUInt32LE(12);
      const header = archive.subarray(16, 16 + headerLength);
      process.stdout.write(crypto.createHash("sha256").update(header).digest("hex"));
    ' "$resources/app.asar")"
    PlistBuddy -c \
      "Set :ElectronAsarIntegrity:Resources/app.asar:hash $asarHeaderHash" \
      "$app/Contents/Info.plist"

    codesign --force --sign - "$app/Contents/MacOS/Openscreen"

    mkdir -p "$out/bin"
    ln -s "$app/Contents/MacOS/Openscreen" "$out/bin/openscreen"

    runHook postInstall
  '';

  meta = {
    description = "Free, open-source screen recorder and editor with the PR #370 transcription fix";
    homepage = "https://getopenscreen.com";
    changelog = "https://github.com/getopenscreen/openscreen/releases/tag/v1.10.0";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    mainProgram = "openscreen";
    platforms = [ "aarch64-darwin" ];
  };
}
