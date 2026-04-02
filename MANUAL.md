# dotfiles-nix 運用マニュアル

このリポジトリは **Nix flakes + nix-darwin + home-manager** で macOS のシェル・CLI・一部 OS 設定を宣言管理する。README の「初回・日常のコマンド」と併せて読む。

## Determinate Nix と nix-darwin

[nix-darwin](https://github.com/LnL7/nix-darwin) は既定で Nix のインストールや `nix.*` オプション（`/etc/nix/nix.conf` など）を管理できる。[Determinate Nix](https://github.com/DeterminateSystems/nix-installer) は別デーモンで同じ領域を管理するため、**両方を有効にすると activation が `Determinate detected, aborting activation` で止まる**。

このリポジトリの `hosts/reohakase.nix` では **`nix.enable = false`** とし、nix-darwin に Nix 本体を任せない。`experimental-features` や `trusted-users` は、Determinate の設定やローカルの Nix 設定で調整する。nix-darwin の `nix.*` に依存する機能（Linux ビルダーなど）は使えない点に注意。

## インストール（新しい Mac / 初回）

1. [Determinate Nix Installer](https://github.com/DeterminateSystems/nix-installer) などで Nix を入れ、flakes を有効にする。
2. このリポジトリを任意の場所に clone する。
3. パスに `nix` が無い場合は README のとおり `PATH` に `/nix/var/nix/profiles/default/bin` を足す。
4. 既存の `~/.zshrc` や `~/.config/gh/config.yml` などがあると、home-manager のリンクと衝突する。このリポジトリでは `hosts/reohakase.nix` の **`home-manager.backupFileExtension = "hm-backup"`** により、衝突時に同名ファイルを `.hm-backup` 付きで退避してから適用する。手動で退避したい場合は、適用前にコピーを取っておく。
5. **システム適用（管理者権限が必要）:** リポジトリ直下で  
   `./scripts/apply-system.sh`  
   または README にある `sudo nix run nix-darwin ... switch --flake '.#reohakase'` と同等。
6. 新しいターミナルを開くか `exec zsh` でログインシェルを読み直す。
7. ログインシェルが Nix の `zsh` か確認: `dscl . -read ~/ UserShell`

### 別マシン・別ユーザーに載せ替えるとき

最低限そろえるもの:

- `flake.nix` の `user` と `hostname`（`outputs.darwinConfigurations.<name>`）
- `hosts/<hostname>.nix` のファイル名と中身の `home-manager.users.<user>`
- `home/default.nix` の `home.username` と `home.homeDirectory`

ホスト名は `scutil --get LocalHostName` / `hostname -s` と一致させる。

## 変更の適用（update）

1. `flake.nix` の `inputs` を変えたら `nix flake lock` で `flake.lock` を更新し、動作確認後にコミットする。
2. 設定を反映: `./scripts/apply-system.sh`（または `darwin-rebuild switch --flake .#reohakase`。初回後は `darwin-rebuild` が PATH に乗ることが多い）。
3. `home/default.nix` や `hosts/*.nix` を変えたら必ず上記の **switch** を実行する。

## 評価だけ確認（ビルド適用なし）

```bash
cd /path/to/dotfiles-nix
nix flake check
```

## ディスク不足（`No space left on device`）と Nix ストア

`darwin-rebuild` / `nix run` が **`No space left on device`** で落ちるときは、まず **空き容量を増やす**（不要ファイルの削除、ストアの整理）。

```bash
# 未参照の世代を削除（古いプロファイルを消す前に世代一覧を確認してよい）
nix-collect-garbage -d

# 重複のハードリンク化（任意）
sudo nix-store --optimise
```

ビルドが **巨大な依存（例: ソースからの Rust ビルド）** で失敗する場合は、`home.packages` から該当パッケージを一時的に外すか、`nix log /nix/store/…drv` で原因を確認する。以前は `yt-dlp` が `deno` をソースビルドし容量を大量に使うことがあったため、このリポジトリでは **`yt-dlp` は Nix パッケージに含めず**、必要なら `pipx install yt-dlp` や Homebrew など別経路で入れる運用としている。

## `sudo` 時の `$HOME` 警告について

`sudo nix …` で `warning: $HOME ('/Users/…') is not owned by you` が出る場合、`scripts/apply-system.sh` は **`sudo -H`** で root の `HOME` を `/var/root` にそろえる。手で実行するときも同様に `sudo -H` を使うか、警告は評価上はフォールバックされることが多い。

## アンインストール

Nix 自体を消す場合は、インストール方法に従う（Determinate の場合は [nix-installer の README](https://github.com/DeterminateSystems/nix-installer) の `nix-installer uninstall` など）。ホームディレクトリの生成物（`~/.config` 配下の HM 管理ファイルなど）はバックアップを取ったうえで整理する。

## Homebrew

- **方針:** formula は極力 Nix に寄せ、`brew list --formula` を小さくする。Cask / GUI は手動・Homebrew のみ・nix-darwin の `homebrew` モジュール・[NixCasks](https://nix-casks.yorganci.dev/) のいずれかで運用する。
- **PATH の確認:** `which -a git rg fzf` などで **`/etc/profiles/per-user/<ユーザー>/bin` が先**になることを確認する（`home.sessionPath` で付けている）。
- **整理（formula のみ・cask は触らない）:** 一度に全部消さず、Nix で代替できているものから順に外す。

```bash
brew list --formula
# 例: git / ripgrep / fzf が Nix 先頭なら
brew uninstall git ripgrep fzf
brew autoremove
brew cleanup
```

他ツールが依存していると `brew uninstall` が失敗することがある。その場合はメモして後回しでよい。**`brew uninstall --cask`** や Cask の整理は別タスクとして扱う。

## 次の作業の目安（cask 以外）

1. **リポジトリ:** 変更を `git add` / `commit` / `push` し、警告の出る未コミット状態を減らす。
2. **ログインシェル:** `dscl . -read ~/ UserShell` が Nix の `zsh` を指すか確認。まだ `/bin/zsh` なら新しいターミナルで再ログインするか、システム設定でログインシェルを確認する。
3. **nixd:** [editor-setup](https://github.com/nix-community/nixd/blob/main/nixd/docs/editor-setup.md) に従い Cursor / Neovim に `nixd` を接続する（Cursor の Nix 拡張は別途）。
4. **Homebrew formula:** 上記「整理（formula のみ）」を少しずつ実施。cask は後回しでよい。
5. **inputs 更新の運用:** `flake.nix` の `inputs` を変えたら `nix flake lock` → `nix flake check` → `./scripts/apply-system.sh` → 問題なければ `flake.lock` をコミット。

## NixCasks（GUI）

`flake.nix` に `nix-casks` の input を追加済み。`home/default.nix` の `nixCasks` リストに、例として次のようにパッケージを足す（名前は [NixCasks の一覧](https://nix-casks.yorganci.dev/) を参照）:

```nix
nixCasks = with inputs.nix-casks.packages.${pkgs.system}; [
  raycast
];
```

変更後は `nix flake lock`（初回追加時）と `darwin-rebuild` / `apply-system.sh` で適用する。

## 秘密情報（GPG・SSH など）

**秘密鍵・トークン・機種固有のパスはリポジトリに含めない。**  
GPG エージェントや `ssh-agent`、`~/.ssh/config` の中身はローカルで管理し、このリポジトリには手順メモのみを書く（本ファイルの「ローカルのみ」扱い）。

## nixd（エディタ連携）

[Nix 用 language server nixd の editor セットアップ](https://github.com/nix-community/nixd/blob/main/nixd/docs/editor-setup.md) を参照し、Cursor / Neovim に `nixd` を接続する。Cursor 側の Nix 拡張は別途インストール済み前提。

## Neovim

現状は home-manager の `programs.neovim`（エディタ本体とデフォルトエディタ設定）のみ。`~/.config/nvim` を宣言管理する場合は `xdg.configFile` で配る、`programs.neovim` の extraConfig、別リポジトリを submodule にするなど、好みの方式を選び、この MANUAL に追記するとよい。

## Flake と Git

`nix` は **Git で追跡されたファイル**を主に flake 入力として見る。未コミットの変更があると警告が出ることがある。本番に近い評価では変更を `git add` / `commit` してから `nix flake check` や `switch` するとよい。

## トラブル

- **`abbr: command not found`:** `programs.zsh.zsh-abbr` でプラグインと略語を宣言管理する（手動 `source` は使わない）。 **`./scripts/apply-system.sh`** で HM を再適用し、`exec zsh`。
- **`which -a git` で `/usr/bin` や Homebrew が Nix より先:** `home.sessionPath` の先頭に `/etc/profiles/per-user/<ユーザー>/bin` などを置いている。反映後もおかしい場合は、`/etc/zprofile` の `path_helper` やターミナル設定を確認する（必要なら `programs.zsh.profileExtra` で PATH を足し直すこともある）。
- **`darwin-rebuild` がホスト名で失敗:** `flake.nix` の `hostname` と `scutil --get LocalHostName` を一致させる。
- **`darwin-rebuild` が root を要求:** システム適用は常に管理者権限。`scripts/apply-system.sh` を使う。
