# OpenAI Codex CLI を upstream の GitHub Releases の prebuilt Rust バイナリから入れる。
# `@openai/codex` npm は postinstall で同じ tarball を取得する wrapper なので、
# ここでは素直にプラットフォーム別の tarball を `fetchurl` して展開する。
# bump 手順は `pkgs/npm/README.md` 参照。
{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.122.0";

  platforms = {
    "aarch64-darwin" = {
      triple = "aarch64-apple-darwin";
      hash = "sha256-dOaIXhpY148CSfrtEm62qyIPnONOdiP55BCCVQNdYcw=";
    };
    "x86_64-linux" = {
      triple = "x86_64-unknown-linux-musl";
      hash = "sha256-kQ8l0akiLew5tTG/4VZCK1qgr6ne85Gu7hP7F2lu66Q=";
    };
  };

  platform =
    platforms.${stdenv.hostPlatform.system}
      or (throw "codex: unsupported platform ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "codex";
  inherit version;

  src = fetchurl {
    url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-${platform.triple}.tar.gz";
    inherit (platform) hash;
  };

  sourceRoot = ".";

  dontConfigure = true;
  dontBuild = true;
  # Rust static binary。macOS は Mach-O、linux は musl static のためパッチ不要。
  dontStrip = true;
  dontPatchELF = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 codex-${platform.triple} $out/bin/codex
    runHook postInstall
  '';

  meta = {
    description = "Lightweight coding agent that runs in your terminal";
    homepage = "https://github.com/openai/codex";
    license = lib.licenses.asl20;
    mainProgram = "codex";
    platforms = builtins.attrNames platforms;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
