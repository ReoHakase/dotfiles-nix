#!/usr/bin/env bash
# Dev Containers dotfiles entrypoint.
# This script assumes Nix and Home Manager are already installed.
set -euo pipefail

LOG_PREFIX="[ReoHakase/dotfiles-nix]"
REPOSITORY_URL="https://github.com/ReoHakase/dotfiles-nix"

prefix_stream() {
  while IFS= read -r line; do
    printf '%s %s\n' "$LOG_PREFIX" "$line"
  done
}

log() {
  printf '%s %s\n' "$LOG_PREFIX" "$*" >&2
}

die() {
  log "dotfiles install: $*"
  exit 1
}

log "repository: ${REPOSITORY_URL}"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
user_name="$(id -un 2>/dev/null || true)"

if [ -z "$user_name" ]; then
  die "could not determine the current user with 'id -un'."
fi

path_prefix=(
  "/etc/profiles/per-user/${user_name}/bin"
  "/nix/var/nix/profiles/default/bin"
)

if [ -n "${HOME:-}" ]; then
  path_prefix=("${HOME}/.nix-profile/bin" "${path_prefix[@]}")
fi

export PATH="$(IFS=:; printf '%s' "${path_prefix[*]}"):${PATH:-}"

command -v nix >/dev/null 2>&1 ||
  die "nix was not found in PATH. Install Nix with flakes enabled before running Dev Containers dotfiles; this script does not install Nix."

command -v home-manager >/dev/null 2>&1 ||
  die "home-manager was not found in PATH. Install Home Manager before running Dev Containers dotfiles; this script does not install Home Manager."

if [ -n "${DOTFILES_HM_OUTPUT:-}" ]; then
  resolved_output="$DOTFILES_HM_OUTPUT"
  resolution_source="DOTFILES_HM_OUTPUT"
else
  host_name="$(hostname -s 2>/dev/null || true)"

  if [ -z "$host_name" ]; then
    host_name="$(hostname 2>/dev/null || true)"
  fi

  if [ -z "$host_name" ]; then
    die "could not determine the current hostname with 'hostname -s'. Set DOTFILES_HM_OUTPUT to a homeConfigurations output."
  fi

  resolved_output="${user_name}@${host_name}"
  resolution_source="current user and hostname"
fi

if ! available_outputs="$(
  nix eval --raw \
    --apply 'attrs: builtins.concatStringsSep "\n" (builtins.attrNames attrs)' \
    "${repo_root}#homeConfigurations" \
    2> >(prefix_stream >&2)
)"; then
  die "failed to inspect homeConfigurations in ${repo_root}."
fi

if ! printf '%s\n' "$available_outputs" | grep -Fqx -- "$resolved_output"; then
  {
    log "dotfiles install: homeConfigurations.${resolved_output} was not found."
    log "dotfiles install: resolved from ${resolution_source}."
    log "dotfiles install: set DOTFILES_HM_OUTPUT to one of the available outputs or add a matching flake output."
    log "dotfiles install: available homeConfigurations:"

    if [ -n "$available_outputs" ]; then
      printf '%s\n' "$available_outputs" | sed 's/^/  /' | prefix_stream >&2
    else
      printf '  (none)\n' | prefix_stream >&2
    fi
  }
  exit 1
fi

log "dotfiles install: using homeConfigurations.${resolved_output}"
log "dotfiles install: running home-manager switch"

set +e
home-manager switch -b hm-backup --flake "${repo_root}#${resolved_output}" 2>&1 | prefix_stream
status=${PIPESTATUS[0]}
set -e

exit "$status"
