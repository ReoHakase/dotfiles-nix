# @anthropic-ai/claude-code を in-tree で `buildNpmPackage` する。
# nixpkgs master の `pkgs/by-name/cl/claude-code/package.nix` をほぼそのまま踏襲。
# bump 手順は `pkgs/npm/README.md` 参照。
{
  lib,
  stdenv,
  buildNpmPackage,
  fetchzip,
  versionCheckHook,
  writableTmpDirAsHomeHook,
  bubblewrap,
  procps,
  socat,
}:
buildNpmPackage (finalAttrs: {
  pname = "claude-code";
  version = "2.1.112";

  src = fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${finalAttrs.version}.tgz";
    hash = "sha256-SJJqU7XHbu9IRGPMJNUg6oaMZiQUKqJhI2wm7BnR1gs=";
  };

  npmDepsHash = "sha256-bdkej9Z41GLew9wi1zdNX+Asauki3nT1+SHmBmaUIBU=";

  strictDeps = true;

  postPatch = ''
    cp ${./package-lock.json} package-lock.json

    # https://github.com/anthropics/claude-code/issues/15195
    substituteInPlace cli.js \
      --replace-fail '#!/bin/sh' '#!/usr/bin/env sh'
  '';

  dontNpmBuild = true;

  env.AUTHORIZED = "1";

  # `claude-code` は既定で自動更新を試みるためここで封じる。
  # https://docs.anthropic.com/en/docs/agents-and-tools/claude-code/overview#environment-variables
  # `DEV=true` が残ると `TypeError: window.WebSocket is not a constructor` で落ちるため除去。
  postInstall = ''
    wrapProgram $out/bin/claude \
      --set DISABLE_AUTOUPDATER 1 \
      --set-default FORCE_AUTOUPDATE_PLUGINS 1 \
      --set DISABLE_INSTALLATION_CHECKS 1 \
      --unset DEV \
      --prefix PATH : ${
        lib.makeBinPath (
          [
            # node-tree-kill が darwin では pgrep、linux では ps を要求する
            procps
          ]
          ++ lib.optionals stdenv.hostPlatform.isLinux [
            bubblewrap
            socat
          ]
        )
      }
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [
    writableTmpDirAsHomeHook
    versionCheckHook
  ];
  versionCheckKeepEnvironment = [ "HOME" ];

  meta = {
    description = "Agentic coding tool that lives in your terminal, understands your codebase, and helps you code faster";
    homepage = "https://github.com/anthropics/claude-code";
    downloadPage = "https://www.npmjs.com/package/@anthropic-ai/claude-code";
    license = lib.licenses.unfree;
    mainProgram = "claude";
    sourceProvenance = with lib.sourceTypes; [ binaryBytecode ];
  };
})
