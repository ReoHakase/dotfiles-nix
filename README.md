# dotfiles-nix（引き継ぎメモ）

macOS 向けに **Nix flakes + nix-darwin + home-manager** でシェル・CLI・一部 UI 設定を宣言管理するリポジトリ。元々は Homebrew 中心だった構成から、**formula 相当は極力 Nix に寄せ、`brew list` を小さくする**ことを目的としている。

## スタック

| 役割 | 内容 |
|------|------|
| インストーラ | [Determinate Nix Installer](https://github.com/DeterminateSystems/nix-installer)（flakes 有効） |
| OS 統合 | [nix-darwin](https://github.com/LnL7/nix-darwin)（`system.defaults`、ユーザシェル、`/etc/nix` など） |
| ユーザ環境 | [home-manager](https://github.com/nix-community/home-manager)（zsh、starship、nvim、パッケージ群） |
| 入力 | `nixpkgs-unstable`（`flake.nix` の `inputs` を参照） |

**Cask / GUI アプリ**は厳密なハッシュ管理を前提にしない。必要なら (1) 手動インストール、(2) 残りの Homebrew 専用、(3) nix-darwin の `homebrew` モジュール、のいずれかで運用する想定。`hosts/reohakase.nix` 末尾にコメント例あり。

## 前提（このマシン向けの固定値）

- **ユーザー名:** `ReoHakase`（`flake.nix` と `home/default.nix` の両方）
- **Darwin 構成名（flake 出力）:** `reohakase`（`hostname -s` / `scutil --get LocalHostName` と揃える）
- **アーキテクチャ:** `aarch64-darwin`（Apple Silicon）

別 Mac や別ユーザーに載せ替えるときは、少なくとも `flake.nix` の `user` / `hostname`、`hosts/` のファイル名、`home/default.nix` の `home.username` と `home.homeDirectory` を合わせる。

## ディレクトリ構成

```
flake.nix              # inputs と darwinConfigurations.reohakase
flake.lock             # 入力のロック（コミットする）
hosts/reohakase.nix    # nix-darwin（Nix、defaults、users、HM の読み込み）
home/default.nix       # home-manager（zsh / starship / neovim / packages）
config/starship.toml   # HM が xdg.configFile で配布
```

Flake は **Git で追跡されたファイルだけ**を見る。未コミットの変更は `nix` が警告を出すことがある。

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

**設定を本番適用（管理者権限が必要）:**

```bash
cd /path/to/dotfiles-nix
darwin-rebuild switch --flake .#reohakase
```

まだ `darwin-rebuild` が無い初回は、例:

```bash
nix run nix-darwin --extra-experimental-features 'nix-command flakes' -- \
  switch --flake /path/to/dotfiles-nix#reohakase
```

適用後は新しいターミナルを開くか `exec zsh` で、Nix 管理の `zsh` と HM を読み込ませる。

## 何がどこで管理されているか

- **nix-darwin（`hosts/reohakase.nix`）**  
  - `nix` の `experimental-features`、ストア最適化  
  - ログインシェルを Nix の `zsh` に  
  - `system.defaults.*`（ダークモード、Finder、Dock、トラックパッドなど）  
  - 新しい nix-darwin では `system.defaults` 利用に **`system.primaryUser`** が必須（コメント参照）

- **home-manager（`home/default.nix`）**  
  - zsh（補完・autosuggestion・syntax-highlighting、`zsh-abbr` の読み込み）  
  - starship（`config/starship.toml` を `~/.config` 相当へ）  
  - neovim、git、gh、fzf、mise  
  - CLI パッケージ（`bat`、`eza`、`ffmpeg`、`tmux` など。必要に応じて `home.packages` を増減）

## Homebrew からの移行（方針メモ）

1. この flake を `darwin-rebuild switch` まで通し、**パス上のツールが Nix 由来になることを確認**する。  
2. `brew list --formula` を見て、Nix で代替済みのものから `brew uninstall` していく（依存は `brew autoremove` などで整理）。  
3. Cask は別方針（上記）で残すか、別インストールにする。  
4. 既存の `~/.zshrc` が HM 生成物と二重にならないよう、**エイリアスやパス設定は `home/default.nix` に寄せる**と安全。

## トラブル時のヒント

- **`darwin-rebuild` がホスト名で失敗:** `flake.nix` の `hostname` と `scutil --get LocalHostName` を一致させる。  
- **Flake が古いファイルしか見ない:** 変更を `git add` / `commit` するか、警告に従う。  
- **Nix のアンインストール:** Determinate インストールの場合は [nix-installer の README](https://github.com/DeterminateSystems/nix-installer) の `nix-installer uninstall` を参照。

---

最終更新: 引き継ぎ用にリポジトリの現状に合わせて記載。構成を変えたらこの README も更新すること。
