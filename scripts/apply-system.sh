#!/usr/bin/env bash
# Apply nix-darwin + home-manager for this flake (requires administrator password once).
# sudo -H sets root's HOME to /var/root so Nix does not warn about owning $HOME.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="/nix/var/nix/profiles/default/bin:${PATH:-}"
exec sudo -H env PATH="$PATH" \
  nix run nix-darwin --extra-experimental-features 'nix-command flakes' -- \
  switch --flake "${ROOT}#reohakase"
