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
- **nix-darwin の `homebrew`:** `hosts/<hostname>.nix` の `homebrew.enable` で `brew bundle` による宣言管理が有効になる。`taps` / `brews` / `casks` に列挙する（例: `wtp` は `satococoa/tap`）。
- **nix-homebrew（brew 本体を Nix で管理）:** `flake.nix` に `nix-homebrew` input を追加し、`nix-homebrew.darwinModules.nix-homebrew` を読み込む。`hosts/*.nix` で `nix-homebrew.enable` と `user`、既存インストールの移行に **`autoMigrate = true`**。[nix-homebrew](https://github.com/zhaofengli/nix-homebrew) は Homebrew のバージョンをピン留めし、nix-darwin の `homebrew.*` と併用する。
- **`onActivation.cleanup`（[nix-darwin manual](https://nix-darwin.github.io/nix-darwin/manual/index.html#opt-homebrew.onActivation.cleanup)）:**  
  - **`check`:** 手元にあって Brewfile（= この flake の `homebrew.*`）に無いパッケージがあると **activation が失敗**し、余分なものが列挙される。flake に「正本」を全部書き込むまで使うのが安全。  
  - **`uninstall`:** Brewfile に無い formula / cask を **`brew bundle --cleanup`** で削除。**通常はこちら**（nix を正本にしたいときの既定）。  
  - **`zap`:** `uninstall` に加え **`--zap`**。cask の関連ファイルまで強く掃除する。**GUI アプリのユーザデータまで消える可能性**があるので、cask を徹底除去したい場合だけ。
- **ブラウザや GUI の設定を守りたいとき:** **`cleanup` に `zap` は使わない**（プロファイルや `~/Library/Application Support` 周りまで消すことがある）。**`uninstall`** は通常、アプリ本体（`/Applications` など）を外す動きで、**多くのブラウザはブックマーク・プロファイルがユーザ領域に残る**ことが多いが、アプリによっては消えるものもある。**確実に残したい cask は必ず `homebrew.casks` に書き、意図的にリストから外さない。** 迷う間は `check` のままにして、Cask は手動のみ・別管理にする選択も可。
- **`brew` と Cellar:** `home.sessionPath` に **`/opt/homebrew/bin`** / **`sbin`**（formula はここにリンク）。`brew` コマンドは nix-homebrew 経由で **`/run/current-system/sw/bin/brew`** にも出ることがある（`which -a brew` で確認）。
- **PATH の確認:** `which -a git rg fzf` などで **`/etc/profiles/per-user/<ユーザー>/bin` が先**になることを確認する（`home.sessionPath` で付けている）。
- **整理（formula のみ・cask は触らない）:** 一度に全部消さず、Nix で代替できているものから順に外す。依存関係の見方と優先度の例は、下の **「nixd（エディタ連携）」→「Homebrew と重複」** を参照。

```bash
brew list --formula
brew autoremove
brew cleanup
```

他ツールが依存していると `brew uninstall` が失敗することがある。その場合はメモして後回しでよい。**`brew uninstall --cask`** や Cask の整理は別タスクとして扱う。

## 次の作業の目安（cask 以外）

1. **リポジトリ:** 変更を `git add` / `commit` / `push` し、警告の出る未コミット状態を減らす。
2. **ログインシェル:** `dscl . -read ~/ UserShell` が Nix の `zsh` を指すか確認。まだ `/bin/zsh` なら新しいターミナルで再ログインするか、システム設定でログインシェルを確認する。
3. **nixd:** 下記「nixd（エディタ連携）」と `.vscode/settings.json`、適用後 `command -v nixd`。
4. **Homebrew formula:** 下記の重複整理を少しずつ。cask は後回しでよい。
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

`nixd` と `nixfmt` は **`home/default.nix` の `home.packages`** に含めている。適用後はターミナルで `command -v nixd` が Nix のパスを指すことを確認する。概要は [editor-setup](https://github.com/nix-community/nixd/blob/main/nixd/docs/editor-setup.md)。

### Cursor / VS Code（[vscode-nix-ide](https://github.com/nix-community/vscode-nix-ide)）

1. 拡張機能 **Nix IDE**（`nix-ide`）を入れる（未導入なら）。
2. このリポジトリ直下の **`.vscode/settings.json`** で `nix.serverPath` が `nixd` になっている（ワークスペースをこのフォルダとして開く）。
3. **Command Palette → Developer: Reload Window** で LSP を読み直す。

グローバルに効かせたい場合は、[editor-setup](https://github.com/nix-community/nixd/blob/main/nixd/docs/editor-setup.md) に沿って `~/Library/Application Support/Cursor/User/settings.json` に同様の `nix.*` を書いてもよい。

### Neovim

`programs.neovim.initLua` で **`FileType nix` 時に `nixd` を `vim.lsp.start`** している。flake のオプション補完は `darwinConfigurations.reohakase` を指す式になっている（ホスト名を変えたら `home/default.nix` の Lua と `.vscode/settings.json` の両方を合わせる）。

`~/.config/nvim` をプラグイン込みで宣言管理したくなったら、`xdg.configFile` や `programs.neovim` の `extraConfig`、別リポジトリの submodule など、好みの方式で拡張してよい。

### Homebrew と重複している formula の整理（少しずつ）

**方針:** `brew uses --installed <formula>` で **他 formula から依存されているか**を見てから外す。

手元の例（2026 年時点の一例）:

| 状況 | 例 |
|------|-----|
| 依存なしで外しやすい | `fzf`, `bat`, `eza`, `fd`, `gh`, `tmux`, `ffmpeg`, `gnupg`, `graphviz`, `hyperfine`, `nmap`, `typst`, `uv`, `terminal-notifier`, `wget`, `starship` など（`brew uses --installed` が空なら候補） |
| 他タップが依存 | `git` ← `wtp`（`satococoa/tap/wtp`）が依存する場合がある。先に `wtp` を Nix 側に寄せるか、Nix の `git` で動くか確認してから |
| 同上 | `ripgrep` ← `opencode`（`anomalyco/tap`）が依存することがある |
| Neovim 周り | `tree-sitter` は **brew の `neovim` が依存**することがある。**先に** `brew uninstall neovim`（Nix の Neovim を使う前提）→ その後 `brew uninstall tree-sitter` が通るか確認 |
| シェル系 | `zsh-abbr` は **`programs.zsh.zsh-abbr`**。`zsh-autosuggestions` / `zsh-syntax-highlighting` は **`programs.zsh.autosuggestion.enable`** と **`programs.zsh.syntaxHighlighting.enable`**（nixpkgs のパッケージを HM が読み込む。`home.packages` に明示しなくてよい）。brew 版は外してよい |
| `mise` | HM の `programs.mise` と重複するなら brew 側を外してよい（`brew uses` が空なら試しやすい） |

**実施例（メイン Mac）:** `fzf`, `bat`, `eza`, `fd`, `gh`, `tmux`, `wget`, `ffmpeg`, `gnupg`, `graphviz`, `hyperfine`, `nmap`, `typst`, `uv`, `terminal-notifier`, `starship`, `neovim` をアンインストールし、`neovim` 削除に伴う autoremove で `tree-sitter` も除去。続けて `mise` と zsh プラグイン 3 本を削除。**`git` と `ripgrep` は** `wtp` / `opencode` が依存するため **brew に残置**。Nix に無い `act`, `arp-scan`, `chezmoi` などはそのまま。

```bash
# 例: 依存の確認
brew uses --installed fzf bat eza

# 問題なければ少しずつ（失敗したらそのパッケージは保留）
brew uninstall fzf bat eza fd gh tmux
brew autoremove
brew cleanup
```

Nix に無いツール（例: `chezmoi`, `act`, `arp-scan` など）は **brew のまま**でよい。

## Flake と Git

`nix` は **Git で追跡されたファイル**を主に flake 入力として見る。未コミットの変更があると警告が出ることがある。本番に近い評価では変更を `git add` / `commit` してから `nix flake check` や `switch` するとよい。

## トラブル

- **`dscl . -read ~/ UserShell` がまだ `/bin/zsh`:** flake では `users.users.<名前>.shell = pkgs.zsh` になっている。`./scripts/apply-system.sh` の再適用とログアウト／再起動のあと、変わらなければ `/etc/shells` に載っている Nix の zsh（通常 **`/run/current-system/sw/bin/zsh`**）を指定して `sudo chsh -s /run/current-system/sw/bin/zsh`。別パスなら `grep zsh /etc/shells` で確認する。
- **`abbr: command not found`:** `programs.zsh.zsh-abbr` でプラグインと略語を宣言管理する（手動 `source` は使わない）。 **`./scripts/apply-system.sh`** で HM を再適用し、`exec zsh`。
- **`which -a git` で `/usr/bin` や Homebrew が Nix より先:** `home.sessionPath` の先頭に `/etc/profiles/per-user/<ユーザー>/bin` などを置いている。反映後もおかしい場合は、`/etc/zprofile` の `path_helper` やターミナル設定を確認する（必要なら `programs.zsh.profileExtra` で PATH を足し直すこともある）。
- **`darwin-rebuild` がホスト名で失敗:** `flake.nix` の `hostname` と `scutil --get LocalHostName` を一致させる。
- **`darwin-rebuild` が root を要求:** システム適用は常に管理者権限。`scripts/apply-system.sh` を使う。
