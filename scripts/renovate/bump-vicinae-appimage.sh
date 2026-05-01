#!/usr/bin/env bash
# Called from Renovate postUpgradeTasks after the version regex in vicinae.nix bumps.
# Recomputes fetchurl.url + fixed-output hash (SRI) for the AppImage — same idea as nix-update for fetchurl blobs.
set -euo pipefail

ver="${1:?usage: bump-vicinae-appimage.sh <semver>}"
nixfile="${2:-pkgs/appimages/vicinae.nix}"
url="https://github.com/vicinaehq/vicinae/releases/download/v${ver}/Vicinae-x86_64.AppImage"

tmp="$(mktemp)"
trap 'rm -f "${tmp:?}"' EXIT
curl -sfL "${url}" -o "${tmp}"
sri="$(nix hash file "${tmp}" --sri)"

export VERSION="${ver}"
export FETCH_URL="${url}"
export FETCH_HASH="${sri}"

perl -0777 -i -pe '
  s/version\s*=\s*"[^"]*"\s*;/version = "$ENV{VERSION}";/;
  s/url\s*=\s*"[^"]*"\s*;/url = "$ENV{FETCH_URL}";/;
  s/hash\s*=\s*"[^"]*"\s*;/hash = "$ENV{FETCH_HASH}";/;
' "${nixfile}"
