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

## Renovate による自動 bump

`.github/workflows/renovate.yml` が毎日 03:00 JST に self-hosted Renovate を起動し、下記 3 つを PR として開く。

- `flake.lock` の週次 `lockFileMaintenance` (月曜のみ)
- `pkgs/npm/claude-code/package.nix` の `version` を npm registry と突き合わせ、
  更新があれば `scripts/renovate/update-claude-code.sh` が post-upgrade task として走り、
  `package-lock.json` を再生成 → `nix-update` が `src.hash` / `npmDepsHash` を置換する。
- `pkgs/npm/codex/package.nix` の `version` を `openai/codex` の `rust-v*` Release と突き合わせ、
  `scripts/renovate/update-codex.sh` が各 triple の SRI hash を prefetch して差し込む。

設定は [.github/renovate.json5](../../.github/renovate.json5)。手動 bump したいときも同じスクリプトを呼ぶのが最短:

```sh
bash scripts/renovate/update-claude-code.sh 2.1.113
bash scripts/renovate/update-codex.sh 0.123.0
```

### トークン

デフォルトの `GITHUB_TOKEN` で作った PR は他の workflow (= 既存 `nix.yml` CI) を**起動しない**という GitHub の仕様があるので、Renovate PR が自動的に CI を通るようにするには Fine-grained PAT を発行して Secret に登録する必要がある。

- Secret 名: `RENOVATE_TOKEN` (未設定時は `GITHUB_TOKEN` にフォールバックして動くが CI は走らない)
- 権限: 本リポジトリに対して
  - Repository permissions: `Contents: Read & Write`, `Pull requests: Read & Write`, `Workflows: Read & Write`
  - 発行元アカウントは自分自身 (bot 化したい場合のみ GitHub App に切り替え)
- 将来 GitHub App 化する場合は `actions/create-github-app-token` に差し替え、`app-id` / `private-key` を Secret に置く。

### 運用メモ

- 初回は `gh workflow run Renovate` で手動キック、または Actions タブから `workflow_dispatch`。`dryRun: extract` でまず extract 段階まで走らせると副作用なしで設定確認ができる。
- Renovate の `allowedPostUpgradeCommands` allowlist はこのリポジトリの `.github/renovate.json5` にベタ書きしてあり、self-hosted global config として読まれる (= `configurationFile` に指定しているため)。
- `post-upgrade` が失敗 (例: 上流 tarball の URL スキーマ変更) したときは PR が出ない代わりに Actions ログにスタックが残る。週次で run 履歴を覗くこと。
- 対応 triple を増やしたいときは `pkgs/npm/codex/package.nix` の `platforms` attrset と `scripts/renovate/update-codex.sh` の `TRIPLES=(...)` を同時に広げる。

## 動作確認

ビルド後:

```sh
claude --version   # 最新の claude-code バージョン
codex --version    # 最新の codex バージョン
which claude codex # /nix/store/... 配下にあること(mise shim ではない)
```
