{ pkgs }:

let
  version = "0.2.9";
  feed = "https://github.com/Niko1221/Strata/releases/download/v${version}";
in
{
  inherit version feed;

  installer = pkgs.fetchurl {
    url = "${feed}/install.sh";
    hash = "sha256-ZcOPgrt4Df66L0yR6c+TJgdtllZuo4gGP1rWVb3fH0M=";
  };

  vector = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/Niko1221/Strata/c62d5e3a15b40ea51c96aae9e8d36928965f53ab/data/experimental-speed-projection/Qwen3.8-Flash-Next-experimental-speed-projection.gguf";
    hash = "sha256-7wckxbeSl+SBAXvoV2mDK8JusiDJhOy6Kw4bDIQmMSs=";
  };

  desktop = pkgs.stdenvNoCC.mkDerivation {
    pname = "strata-desktop";
    inherit version;
    src = pkgs.fetchurl {
      url = "${feed}/Strata.app.tar.gz";
      hash = "sha256-vAEG6le0dRpckvuD+jcpYLTdpzz1gZ4kpsmIDJ1UdBQ=";
    };
    dontUnpack = true;
    # Preserve the publisher's signed app bundle.
    dontFixup = true;
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/Applications"
      tar -xzf "$src" -C "$out/Applications"
      runHook postInstall
    '';
    meta = {
      description = "Official Strata desktop client";
      homepage = "https://github.com/Niko1221/Strata";
      license = pkgs.lib.licenses.mit;
      platforms = [ "aarch64-darwin" ];
      sourceProvenance = [ pkgs.lib.sourceTypes.binaryNativeCode ];
    };
  };
}
