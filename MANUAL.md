# dotfiles-nix 運用マニュアル

このリポジトリは **Nix flakes + nix-darwin + home-manager** で macOS のシェル・CLI・一部 OS 設定を宣言管理する。README の「初回・日常のコマンド」と併せて読む。

> [!TIP] > **短く済ませたいとき:** コマンドだけは [README.md](README.md)。運用・Homebrew・`config/` の衝突はこの MANUAL。

## 目次

- [Determinate Nix と nix-darwin](#determinate-nix-と-nix-darwin)
- [インストール（新しい Mac / 初回）](#インストール新しい-mac--初回)
- [変更の適用（update）](#変更の適用update)
- [`config/` の追加・削除・編集](#config-の追加削除編集config-を宣言管理するとき)
- [`~/.config` とリポジトリのずれ・衝突](#config-とリポジトリが食い違った衝突したとき)
- [評価だけ確認](#評価だけ確認ビルド適用なし)
- [ディスク不足と Nix ストア](#ディスク不足no-space-left-on-deviceと-nix-ストア)
- [`sudo` 時の `$HOME` 警告](#sudo-時のhome-警告について)
- [アンインストール](#アンインストール)
- [Homebrew](#homebrew)
- [次の作業の目安](#次の作業の目安cask-以外)
- [NixCasks（GUI）](#nixcasksgui)
- [Linux（Ubuntu）GUI: Ghostty・Cursor・Vicinae](#linuxubuntu-gui-ghosttycursorvicinae)
- [秘密情報（GPG・SSH など）](#秘密情報gpgssh-など)
- [nixd（エディタ連携）](#nixdエディタ連携)
- [Flake と Git](#flake-と-git)
- [actrun（ローカル Actions ランナー）](#actrunmizchiactrun)
- [CI（GitHub Actions）](#cigithub-actions)
- [トラブル](#トラブル)

---

## Determinate Nix と nix-darwin

[nix-darwin](https://github.com/LnL7/nix-darwin) は既定で Nix のインストールや `nix.*` オプション（`/etc/nix/nix.conf` など）を管理できる。[Determinate Nix](https://github.com/DeterminateSystems/nix-installer) は別デーモンで同じ領域を管理するため、**両方を有効にすると activation が `Determinate detected, aborting activation` で止まる**。

> [!IMPORTANT]
> このリポジトリの `hosts/reohakase.nix` では **`nix.enable = false`** とし、nix-darwin に Nix 本体を任せない。`experimental-features` や `trusted-users` は、Determinate の設定やローカルの Nix 設定で調整する。

> [!NOTE]
> nix-darwin の `nix.*` に依存する機能（Linux ビルダーなど）は使えない点に注意。

## インストール（新しい Mac / 初回）

1. [Determinate Nix Installer](https://github.com/DeterminateSystems/nix-installer) などで Nix を入れ、flakes を有効にする。
2. このリポジトリを任意の場所に clone する。
3. パスに `nix` が無い場合は README のとおり `PATH` に `/nix/var/nix/profiles/default/bin` を足す。
4. 既存の `~/.zshrc` や `~/.config/gh/config.yml` などがあると、home-manager のリンクと衝突する。このリポジトリでは `hosts/reohakase.nix` の **`home-manager.backupFileExtension = "hm-backup"`** により、衝突時に同名ファイルを `.hm-backup` 付きで退避してから適用する。手動で退避したい場合は、適用前にコピーを取っておく。
5. **システム適用（管理者権限が必要）:** リポジトリ直下で `./scripts/apply-system.sh`、または README にある `sudo nix run nix-darwin ... switch --flake '.#reohakase'` と同等。
6. 新しいターミナルを開くか `exec zsh` でログインシェルを読み直す。
7. ログインシェルが Nix の `zsh` か確認: `dscl . -read ~/ UserShell`

### 別マシン・別ユーザーに載せ替えるとき

最低限そろえるもの:

| 項目         | 内容                                                              |
| ------------ | ----------------------------------------------------------------- |
| flake        | `user` と `hostname`（`outputs.darwinConfigurations.<name>`）     |
| ホスト       | `hosts/<hostname>.nix` のファイル名と `home-manager.users.<user>` |
| Home Manager | `home/default.nix` の `home.username` と `home.homeDirectory`     |

ホスト名は `scutil --get LocalHostName` / `hostname -s` と一致させる。

## 変更の適用（update）

1. `flake.nix` の `inputs` を変えたら `nix flake lock` で `flake.lock` を更新し、動作確認後にコミットする。
2. 設定を反映: `./scripts/apply-system.sh`（または `darwin-rebuild switch --flake .#reohakase`。初回後は `darwin-rebuild` が PATH に乗ることが多い）。
3. `home/default.nix` や `hosts/*.nix` を変えたら必ず上記の **switch** を実行する。

## `config/` の追加・削除・編集（`~/.config` を宣言管理するとき）

`home/default.nix` の `xdg.configFile` が **`../config/...` を `source` として** `~/.config` 以下にシンボリックリンクを張る。Nix は **flake の入力として Git の追跡ファイル**を読むため、リポジトリ直下で作業する場合は **未コミットの新規パスがあるとビルドが失敗**することがある（`Path 'config/...' does not exist in Git repository` など）。

> [!WARNING] > **新規ファイルを `git add` したうえで** `nix flake check` / `switch` しないと、Nix がパスを見つけられないことがある。

### ファイルを編集するとき（既に `xdg.configFile` がある）

1. リポジトリの **`config/` 側**を編集する（正本はここ。`~/.config` のシンボリックリンク先を直接いじらない方が安全）。
2. 内容に満足したら `git add` / `commit`。
3. `./scripts/apply-system.sh` で適用（リンク先のストアパスが更新される）。

### 新しい設定ファイル・ディレクトリを追加するとき

1. `config/` にファイルを置く（ディレクトリごとなら `config/foo/` 以下に置く）。
2. `home/default.nix` の `xdg.configFile` にエントリを足す。例:
   - 単一ファイル: `"アプリ名/設定名".source = ../config/アプリ名/設定名;`
   - ディレクトリ丸ごと: `"アプリ名".source = ../config/アプリ名;`
3. **`git add` で新規パスを追跡したうえで** `nix flake check` または `switch`（未追跡のままだと Nix がパスを見つけられない）。
4. `commit` してから `./scripts/apply-system.sh`。

### 宣言管理をやめる・ファイルを削除するとき

1. `home/default.nix` から該当の `xdg.configFile` 行を削除する。
2. リポジトリから `config/...` のファイルを `git rm` する（不要なら）。
3. `commit` のあと `./scripts/apply-system.sh`。  
   以降はそのパスは Home Manager が管理しない。**手元で編集したい設定**は、`~/.config` に通常ファイルとして残す（初回は HM が退避した `.hm-backup` をリネームするなど）か、アプリ側の「デフォルトの設定場所」に任せる。

### `programs.*` で生成しているもの（`git` など）

`~/.config/git/config` の一部は **`programs.git` など Home Manager のモジュール**が生成する。リポジトリに平文の `config/git/config` を置かず、**`home/default.nix` の `programs.git.settings`** を編集する。`config/git/README.md` を参照。

## `~/.config` とリポジトリが食い違った・衝突したとき

### 事前に知っておくこと

- **`home-manager.backupFileExtension = "hm-backup"`**（`hosts/reohakase.nix`）により、適用時に既存ファイルと衝突すると、既存側が **`*.hm-backup`** にリネームされ、代わりに Nix のリンクが張られる。
- 正本を **`config/` + `home/default.nix`** に置く運用なら、**いじるのは基本リポジトリ側**で、`switch` で `~/.config` に反映するのが一番わかりやすい。

### 楽な解決の流れ（迷ったらこの順）

1. **何が正か決める**
   - 「リポジトリを正にする」→ 手元の変更を `config/` に取り込んでから `commit` → `switch`。
   - 「手元の `~/.config` だけ試したい」→ そのパスを **`xdg.configFile` から外す**か一時的にコメントアウトして `switch` し、通常ファイルとして編集（恒久なら後で `config/` に写して再度宣言化）。
2. **`.hm-backup` が残っている場合**
   - 中身は「適用直前の旧ファイル」。**差分を見る:**  
     `diff ~/.config/foo/foo.yml ~/.config/foo/foo.yml.hm-backup`（パスは例）
   - リポジトリ側に取り込みたい内容がバックアップにだけあるなら、**`config/` にマージして `commit` → `switch`**。不要ならバックアップを削除してよい。
3. **シンボリックリンクなのにエディタで直接編集した**
   - リンク先は Nix ストアの読み取り専用パスになることがある。**編集は `config/` の実体**に対して行い、再度 `commit` → `switch`。
4. **古い通常ファイルが残っていてリンクが張れない**
   - バックアップに退避されていない「そのまま残ったファイル」の場合は、**中身を確認したうえで**リネーム・削除してから `switch` をやり直す（消す前に `cp` や `git diff` で退避）。

> [!TIP] > **コンフリクトを減らす:** 宣言管理するパスは **`config/` だけ編集**し、`switch` で反映する。大きいデータ（Raycast の extensions など）は **リポジトリに含めず**、ローカルや別バックアップで管理する。変更後は **`git status` がきれいな状態**で `nix flake check` / `switch` すると、Nix の「Git に無いパス」エラーを避けやすい。

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
- **nix-darwin の `homebrew`:** `hosts/<hostname>.nix` の `homebrew.enable` で `brew bundle` による宣言管理が有効になる。CLI は nixpkgs（`home.packages`）に寄せ、`brews` / `taps` は空でもよい（**cask だけ** Homebrew に残す運用）。
- **nix-homebrew（brew 本体を Nix で管理）:** `flake.nix` に `nix-homebrew` input を追加し、`nix-homebrew.darwinModules.nix-homebrew` を読み込む。`hosts/*.nix` で `nix-homebrew.enable` と `user`、既存インストールの移行に **`autoMigrate = true`**。[nix-homebrew](https://github.com/zhaofengli/nix-homebrew) は Homebrew のバージョンをピン留めし、nix-darwin の `homebrew.*` と併用する。

### `onActivation.cleanup`（[nix-darwin manual](https://nix-darwin.github.io/nix-darwin/manual/index.html#opt-homebrew.onActivation.cleanup)）

| 値          | 動き                                                                                                                                             |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `check`     | 手元にあって Brewfile に無いパッケージがあると **activation が失敗**し、余分なものが列挙される。flake に「正本」を全部書き込むまで使うのが安全。 |
| `uninstall` | Brewfile に無い formula / cask を **`brew bundle --cleanup`** で削除。**通常はこちら**（nix を正本にしたいときの既定）。                         |
| `zap`       | `uninstall` に加え **`--zap`**。cask の関連ファイルまで強く掃除する。                                                                            |
| `none`      | `brew bundle` 後に **自動では formula を消さない**。tap 由来の formula が **`cleanup = uninstall` と衝突**する場合に使う。                       |

> [!CAUTION] > **`zap`** は **GUI アプリのユーザデータまで消える可能性**がある。cask を徹底除去したい場合だけ。ブラウザのプロファイルや `~/Library/Application Support` を守りたいときは **`zap` を使わない**。

- **ブラウザや GUI の設定を守りたいとき:** **`cleanup` に `zap` は使わない**（プロファイルや `~/Library/Application Support` 周りまで消すことがある）。**`uninstall`** は通常、アプリ本体（`/Applications` など）を外す動きで、**多くのブラウザはブックマーク・プロファイルがユーザ領域に残る**ことが多いが、アプリによっては消えるものもある。**確実に残したい cask は必ず `homebrew.casks` に書き、意図的にリストから外さない。** 迷う間は `check` のままにして、Cask は手動のみ・別管理にする選択も可。
- **手元から flake へ移行するとき:** `brew tap` / `brew list --formula` / `brew list --cask` の出力を `hosts/<hostname>.nix` の `homebrew.taps` / `brews` / `casks` に写し、`onActivation.cleanup` を `uninstall` にする（初回は `check` で差分確認でもよい）。
- **`brew` と Cellar:** `home.sessionPath` に **`/opt/homebrew/bin`** / **`sbin`**（formula はここにリンク）。`brew` コマンドは nix-homebrew 経由で **`/run/current-system/sw/bin/brew`** にも出ることがある（`which -a brew` で確認）。
- **PATH の確認:** `which -a git rg fzf` などで **`/etc/profiles/per-user/<ユーザー>/bin` が先**になることを確認する。`brew shellenv` などで PATH が変わる場合は、`programs.zsh.initContent` の末尾で Nix の `bin` を再度先頭に付け直している。
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

## Linux（Ubuntu）GUI: Ghostty・Cursor・Vicinae

macOS では [NixCasks](#nixcasksgui) や Homebrew cask で GUI を足すことが多いが、**この flake の Ubuntu 向け Home Manager** では次を宣言している（`home/linux/apps/gui-apps.nix`）。

| パッケージ | 中身 | flake の `packages.x86_64-linux` |
| ---------- | ---- | -------------------------------- |
| Ghostty | nixpkgs の `ghostty` を [`pkgs/gui/ghostty.nix`](pkgs/gui/ghostty.nix) で再エクスポート | `ghostty` |
| Cursor | nixpkgs の **`code-cursor`**（Linux では AppImage ベース）。[`pkgs/appimages/cursor.nix`](pkgs/appimages/cursor.nix) で `cursor-appimage` という名前に寄せている | `cursor-appimage` |
| Vicinae | 公式リリースの AppImage を `fetchurl` で固定。[`pkgs/appimages/vicinae.nix`](pkgs/appimages/vicinae.nix) で `appimageTools.wrapType2` | `vicinae-appimage` |

`flake.nix` の **`pkgsLinux` 用 overlay** で `cursor-appimage` / `vicinae-appimage` を定義しているため、Home Manager の `pkgs` からも同じ名前で参照できる。

**ビルド確認（Linux またはリモートビルダー上）:**

```bash
nix build '.#packages.x86_64-linux.home-reohakuta-kcvl' --no-link
# 個別
nix build '.#packages.x86_64-linux.ghostty' --no-link
nix build '.#packages.x86_64-linux.cursor-appimage' --no-link
nix build '.#packages.x86_64-linux.vicinae-appimage' --no-link
```

**Vicinae のバージョン更新:** `pkgs/appimages/vicinae.nix` の `version` と `src.url` をリリースに合わせ、`hash` を更新する。手元で一度取り込んだあとなら `nix hash path /nix/store/…-Vicinae-x86_64.AppImage` で SRI にできる。未取得なら `nix-prefetch-url '<AppImage の URL>' --type sha256` で store に入れてから同様に hash を得る。

## 秘密情報（GPG・SSH など）

> [!WARNING] > **秘密鍵・トークン・機種固有のパスはリポジトリに含めない。**

GPG エージェントや `ssh-agent`、`~/.ssh/config` の中身はローカルで管理し、このリポジトリには手順メモのみを書く（本ファイルの「ローカルのみ」扱い）。

## nixd（エディタ連携）

`nixd` と `nixfmt` は **`home/default.nix` の `home.packages`** に含めている。適用後はターミナルで `command -v nixd` が Nix のパスを指すことを確認する。概要は [editor-setup](https://github.com/nix-community/nixd/blob/main/nixd/docs/editor-setup.md)。

### Cursor / VS Code（[vscode-nix-ide](https://github.com/nix-community/vscode-nix-ide)）

1. 拡張機能 **Nix IDE**（`nix-ide`）を入れる（未導入なら）。
2. このリポジトリ直下の **`.vscode/settings.json`** で `nix.serverPath` が `nixd` になっている（ワークスペースをこのフォルダとして開く）。
3. **Command Palette → Developer: Reload Window** で LSP を読み直す。

グローバルに効かせたい場合は、[editor-setup](https://github.com/nix-community/nixd/blob/main/nixd/docs/editor-setup.md) に沿って `~/Library/Application Support/Cursor/User/settings.json` に同様の `nix.*` を書いてもよい。

### Neovim

`config/nvim` を `xdg.configFile` で丸ごとリンクしている。Nix 用の LSP は **`config/nvim/lua/polish.lua`** で **`FileType nix` 時に `nixd` を `vim.lsp.start`** している。flake のオプション補完は `darwinConfigurations.reohakase` を指す式になっている（ホスト名を変えたら `polish.lua` と `.vscode/settings.json` の両方を合わせる）。

### Homebrew と重複している formula の整理（少しずつ）

**方針:** `brew uses --installed <formula>` で **他 formula から依存されているか**を見てから外す。

手元の例（2026 年時点の一例）:

| 状況                 | 例                                                                                                                                                                                                                                                                                        |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 依存なしで外しやすい | `fzf`, `bat`, `eza`, `fd`, `gh`, `tmux`, `ffmpeg`, `gnupg`, `graphviz`, `hyperfine`, `nmap`, `typst`, `uv`, `terminal-notifier`, `wget`, `starship` など（`brew uses --installed` が空なら候補）                                                                                          |
| 他タップが依存       | 例: 以前 `wtp` が brew の `git` に依存していた場合は、ツールを外すか Nix の `git` を使うか整理する                                                                                                                                                                                        |
| 同上                 | `ripgrep` ← `opencode`（`anomalyco/tap`）が依存することがある                                                                                                                                                                                                                             |
| Neovim 周り          | `tree-sitter` は **brew の `neovim` が依存**することがある。**先に** `brew uninstall neovim`（Nix の Neovim を使う前提）→ その後 `brew uninstall tree-sitter` が通るか確認                                                                                                                |
| シェル系             | `zsh-abbr` は **`programs.zsh.zsh-abbr`**。`zsh-autosuggestions` / `zsh-syntax-highlighting` は **`programs.zsh.autosuggestion.enable`** と **`programs.zsh.syntaxHighlighting.enable`**（nixpkgs のパッケージを HM が読み込む。`home.packages` に明示しなくてよい）。brew 版は外してよい |
| `mise`               | HM の `programs.mise` と重複するなら brew 側を外してよい（`brew uses` が空なら試しやすい）                                                                                                                                                                                                |

**実施例（メイン Mac）:** 上記のとおり重複 formula を削減。`opencode` / `fastfetch` などは **nixpkgs の `home.packages`** に移し、brew の formula は `cleanup = uninstall` で整理する。

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

### actrun（[mizchi/actrun](https://github.com/mizchi/actrun)）

> [!NOTE]
> **NixOS/nixpkgs の公式パッケージ集合にまだ入っていない**ため、このリポジトリでは `flake.nix` の **`inputs.actrun`** と **`nixpkgs.overlays = [ inputs.actrun.overlays.default ]`**（`hosts/reohakase.nix`）で [actrun の flake](https://github.com/mizchi/actrun) から `pkgs.actrun` を取り込み、`home.packages` に追加している。nixpkgs 本体への追加をしたい場合は [NixOS/nixpkgs](https://github.com/NixOS/nixpkgs) へパッケージ定義の PR を出す（別作業）。

適用後は `actrun workflow run .github/workflows/nix.yml` などでローカル検証できる。

## CI（GitHub Actions）

`.github/workflows/nix.yml` は **Apple Silicon 向け**（`aarch64-darwin`）の darwin 構成を検証する。

| ステップ                                                        | 意味                                                                                           |
| --------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| `nix flake check`                                               | flake の評価・チェック（軽め。`build skipped` と出ることもある）。                             |
| `nix build '.#darwinConfigurations.reohakase.system' --no-link` | **システム drv を実際にビルド**（`switch` はしない）。閉包がコンパイルできるかの実質的な検証。 |

> [!NOTE] > **`darwin-rebuild switch` は CI では実行しない。** root・activation・nix-homebrew / Homebrew が **そのランナー固有**になり、本番 Mac の再現にもならない。検証したいのは **「flake から drv がビルドできるか」** であり、それは **`nix build …system`** で足りる。

> [!TIP] > **Runner イメージ:** `macos-14` はやや古い。[GitHub のランナー一覧](https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners/about-github-hosted-runners) に従い、**`macos-latest` または `macos-15`** に更新している。macOS 26（Tahoe）専用ラベルが **aarch64** で提供されたら、必要に応じて `runs-on` を差し替える（Intel 専用ラベルはこの flake の `aarch64-darwin` と合わない）。

### リモートビルド・キャッシュで時間を短くするには

- **Linux の強い CPU に `aarch64-darwin` を丸ごとリモートビルド**するのは、通常の Nix 分散ビルドでは **向いていない**（ビルダの `system` が一致しないとそのままでは使えない。クロスは別途ツールチェーンが要る）。
- **CI（macOS ランナー）でビルドした結果を手元が再利用**したい場合は **[Cachix](https://www.cachix.org/)** や **FlakeHub Cache** など、**バイナリキャッシュに push → ローカルで substituter として pull** するのが定石（「強い CPU でビルドした store パスをダウンロードする」に近い）。
- **GitHub Actions 内**の再利用には [Magic Nix Cache](https://github.com/DeterminateSystems/magic-nix-cache)（Determinate）を workflow に足すと、同じリポジトリの連続ビルドで **nix ストアのヒット率**が上がりやすい（ローカル Mac とは別物）。

## トラブル

| 症状                                                   | 対処                                                                                                                                                                                                                                                                                                                                     |
| ------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `dscl . -read ~/ UserShell` がまだ `/bin/zsh`          | flake では `users.users.<名前>.shell = pkgs.zsh` になっている。`./scripts/apply-system.sh` の再適用とログアウト／再起動のあと、変わらなければ `/etc/shells` に載っている Nix の zsh（通常 **`/run/current-system/sw/bin/zsh`**）を指定して `sudo chsh -s /run/current-system/sw/bin/zsh`。別パスなら `grep zsh /etc/shells` で確認する。 |
| `abbr: command not found`                              | `programs.zsh.zsh-abbr` でプラグインと略語を宣言管理する（手動 `source` は使わない）。 **`./scripts/apply-system.sh`** で HM を再適用し、`exec zsh`。                                                                                                                                                                                    |
| `which -a git` で `/usr/bin` や Homebrew が Nix より先 | `home.sessionPath` と `initContent` 末尾の `PATH` を確認する。まだ Homebrew が先なら `exec zsh` で読み直す。                                                                                                                                                                                                                             |
| `brew untap` / `cleanup` が失敗                        | nixpkgs に移した formula（例 **`opencode`**）が brew に残っていると、`brew bundle --cleanup` や untap が失敗することがある。`brew uninstall opencode` などで消してから再適用。                                                                                                                                                           |
| `darwin-rebuild` がホスト名で失敗                      | `flake.nix` の `hostname` と `scutil --get LocalHostName` を一致させる。                                                                                                                                                                                                                                                                 |
| `darwin-rebuild` が root を要求                        | システム適用は常に管理者権限。`scripts/apply-system.sh` を使う。                                                                                                                                                                                                                                                                         |
