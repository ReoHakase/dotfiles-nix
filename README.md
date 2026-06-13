# ❄️ dotfiles-nix（引き継ぎメモ）

**Nix flakes + home-manager** でシェル・CLI・ドットファイルを宣言管理するリポジトリ。macOS では **nix-darwin** も利用し、Ubuntu LTS などでは **Home Manager のみ**（flake の `homeConfigurations`）で `home/common.nix` と `home/modules/` を Mac と共有する。元々は Homebrew 中心だった構成から、**formula 相当は極力 Nix に寄せ、`brew list` を小さくする**ことを目的としている。

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
  - [Dev Containers の dotfiles install](#dev-containers-の-dotfiles-install)
  - [Ubuntu LTS（reohakuta-kcvl）: Home Manager のみ](#ubuntu-ltsreohakuta-kcvl-home-manager-のみ)
  - [何がどこで管理されているか](#何がどこで管理されているか)
    - [nix-darwin（`hosts/reohakase.nix`）](#nix-darwinhostsreohakasenix)
    - [home-manager（`home/modules/` ほか）](#home-managerhomemodules-ほか)
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
| Agent Skills | [agent-skills-nix](https://github.com/Kyure-A/agent-skills-nix)（`.agents` / `.claude` / `.cursor` 向け skill 配布） |
| Linux（Ubuntu 等） | nix-darwin に相当する OS 統合は**無し**。`home/linux.nix` + `homeConfigurations.reohakuta@reohakuta-kcvl` のみ適用。GUI は **Ghostty（nixpkgs）・Cursor（nixpkgs の AppImage 版）・Proton VPN（nixpkgs）・VeraCrypt（nixpkgs）・Vicinae（公式 AppImage + 固定 hash）** を Home Manager で入れられる（`home/modules/linux/gui-apps.nix`）。 |
| 入力         | `nixpkgs-unstable`（`flake.nix` の `inputs` を参照）                                                 |
| LaTeX（LuaLaTeX + 日本語） | [`home/modules/tex.nix`](home/modules/tex.nix) の TeX Live（`collection-langjapanese` 等）。**BasicTeX は使わない**（Nix に統一）。設定例: [traP: TeXエンジン比較](https://trap.jp/post/2596/)。`~/.latexmkrc` は [`config/latex/latexmkrc`](config/latex/latexmkrc) を HM が配布。`graphicscache` を使うなら別途 `pkgs.ghostscript` を足すなど。 |

> [!NOTE] > **Cask / GUI アプリ**は厳密なハッシュ管理を前提にしない。必要なら (1) 手動インストール、(2) 残りの Homebrew 専用、(3) nix-darwin の `homebrew` モジュール、のいずれかで運用する想定。`hosts/reohakase.nix` 末尾にコメント例あり。

> [!IMPORTANT] > **Determinate Nix を使う場合:** [Determinate](https://github.com/DeterminateSystems/nix-installer) は Nix のインストールを独自に管理するため、nix-darwin の `nix.*`（`/etc/nix` など）と競合し、`Determinate detected, aborting activation` で止まる。このリポジトリでは `hosts/reohakase.nix` で **`nix.enable = false`** とし、Nix 本体の設定は Determinate / 手元の `nix.conf` に任せる。詳細は [MANUAL.md](MANUAL.md) の「Determinate Nix と nix-darwin」。

> [!NOTE]
> `claude-code` / `codex` は [`numtide/llm-agents.nix`](https://github.com/numtide/llm-agents.nix) から入れる。Agent Skills は [`agent-skills-nix`](https://github.com/Kyure-A/agent-skills-nix) で Home Manager から配布する。`flake.nix` には Numtide cache の `nixConfig` を置いているが、Determinate Nix では非 trusted user からの `extra-substituters` / `trusted-public-keys` は無視されることがある。その場合でも `nix flake check --all-systems` は通るが、cache を使うには trusted な Nix 設定（例: `/etc/nix/nix.conf` や Determinate 側の管理設定）に次を入れる。
>
> ```conf
> extra-substituters = https://cache.numtide.com
> extra-trusted-public-keys = niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=
> ```

## 前提（このマシン向けの固定値）

| 項目                        | 値                                                                   |
| --------------------------- | -------------------------------------------------------------------- |
| macOS ユーザー名            | `ReoHakase`（`flake.nix` の `user`、`home/darwin.nix`） |
| Darwin 構成名（flake 出力） | `reohakase`（`hostname -s` / `scutil --get LocalHostName` と揃える） |
| Linux ユーザー名            | `reohakuta`（`home/linux.nix`、`flake.nix` の `linuxUser`） |
| Linux HM 出力名           | `reohakuta@reohakuta-kcvl`（`flake.nix` の `linuxHmHostname`） |
| macOS アーキテクチャ              | `aarch64-darwin`（Apple Silicon）                                    |
| Ubuntu（この flake の既定） | `x86_64-linux`（`flake.nix` の `linuxSystem`。ARM なら `aarch64-linux` に変更） |

別 Mac・別ユーザー・別 Linux ユーザーに載せ替えるときは、`flake.nix` の `user` / `hostname` / `linuxSystem` / `linuxUser` / `linuxHmHostname`、`hosts/` のファイル名、`home/darwin.nix` または `home/linux.nix` の `home.homeDirectory` を合わせる。

## ディレクトリ構成

```
flake.nix              # darwinConfigurations.reohakase + homeConfigurations.reohakuta@reohakuta-kcvl
flake.lock             # 入力のロック（コミットする）
hosts/reohakase.nix    # nix-darwin（defaults、users、HM → home/default.nix）
home/default.nix       # macOS 向けエントリ（import ./darwin.nix）
home/darwin.nix        # macOS（common + Karabiner / Glide / brew PATH など）
home/linux.nix         # Ubuntu 等（common + Linux PATH / Linux 固有 aliases）
home/common.nix        # 共有 Home Manager entry（home/modules/* を import）
home/modules/          # shell/git/ssh/terminal/editor/packages/tex/gpg-agent/skills など
home/modules/linux/    # Linux 向け GUI と user-space Tailscale
pkgs/gui/ghostty.nix   # Linux: nixpkgs の ghostty を薄く再エクスポート（flake の `packages` 用）
pkgs/appimages/        # Linux: Cursor（nixpkgs の AppImage 版）・Vicinae（固定 URL + hash）
config/latex/latexmkrc  # LuaLaTeX 用 ~/.latexmkrc の元ファイル
scripts/apply-system.sh # darwin-rebuild を root で実行するヘルパー
.github/workflows/nix.yml      # Nix 検証 CI（lint + Linux/Darwin eval）
.github/workflows/renovate.yml # Renovate（flake.lock / fixed-output hash 更新）
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

Git hook を入れる:

```bash
nix develop -c lefthook install
nix develop -c lefthook run pre-commit --all-files
```

`pre-commit` は staged の Nix ファイルに `nixfmt --check` / `statix check` / `deadnix --fail` をかけ、`flake.nix` / `flake.lock` 変更時は `nix flake lock --no-update-lock-file` で lockfile の同期漏れを止める。

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

## Dev Containers の dotfiles install

[Dev Containers の dotfiles 機能](https://code.visualstudio.com/docs/devcontainers/containers#_personalizing-with-dotfile-repositories)向けに、リポジトリ直下の [`install.sh`](install.sh) を用意している。これは Dev Container 内で Home Manager を適用する entrypoint。基本はコンテナイメージ、Feature、またはプロジェクト側のセットアップで、dotfiles install より前に `nix` が PATH から見える状態にしておく。必要な場合だけ、`DOTFILES_AUTO_INSTALL_NIX=1` で [Determinate Nix Installer](https://github.com/DeterminateSystems/nix-installer) による Nix の自動インストールを opt-in できる。

VS Code の User Settings 例:

```jsonc
{
  "dotfiles.repository": "ReoHakase/dotfiles-nix",
  "dotfiles.targetPath": "~/dotfiles",
  "dotfiles.installCommand": "install.sh"
}
```

`dotfiles.targetPath` は、Dev Containers が **コンテナ内で dotfiles リポジトリを clone する場所**を指す。上の例では、Mac 側の `~/dotfiles` ではなく、Dev Container 内の `~/dotfiles` にこのリポジトリが clone され、そのディレクトリで `./install.sh` が実行される。`install.sh` は自身の配置場所をリポジトリ root として扱うため、必要なら `~/.dotfiles` など別の clone 先に変えてもよい。

`install.sh` は、Dev Container 内の `$(id -un)@$(hostname -s)` から `homeConfigurations.<user>@<host>` を自動解決する。たとえば現在の Linux 向け出力は `homeConfigurations.reohakuta@reohakuta-kcvl` なので、ユーザー名やホスト名が一致するコンテナなら追加設定なしで適用できる。

ユーザー名が `vscode` だったり、ホスト名がコンテナ ID になる環境では flake 出力と一致しない。その場合は `.devcontainer/devcontainer.json` などで `DOTFILES_HM_USER` / `DOTFILES_HM_HOST` を明示する:

```jsonc
{
  "remoteEnv": {
    "DOTFILES_HM_USER": "reohakuta",
    "DOTFILES_HM_HOST": "reohakuta-kcvl"
  }
}
```

出力名を直接指定したい場合は `DOTFILES_HM_OUTPUT` を使う。優先順位は `--hm-output`、`DOTFILES_HM_OUTPUT`、`DOTFILES_HM_USER` / `DOTFILES_HM_HOST` と現在値から作る `<user>@<host>` の順。

```jsonc
{
  "remoteEnv": {
    "DOTFILES_HM_OUTPUT": "reohakuta@reohakuta-kcvl"
  }
}
```

`nix` が無いコンテナでも dotfiles 側で bootstrap したい場合だけ、次のように opt-in する。`home-manager` コマンドが無い場合は直接インストールせず、`nix run github:nix-community/home-manager -- switch ...` で初回適用する。

```jsonc
{
  "remoteEnv": {
    "DOTFILES_AUTO_INSTALL_NIX": "1"
  }
}
```

Dev Containers CLI の実装では `installCommand` はシェルコマンド文字列ではなく、dotfiles の `targetPath` 内にある実行ファイル名として扱われる。つまり `install.sh --hm-output ...` や `DOTFILES_HM_OUTPUT=... ./install.sh` のようには書かず、Dev Containers では上の `remoteEnv` で環境変数を渡す。`--hm-output` / `--auto-install-nix` は、コンテナ内で手動実行するときや wrapper から呼ぶときの option。`install.sh` は冒頭にリポジトリ URL を表示し、ログには `[ReoHakase/dotfiles-nix]` prefix を付ける。候補が見つからない場合は、解決した出力名と利用可能な `homeConfigurations` を表示して異常終了する。

## Ubuntu LTS（reohakuta-kcvl）: Home Manager のみ

macOS の `nix-darwin`（ログインシェル・`system.defaults`・Homebrew cask 宣言など）に相当するものは **Ubuntu 上には無い**。**ユーザー環境だけ**を [home/linux.nix](home/linux.nix) で宣言し、Mac との差は次のとおりです。

| Mac（`home/darwin.nix`） | Ubuntu（`home/linux.nix`） |
| ------------------------ | --------------------------- |
| Karabiner・Glide の `xdg.configFile` | 無し（macOS用） |
| `pinentry_mac` / `terminal-notifier` | `pinentry-gtk2`（GPG 用） |
| `sessionPath` に Homebrew・TeX 等 | `~/.nix-profile/bin` 中心 |
| zsh 追記 | [`home/modules/shell.nix`](home/modules/shell.nix) で共通生成。Linux だけ `PYTHONNOUSERSITE=1` を `home/linux.nix` で追加 |
| NixCasks 等の macOS GUI | [home/modules/linux/gui-apps.nix](home/modules/linux/gui-apps.nix)（Ghostty・Cursor・Proton VPN・VeraCrypt・Vicinae）。個別に `nix build` する場合は `packages.x86_64-linux.{ghostty,cursor-appimage,proton-vpn,veracrypt,vicinae-appimage}` |
| `services.tailscale`（launchd + CLI、`hosts/reohakase.nix`） | `systemd.user` の `tailscaled`（userspace）、`pkgs.tailscale`、`TS_SOCKET`（root 無し。サブネットルータ等は制限あり） |

**前提:** Nix（flakes 有効）を入れる（例: [Determinate Nix Installer](https://github.com/DeterminateSystems/nix-installer)）。Linux のユーザー名・ホームが `reohakuta` / `/home/reohakuta` でない場合は `home/linux.nix` と `flake.nix` の `linuxUser` / `linuxHmHostname` / `homeConfigurations` 名を合わせる。**ARM PC** なら `flake.nix` の `linuxSystem` を `"aarch64-linux"` に変更する。

ビルドで drv の確認のみ:

```bash
cd /path/to/dotfiles-nix
nix flake check
nix build '.#packages.x86_64-linux.home-reohakuta-kcvl' --no-link
# （任意）Linux GUI パッケージだけ確認する場合
# nix build '.#packages.x86_64-linux.ghostty' --no-link
# nix build '.#packages.x86_64-linux.cursor-appimage' --no-link
# nix build '.#packages.x86_64-linux.vicinae-appimage' --no-link
```

初回適用（Home Manager 未インストールでも可）:

```bash
cd /path/to/dotfiles-nix
nix run github:nix-community/home-manager -- switch --flake .#reohakuta@reohakuta-kcvl
```

2 回目以降:

```bash
home-manager switch --flake .#reohakuta@reohakuta-kcvl
```

**ログインシェルを zsh にする**（Ubuntu は手動。`/etc/shells` に Nix の zsh を追加してから `chsh`）:

```bash
grep zsh /etc/shells || echo '/nix/var/nix/profiles/default/bin/zsh' | sudo tee -a /etc/shells
chsh -s "$(which zsh)"
```

**Linux GUI:** `home/modules/linux/gui-apps.nix` で **Ghostty**（nixpkgs）、**Cursor**（nixpkgs の `code-cursor` / AppImage ラッパー）、**Proton VPN**（nixpkgs の `proton-vpn`）、**VeraCrypt**（nixpkgs）、**Vicinae**（GitHub リリースの AppImage を `fetchurl` + SRI hash で固定）を入れている。Vicinae のバージョンを上げるときは `pkgs/appimages/vicinae.nix` の `version` / `url` / `hash` を更新し、`nix-prefetch-url '<url>' --type sha256` や `nix hash path <store-path>` で hash を取り直す。詳細は [MANUAL.md](MANUAL.md) の「Linux（Ubuntu）GUI」。

**Apptainer / GPU:** ドライバはホストに入れ、`nvidia-smi` がホストで通ることを先に確認する。コンテナでは `apptainer exec --nv`（`home/linux.nix` の zsh 略記 `apx-nv`）を参照。ホストの `uv` / venv とコンテナ内 Python の切り分けは [MANUAL.md](MANUAL.md) の「Apptainer・GPU とコンテナ」。

**Tailscale（Ubuntu）:** `home-manager switch` 後、`systemctl --user enable --now tailscaled`（HM がユニットを入れるので初回だけでも可）。`systemctl --user status tailscaled` で確認。**user unit なので `sudo systemctl start tailscaled` では「Unit not found」になる**。操作は必ず `systemctl --user ...` を使う。ユーザーユニットは **システムの `network-online.target` に依存できない**ため、`After` はユーザ側の `basic.target` のみにしている。**ログイン前から** `tailscaled` を載せたい場合は `sudo loginctl enable-linger <ユーザー名>`。**初回は `tailscale up` でブラウザ認証が必須**。完了するまで `tailscale status` は `NeedsLogin` のままで tailnet に参加しない。**userspace モード**のため、exit ノードやサブネット広告など **フル TUN が要る用途では足りない**ことがある。その場合は公式の Linux インストール（system `tailscaled`）など別経路を検討する。

**Tailscale（macOS）:** `hosts/reohakase.nix` の `services.tailscale`。MagicDNS で管理画面の「Override local DNS」を使う場合のみ `overrideLocalDns` を検討し、**DNS 設定を誤ると名前解決全体が壊れる**ので nix-darwin マニュアルと Tailscale 側の前提を確認する。`darwin-rebuild` がハングする事例は [nix-darwin#1688](https://github.com/nix-darwin/nix-darwin/issues/1688) を参照。

## 何がどこで管理されているか

### nix-darwin（`hosts/reohakase.nix`）

- Nix のインストールは **管理しない**（`nix.enable = false`、Determinate 利用時）。`experimental-features` 等は Determinate / `nix.conf` 側
- ログインシェルを Nix の `zsh` に
- `system.defaults.*`（ダークモード、Finder、Dock、トラックパッドなど）
- 新しい nix-darwin では `system.defaults` 利用に **`system.primaryUser`** が必須（コメント参照）
- **Tailscale:** `services.tailscale`（`tailscaled` / CLI）

### home-manager（`home/modules/` ほか）

- **共通（`home/common.nix`）:** `home/modules/*` と `agent-skills-nix` の import、HM 共通の土台（stateVersion、manual、fontconfig、xdg）
- **共有モジュール（`home/modules/`）:** zsh、starship、direnv、mise、neovim、git、gh、ssh、tmux、lazygit、Ghostty shader、CLI パッケージ、TeX Live、GPG pinentry、Agent Skills
- **macOS（`home/darwin.nix`、`home/default.nix` 経由）:** Karabiner・Glide、macOS 向け `sessionPath`、`terminal-notifier`、`mole` など（**`/Library/TeX/texbin` は入れない**）
- **Linux（`home/linux.nix` + `home/modules/linux/`）:** Linux 向け `sessionPath`、`PYTHONNOUSERSITE`、`tailscale` と **userspace** の `systemd.user` `tailscaled`、`TS_SOCKET`、**GUI**
> [!NOTE] > **なぜ `hosts/` と `home/` が分かれるか:** システム全体（ユーザー作成・defaults・Homebrew）と、ユーザーのホーム・ドットファイルの責務が違うため。概要は会話メモか [MANUAL.md](MANUAL.md) を参照。

## Homebrew からの移行（方針メモ）

1. この flake を `darwin-rebuild switch` まで通し、**パス上のツールが Nix 由来になることを確認**する。
2. `brew list --formula` を見て、Nix で代替済みのものから `brew uninstall` していく（依存は `brew autoremove` などで整理）。
3. Cask は別方針（上記）で残すか、別インストールにする。
4. 既存の `~/.zshrc` が HM 生成物と二重にならないよう、**エイリアスやパス設定は `home/modules/shell.nix` / OS 別モジュールに寄せる**と安全。

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

- [x] 手元の `~/.zshrc` の内容を確認し、**abbr・関数・PATH・mise/uv など**を `home/modules/shell.nix` / OS 別モジュールの `programs.zsh` / `sessionPath` に移植した（または意図的に捨てた）
- [x] `starship` / `direnv` / `mise` / `lazygit` / `gh` の小さい設定は、個別ファイルではなく Home Manager の `programs.*.settings` に寄せた
- [x] Neovim は当面 `programs.neovim` のみ。`~/.config/nvim` を宣言管理する場合の選択肢は [MANUAL.md](MANUAL.md) に記載
- [x] GPG・SSH エージェントなど、**秘密情報や機種依存**はリポジトリに含めず、[MANUAL.md](MANUAL.md) のとおりローカルのみで扱う
- [x] nix-darwin で macOS の設定を管理する (`hosts/reohakase.nix` の `system.defaults` など)
- [x] Nix 検証用 GitHub Actions を戻した（`.github/workflows/nix.yml`。検証内容は [MANUAL.md](MANUAL.md)「CI」を参照）
- [x] nix-casks を flake に取り込み、`home/darwin.nix` の `nixCasks` で GUI を足せる状態にした — 使い方は [MANUAL.md](MANUAL.md) と https://nix-casks.yorganci.dev/

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
| `ignoring untrusted substituter 'https://cache.numtide.com'` | `claude-code` / `codex` 用の Numtide cache 設定が trusted user ではないため無視されている。check 自体が通るなら問題なし。cache を使うなら上記の trusted な Nix 設定に追記する。 |
| `No space left on device`                   | ディスク空きを増やし、`nix-collect-garbage -d` などでストアを整理する。詳細は [MANUAL.md](MANUAL.md) の「ディスク不足」。                                                        |
| `darwin-rebuild` がホスト名で失敗           | `flake.nix` の `hostname` と `scutil --get LocalHostName` を一致させる。                                                                                                         |
| Flake が古いファイルしか見ない              | 変更を `git add` / `commit` するか、警告に従う。                                                                                                                                 |
| Nix のアンインストール                      | Determinate インストールの場合は [nix-installer の README](https://github.com/DeterminateSystems/nix-installer) の `nix-installer uninstall` を参照。                            |

> [!WARNING] > **`Existing file … would be clobbered` で止まる**ときは、退避ファイルと HM の「どちらを正にするか」を決めてから再適用。手順は [MANUAL.md](MANUAL.md)「`~/.config` とリポジトリが食い違ったとき」。

---

最終更新: 引き継ぎ用にリポジトリの現状に合わせて記載。構成を変えたらこの README も更新すること。
