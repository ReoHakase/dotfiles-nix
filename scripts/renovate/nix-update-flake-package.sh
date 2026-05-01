#!/usr/bin/env bash
# Linux CI（Renovate）向け。flake の packages.* 属性を nix-update で更新する。
# fetchurl/vendorHash/npmDepsHash など nix-update が認識するフィールドまでまとめて直す。
# 例: nix-update-flake-package.sh vicinae-appimage
set -euo pipefail

attr="${1:?usage: nix-update-flake-package.sh <flake-package-attr> [version-arg for nix-update --version]}" 
version_opt=()
if (($# >= 2)); then
  version_opt+=(--version "$2")
fi

exec nix run nixpkgs#nix-update -- -F \
  --system "${NIX_UPDATER_SYSTEM:-x86_64-linux}" \
  "${attr}" \
  "${version_opt[@]}"
