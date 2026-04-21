#!/usr/bin/env bash
# Renovate の postUpgradeTasks から呼ばれる。
#   引数1: 新しい openai/codex のバージョン (例: 0.123.0)
#
# codex は 2 つの triple ごとに個別の tarball を持つので `nix-update --flake`
# では src.hash を書き換えきれない。素直に sed で version 行を書き換えつつ、
# triple ごとに nix-prefetch-url + SRI 変換で hash を計算して差し込む。
#
# 手動 bump したいときもこのスクリプトを直接叩けば OK。
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "usage: $0 <new-version>" >&2
  exit 64
fi

NEW_VERSION="$1"
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PKG_NIX="${REPO_ROOT}/pkgs/npm/codex/package.nix"

cd "${REPO_ROOT}"

echo "[codex] bump to ${NEW_VERSION}"

# `platforms` attrset で扱う triple 一覧。package.nix と一致させること。
TRIPLES=(
  "aarch64-apple-darwin"
  "x86_64-unknown-linux-musl"
)

# let 配下の `version = "..."` 行のみを書き換える (1 箇所しかない想定)。
sed -i.bak -E "s|^(  version = \")[^\"]+(\";)|\\1${NEW_VERSION}\\2|" "${PKG_NIX}"
rm -f "${PKG_NIX}.bak"
echo "[codex] updated version line"

# triple 別に SRI hash を計算して差し込む。
for triple in "${TRIPLES[@]}"; do
  url="https://github.com/openai/codex/releases/download/rust-v${NEW_VERSION}/codex-${triple}.tar.gz"
  echo "[codex] prefetch ${url}"
  raw_hash="$(nix-prefetch-url --type sha256 "${url}")"
  sri_hash="$(nix --extra-experimental-features 'nix-command' hash convert \
    --hash-algo sha256 --to sri "${raw_hash}")"

  echo "[codex] ${triple} -> ${sri_hash}"

  # `triple = "<triple>";` の次に来る `hash = "...";` を書き換える。
  # awk で triple ブロックを検出し、直近の hash 行だけを置換する。
  tmp="$(mktemp)"
  awk -v triple="${triple}" -v newhash="${sri_hash}" '
    {
      if ($0 ~ "triple = \"" triple "\";") {
        in_block = 1
      }
      if (in_block && $0 ~ /hash = "sha256-[A-Za-z0-9+\/=]+";/) {
        sub(/hash = "sha256-[A-Za-z0-9+\/=]+";/, "hash = \"" newhash "\";")
        in_block = 0
      }
      print
    }
  ' "${PKG_NIX}" > "${tmp}"
  mv "${tmp}" "${PKG_NIX}"
done

echo "[codex] done"
