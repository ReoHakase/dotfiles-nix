#!/usr/bin/env bash
# Create or reuse an ed25519 GPG key for the effective git identity, register it
# in ~/.config/git/local, and upload the public key to GitHub with gh.
set -euo pipefail

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

log() {
  printf '[register-gpg-key] %s\n' "$*"
}

need_cmd() {
  log "Checking command: $1"
  command -v "$1" >/dev/null 2>&1 || die "missing command: $1"
}

find_ed25519_fingerprint() {
  local email="$1"
  {
    gpg --batch --list-secret-keys --with-colons --fingerprint "$email" 2>/dev/null || true
  } | awk -F: '
      $1 == "sec" { ed25519 = ($4 == "22") }
      ed25519 && $1 == "fpr" { print $10; exit }
    '
}

need_cmd awk
need_cmd gh
need_cmd git
need_cmd gpg
need_cmd grep
need_cmd mktemp

log "Checking GitHub CLI authentication"
gh auth status >/dev/null
log "GitHub CLI authentication is available"

log "Reading git identity"
git_name="$(git config --get user.name || true)"
git_email="$(git config --get user.email || true)"

[[ -n "$git_name" ]] || die "git user.name is not set"
[[ -n "$git_email" ]] || die "git user.email is not set"
log "Using git user.name: $git_name"
log "Using git user.email: $git_email"

log "Searching for an existing ed25519 secret key for $git_email"
fingerprint="$(find_ed25519_fingerprint "$git_email")"

if [[ -z "$fingerprint" ]]; then
  log "No matching ed25519 secret key found"
  log "Creating ed25519 GPG key for $git_name <$git_email>"
  gpg --quick-generate-key "${git_name} <${git_email}>" ed25519 sign 0
  log "Re-reading generated key fingerprint"
  fingerprint="$(find_ed25519_fingerprint "$git_email")"
else
  log "Reusing existing ed25519 secret key: $fingerprint"
fi

[[ -n "$fingerprint" ]] || die "could not find an ed25519 secret key for $git_email"

log "Writing signing config to ~/.config/git/local"
mkdir -p ~/.config/git
git config --file ~/.config/git/local user.signingKey "$fingerprint"
git config --file ~/.config/git/local commit.gpgSign true

log "Preparing public key export"
public_key_file="$(mktemp)"
trap 'rm -f "$public_key_file"' EXIT

gpg --armor --export "$fingerprint" >"$public_key_file"
log "Exported public key to a temporary file"

title="$(hostname -s 2>/dev/null || hostname)-${git_email}-gpg"
key_id="${fingerprint: -16}"
log "Checking whether GitHub already has GPG key $key_id"
if gh api user/gpg_keys --jq '.[].key_id' | grep -Fxq "$key_id"; then
  log "GitHub already has GPG key $key_id; skipping upload"
else
  log "Uploading public GPG key to GitHub as \"$title\""
  gh gpg-key add "$public_key_file" --title "$title"
  log "Uploaded public GPG key to GitHub"
fi

printf '\nRegistered GPG signing key:\n'
printf '  user.email: %s\n' "$git_email"
printf '  user.signingKey: %s\n' "$fingerprint"
printf '  local config: ~/.config/git/local\n'
