# pkgs/npm — npm 由来 CLI の in-tree オーバーレイ

nixpkgs 本家が追従しきれない npm 系 CLI を自前で pin するオーバーレイ。`flake.nix` の `pkgsLinux.overlays` と `hosts/reohakase.nix` の `nixpkgs.overlays` 両方で `import ./pkgs/npm` / `import ../pkgs/npm` として取り込まれ、`home/common.nix` の `home.packages` から `claude-code` / `codex` として参照される。

`pkgs.buildNpmPackage` は Nix サンドボックス内で nixpkgs の `nodejs` を使ってビルドし、ランタイム node も `/nix/store` にピンされるため、ユーザー側の mise (node/pnpm) の PATH 状況とは独立している。

## 収録パッケージ

| 名前 | 実装 | 上流 |
| --- | --- | --- |
| `claude-code` | `buildNpmPackage` | [`@anthropic-ai/claude-code`](https://www.npmjs.com/package/@anthropic-ai/claude-code) |
| `codex` | GitHub Releases の Rust prebuilt を `fetchurl` | [`openai/codex`](https://github.com/openai/codex/releases) |

`codex` は `@openai/codex` npm 自体が postinstall で Rust バイナリを取得する薄い wrapper なので、`buildNpmPackage` を挟まず素直に tarball を取得して設置している。

## bump 手順

### claude-code

1. `pkgs/npm/claude-code/package.nix` の `version` を最新に差し替える。
   - npm の最新は `npm view @anthropic-ai/claude-code version` で確認。
2. `src.hash` と `npmDepsHash` を `lib.fakeHash` (= `"sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="`) に一時置換する。
3. `pkgs/npm/claude-code/package-lock.json` を更新する。一番楽なのは nixpkgs master 側の同バージョンを拝借する方法:
   ```sh
   curl -fsSL https://raw.githubusercontent.com/NixOS/nixpkgs/master/pkgs/by-name/cl/claude-code/package-lock.json \
     -o pkgs/npm/claude-code/package-lock.json
   ```
   nixpkgs master がまだバージョンを追っていない場合は `npm install --package-lock-only --prefix /tmp/claude-bump @anthropic-ai/claude-code@<ver>` の出力からコピーする。
4. `nix build .#darwinConfigurations.reohakase.system` (もしくは個別に `nix build --impure --expr '(import <nixpkgs> { overlays = [ (import ./pkgs/npm) ]; }).claude-code'`) を走らせ、hash mismatch エラーから正しい `sha256-...=` を拾って貼り戻す。2 箇所同時には出ないので 2 回ビルドする。
5. 自動化する場合は [`nix-update`](https://github.com/Mic92/nix-update) を利用:
   ```sh
   nix run nixpkgs#nix-update -- \
     --flake claude-code \
     --version=<ver>
   ```

### codex

1. [Releases](https://github.com/openai/codex/releases/latest) で最新の `rust-v<ver>` を確認し、`pkgs/npm/codex/package.nix` の `version` を更新する。
2. 両プラットフォームの tarball sha256 を prefetch して SRI に変換:
   ```sh
   VER=<ver>
   for triple in aarch64-apple-darwin x86_64-unknown-linux-musl; do
     raw=$(nix-prefetch-url --type sha256 \
       "https://github.com/openai/codex/releases/download/rust-v${VER}/codex-${triple}.tar.gz")
     sri=$(nix --extra-experimental-features 'nix-command' hash convert \
       --hash-algo sha256 --to sri "${raw}")
     printf '%-30s %s\n' "${triple}" "${sri}"
   done
   ```
3. 出力された SRI を `platforms` attrset の該当 triple の `hash` に貼る。
4. `nix build .#darwinConfigurations.reohakase.system` で確認。

## 動作確認

ビルド後:

```sh
claude --version   # 最新の claude-code バージョン
codex --version    # 最新の codex バージョン
which claude codex # /nix/store/... 配下にあること(mise shim ではない)
```
