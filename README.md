# ❄️ dotfiles-nix（引き継ぎメモ）

macOS 向けに **Nix flakes + nix-darwin + home-manager** でシェル・CLI・一部 UI 設定を宣言管理するリポジトリ。元々は Homebrew 中心だった構成から、**formula 相当は極力 Nix に寄せ、`brew list` を小さくする**ことを目的としている。

> [!TIP]
> 運用の詳細・移行・Homebrew・`config/` の手順は **[MANUAL.md](MANUAL.md)**。日常コマンドはこの README、深掘りは MANUAL を開くと読みやすいです。

## 目次

- [❄️ dotfiles-nix（引き継ぎメモ）](#️-dotfiles-nix引き継ぎメモ)
  - [目次](#目次)
  - [スタック](#スタック)
  - [前提（このマシン向けの固定値）](#前提このマシン向けの固定値)
  - [ディレクトリ構成](#ディレクトリ構成)
    - [Git と flake（コミットしてから実行すべきか）](#git-と-flakeコミットしてから実行すべきか)
  - [初回・日常のコマンド](#初回日常のコマンド)
  - [何がどこで管理されているか](#何がどこで管理されているか)
    - [nix-darwin（`hosts/reohakase.nix`）](#nix-darwinhostsreohakasenix)
    - [home-manager（`home/default.nix`）](#home-managerhomedefaultnix)
  - [Homebrew からの移行（方針メモ）](#homebrew-からの移行方針メモ)
  - [TODO リスト（引き継ぎ用）](#todo-リスト引き継ぎ用)
    - [セットアップ](#セットアップ)
    - [設定の移行](#設定の移行)
    - [Homebrew の整理（formula・cask 以外から進める）](#homebrew-の整理formulacask-以外から進める)
    - [運用](#運用)
  - [トラブル時のヒント](#トラブル時のヒント)

## スタック

| 役割         | 内容                                                                                                 |
| ------------ | ---------------------------------------------------------------------------------------------------- |
| インストーラ | [Determinate Nix Installer](https://github.com/DeterminateSystems/nix-installer)（flakes 有効）      |
| OS 統合      | [nix-darwin](https://github.com/LnL7/nix-darwin)（`system.defaults`、ユーザシェル、`/etc/nix` など） |
| ユーザ環境   | [home-manager](https://github.com/nix-community/home-manager)（zsh、starship、nvim、パッケージ群）   |
| 入力         | `nixpkgs-unstable`（`flake.nix` の `inputs` を参照）                                                 |

> [!NOTE] > **Cask / GUI アプリ**は厳密なハッシュ管理を前提にしない。必要なら (1) 手動インストール、(2) 残りの Homebrew 専用、(3) nix-darwin の `homebrew` モジュール、のいずれかで運用する想定。`hosts/reohakase.nix` 末尾にコメント例あり。

> [!IMPORTANT] > **Determinate Nix を使う場合:** [Determinate](https://github.com/DeterminateSystems/nix-installer) は Nix のインストールを独自に管理するため、nix-darwin の `nix.*`（`/etc/nix` など）と競合し、`Determinate detected, aborting activation` で止まる。このリポジトリでは `hosts/reohakase.nix` で **`nix.enable = false`** とし、Nix 本体の設定は Determinate / 手元の `nix.conf` に任せる。詳細は [MANUAL.md](MANUAL.md) の「Determinate Nix と nix-darwin」。

## 前提（このマシン向けの固定値）

| 項目                        | 値                                                                   |
| --------------------------- | -------------------------------------------------------------------- |
| ユーザー名                  | `ReoHakase`（`flake.nix` と `home/default.nix` の両方）              |
| Darwin 構成名（flake 出力） | `reohakase`（`hostname -s` / `scutil --get LocalHostName` と揃える） |
| アーキテクチャ              | `aarch64-darwin`（Apple Silicon）                                    |

別 Mac や別ユーザーに載せ替えるときは、少なくとも `flake.nix` の `user` / `hostname`、`hosts/` のファイル名、`home/default.nix` の `home.username` と `home.homeDirectory` を合わせる。

## ディレクトリ構成

```
flake.nix              # inputs（actrun など）と darwinConfigurations.reohakase
flake.lock             # 入力のロック（コミットする）
hosts/reohakase.nix    # nix-darwin（Nix、defaults、users、HM の読み込み）
home/default.nix       # home-manager（zsh / starship / neovim / packages）
config/starship.toml   # HM が xdg.configFile で配布
scripts/apply-system.sh # darwin-rebuild を root で実行するヘルパー
.github/workflows/nix.yml # CI（flake check + darwin system の nix build。switch はしない）
MANUAL.md              # 運用・移行・別マシン・Homebrew / NixCasks
```

> [!NOTE]
> Flake は **Git で追跡されたファイルだけ**を見る。未コミットの変更は `nix` が警告を出すことがある。

### Git と flake（コミットしてから実行すべきか）

> [!TIP] > **`nix flake check` や `darwin-rebuild` / `./scripts/apply-system.sh` の前に、必ずコミットする必要はない。**

- **追跡済みの `.nix` などを編集しただけ**なら、**未コミットの内容でも**その作業ツリーが評価に使われる（ローカル試行はそのまま可能）。このとき `warning: Git tree has uncommitted changes` が出ることがある。
- **新規ファイルをまだ `git add` していない**場合、そのファイルは flake に **含まれない**。追加した設定を反映したいときは **追跡に乗せる**（`git add`）こと。
- **再現性や CI・別マシンと揃えたい**ときは、変更を **コミットしてから** 評価・適用すると、「リポジトリに記録した状態」と一致する。

運用の詳細（別マシン、Homebrew、NixCasks、秘密情報、nixd）は [MANUAL.md](MANUAL.md) を参照。

## 初回・日常のコマンド

パスに Nix が載っていなければ（例）:

```bash
export PATH="/nix/var/nix/profiles/default/bin:$PATH"
```

リポジトリで評価だけ確認:

```bash
cd /path/to/dotfiles-nix
nix flake check
```

入力を更新したあと:

```bash
nix flake lock
```

> [!IMPORTANT] > **設定を本番適用するには管理者権限が必要**です。

```bash
cd /path/to/dotfiles-nix
./scripts/apply-system.sh
```

`darwin-rebuild` が PATH にある場合は次でもよい:

```bash
cd /path/to/dotfiles-nix
darwin-rebuild switch --flake .#reohakase
```

まだ `darwin-rebuild` が無い初回は、例:

```bash
nix run nix-darwin --extra-experimental-features 'nix-command flakes' -- \
  switch --flake /path/to/dotfiles-nix#reohakase
```

> [!TIP]
> 適用後は新しいターミナルを開くか `exec zsh` で、Nix 管理の `zsh` と HM を読み込ませる。

## 何がどこで管理されているか

### nix-darwin（`hosts/reohakase.nix`）

- Nix のインストールは **管理しない**（`nix.enable = false`、Determinate 利用時）。`experimental-features` 等は Determinate / `nix.conf` 側
- ログインシェルを Nix の `zsh` に
- `system.defaults.*`（ダークモード、Finder、Dock、トラックパッドなど）
- 新しい nix-darwin では `system.defaults` 利用に **`system.primaryUser`** が必須（コメント参照）

### home-manager（`home/default.nix`）

- zsh（補完・autosuggestion・syntax-highlighting、`zsh-abbr` の読み込み）
- starship（`config/starship.toml` を `~/.config` 相当へ）
- neovim、git、gh、fzf、mise
- CLI パッケージ（`bat`、`eza`、`ffmpeg`、`tmux` など。必要に応じて `home.packages` を増減）

> [!NOTE] > **なぜ `hosts/` と `home/` が分かれるか:** システム全体（ユーザー作成・defaults・Homebrew）と、ユーザーのホーム・ドットファイルの責務が違うため。概要は会話メモか [MANUAL.md](MANUAL.md) を参照。

## Homebrew からの移行（方針メモ）

1. この flake を `darwin-rebuild switch` まで通し、**パス上のツールが Nix 由来になることを確認**する。
2. `brew list --formula` を見て、Nix で代替済みのものから `brew uninstall` していく（依存は `brew autoremove` などで整理）。
3. Cask は別方針（上記）で残すか、別インストールにする。
4. 既存の `~/.zshrc` が HM 生成物と二重にならないよう、**エイリアスやパス設定は `home/default.nix` に寄せる**と安全。

## TODO リスト（引き継ぎ用）

完了したら `- [ ]` を `- [x]` に変えて進捗を残す。

### セットアップ

- [x] Nix が入り、`nix --version` と `nix flake --help` が動く
- [x] このリポジトリを clone / 配置し、`nix flake check` が通る
- [x] `./scripts/apply-system.sh`（または `darwin-rebuild switch --flake .#reohakase`）を実行し成功させる
- [ ] ログインシェルが Nix の `zsh` になっている（`dscl . -read ~/ UserShell` — まだなら再ログインやターミナル設定を確認）
- [x] `starship`、`nvim`、`git` などが `/etc/profiles/per-user/<ユーザー>/bin` 経由で優先される（`which -a` で確認）
- [x] `nixd` / `nixfmt` を HM に含め、`.vscode/settings.json` と Neovim（`config/nvim/lua/polish.lua` の nixd）で接続 — 詳細は [MANUAL.md](MANUAL.md)「nixd（エディタ連携）」

### 設定の移行

- [x] 手元の `~/.zshrc` の内容を確認し、**abbr・関数・PATH・mise/uv など**を `home/default.nix` の `programs.zsh` / `initContent` / `sessionPath` に移植した（または意図的に捨てた）
- [x] `~/.config/starship.toml` を編集する場合は **リポジトリの `config/starship.toml` を直し**、`darwin-rebuild` で反映する運用にそろえた
- [x] Neovim は当面 `programs.neovim` のみ。`~/.config/nvim` を宣言管理する場合の選択肢は [MANUAL.md](MANUAL.md) に記載
- [x] GPG・SSH エージェントなど、**秘密情報や機種依存**はリポジトリに含めず、[MANUAL.md](MANUAL.md) のとおりローカルのみで扱う
- [x] nix-darwin で macOS の設定を管理する (`hosts/reohakase.nix` の `system.defaults` など)
- [x] GitHub Actions で `nix flake check` と `nix build '.#darwinConfigurations.reohakase.system'` を実行する（`.github/workflows/nix.yml`。詳細は [MANUAL.md](MANUAL.md)「CI」）
- [x] nix-casks を flake に取り込み、`home/default.nix` の `nixCasks` で GUI を足せる状態にした — 使い方は [MANUAL.md](MANUAL.md) と https://nix-casks.yorganci.dev/

### Homebrew の整理（formula・cask 以外から進める）

- [x] `which -a git rg fzf` で **`/etc/profiles/per-user/<ユーザー>/bin` が先**であることを確認した
- [x] Nix と重複していた formula を **`brew uninstall` / `cleanup` で削減**した（CLI は nixpkgs、`opencode` 等は `home.packages`）— 手順は [MANUAL.md](MANUAL.md)「Homebrew」
- [ ] （任意・後回しでよい）Cask / GUI の扱いを決めた（Homebrew のまま / 手動 / nix-darwin `homebrew` / NixCasks など）
- [ ] （任意）`brew` を cask 専用として残すかどうか

### 運用

- [ ] `flake.nix` の inputs を更新したあと **`nix flake lock` → `nix flake check` → 適用 → `flake.lock` をコミット**の流れを一度通した（[MANUAL.md](MANUAL.md)「次の作業」参照）
- [x] 別マシン用に `user` / `hostname` / `hosts/*.nix` を分ける場合の手順を [MANUAL.md](MANUAL.md) に記載した
- [x] ケースバイケースのマニュアル [MANUAL.md](MANUAL.md) を作成した（変更の適用、install, update, uninstall, cask、新しい Mac など）

## トラブル時のヒント

| 症状                                        | 対処                                                                                                                                                                             |
| ------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `abbr: command not found`                   | `programs.zsh.zsh-abbr`（home-manager）で読み込む。**`./scripts/apply-system.sh` で再適用**してから `exec zsh`。[MANUAL.md](MANUAL.md) のトラブルも参照。                        |
| `Existing file '…' would be clobbered`      | 手元の `~/.zshrc` や `~/.config/gh/config.yml` などが HM と重なる。このリポジトリでは `hosts/reohakase.nix` の **`home-manager.backupFileExtension`** で退避してからリンクする。 |
| `Determinate detected, aborting activation` | Determinate と nix-darwin の Nix 管理がぶつかっている。`hosts/<hostname>.nix` で `nix.enable = false` にする（このリポジトリでは既に設定済み）。                                 |
| `No space left on device`                   | ディスク空きを増やし、`nix-collect-garbage -d` などでストアを整理する。詳細は [MANUAL.md](MANUAL.md) の「ディスク不足」。                                                        |
| `darwin-rebuild` がホスト名で失敗           | `flake.nix` の `hostname` と `scutil --get LocalHostName` を一致させる。                                                                                                         |
| Flake が古いファイルしか見ない              | 変更を `git add` / `commit` するか、警告に従う。                                                                                                                                 |
| Nix のアンインストール                      | Determinate インストールの場合は [nix-installer の README](https://github.com/DeterminateSystems/nix-installer) の `nix-installer uninstall` を参照。                            |

> [!WARNING] > **`Existing file … would be clobbered` で止まる**ときは、退避ファイルと HM の「どちらを正にするか」を決めてから再適用。手順は [MANUAL.md](MANUAL.md)「`~/.config` とリポジトリが食い違ったとき」。

---

最終更新: 引き継ぎ用にリポジトリの現状に合わせて記載。構成を変えたらこの README も更新すること。
