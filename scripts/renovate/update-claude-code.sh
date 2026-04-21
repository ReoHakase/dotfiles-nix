#!/usr/bin/env bash
# Renovate の postUpgradeTasks から呼ばれる。
#   引数1: 新しい @anthropic-ai/claude-code のバージョン (例: 2.1.113)
#
# やること:
#   1. npm registry から該当バージョンの tarball を拾って展開し、`npm install --package-lock-only`
#      で pkgs/npm/claude-code/package-lock.json を再生成する。
#   2. `nix-update --flake claude-code --version <ver>` で
#      package.nix の version / src.hash / npmDepsHash を一括書き換える。
#
# 手動 bump したいときもこのスクリプトを直接叩けば OK。
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "usage: $0 <new-version>" >&2
  exit 64
fi

NEW_VERSION="$1"
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PKG_DIR="${REPO_ROOT}/pkgs/npm/claude-code"
TARGET_LOCK="${PKG_DIR}/package-lock.json"

cd "${REPO_ROOT}"

echo "[claude-code] bump to ${NEW_VERSION}"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT

# npm registry から tarball を取得して展開する。
TARBALL_URL="https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${NEW_VERSION}.tgz"
echo "[claude-code] fetching ${TARBALL_URL}"
curl -fsSL "${TARBALL_URL}" -o "${WORK_DIR}/pkg.tgz"

mkdir -p "${WORK_DIR}/pkg"
tar -xzf "${WORK_DIR}/pkg.tgz" -C "${WORK_DIR}/pkg" --strip-components=1

# 展開した package.json を元に package-lock.json を再生成。
# --ignore-scripts で postinstall を走らせない (bubblewrap 等に依存しないため)。
pushd "${WORK_DIR}/pkg" >/dev/null
npm install --package-lock-only --ignore-scripts --no-audit --no-fund
popd >/dev/null

install -m 0644 "${WORK_DIR}/pkg/package-lock.json" "${TARGET_LOCK}"
echo "[claude-code] wrote ${TARGET_LOCK}"

# nix-update は package.nix 内の version / src.hash / npmDepsHash を
# lib.fakeHash 経由で新しいハッシュに置換してくれる。
# --flake を使う場合、対応するフレーク出力が要る。ここでは overlay 越しの
# 評価を避けるため、代替として nixpkgs (empty overlay) 上で再評価させる。
echo "[claude-code] running nix-update"
nix-update \
  --flake \
  --version "${NEW_VERSION}" \
  claude-code

echo "[claude-code] done"
