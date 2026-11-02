# kcvlのQwenをMacから使う

本家 [Strata 0.2.9](https://github.com/Niko1221/Strata/releases/tag/v0.2.9) のTerminal・Linux CUDAエンジンと公式Macアプリを使う。`strata-nvfp4` forkの実行コードやアップデーターは導入しない。本家が対応するNVFP4 GPTQパックを利用し、独自ビルドの追従を避ける。

モデルはQwen3.8-Flash-Next、NVFP4 GPTQ、コンテキスト32K、同時生成1件、画像なし。初回は約128GBをダウンロードし、実行時には約80GBのRAMを使う見込み。速度と必要なVRAMは実機で確認する。モデルや認証情報はNixストアやGitには保存しない。

## 1. kcvlのGPUを復旧する

2026-11-02の調査ではUbuntu 24.04、RAM 128GB、RTX 5060 Ti。起動中のカーネルは`7.0.0-38-generic`で、NVIDIAモジュールは旧カーネル用しかなく、`nvidia-smi`が失敗した。以下はkcvlにSSHして実行する。sudoパスワードはターミナル内で入力する。

```sh
ssh kcvl
sudo apt-get update
sudo apt-get install linux-modules-nvidia-580-open-generic-hwe-24.04 nvidia-driver-580-open
sudo reboot
```

再接続し、`uname -r`と`nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv`を確認する。現在のカーネルだけにモジュールを追加する場合は`linux-modules-nvidia-580-open-$(uname -r)`を指定できる。更新後のカーネルにもモジュールが入るようHWEのメタパッケージも整合させる。[Ubuntuの手順](https://ubuntu.com/server/docs/how-to/graphics/install-nvidia-drivers/)に従い、NVIDIAの`.run`インストーラーは混在させない。

## 2. Home Manager設定とモデルを準備する

このブランチをMacとkcvlへ配置する。Macは通常の`./scripts/apply-system.sh`、kcvlはリポジトリの既存手順でLinux Home Manager出力を適用する。

```sh
# kcvlのリポジトリ内で実行
home-manager switch --flake .#reohakuta@reohakuta-kcvl
# Terminalのみの導入・署名検証。GPU復旧前にも実行できる
strata-qwen-setup install
# GPU復旧後にモデルを取得・初回起動確認し、最後に停止する
strata-qwen-setup prepare
```

Terminalのインストーラー・署名付き配布元、Macアプリ、制御ベクトルは`pkgs/strata.nix`で版とハッシュを固定する。モデルとエンジンは本家Terminalが取得・検証する。モデルの取得はHome Managerの適用だけでは始まらない。`prepare`を途中で止めた場合は、同じコマンドで再開する。

不安定またはVRAM不足の場合は、停止して`strata-qwen-setup iq3_s`を実行し、本家対応のIQ3_Sへ切り替える。既存のNVFP4モデルは自動削除しない。

## 3. Macから使う

```sh
qwen-start                 # kcvlのサービスと専用SSHトンネルを開始し、読み込みを待つ
qwen-chat                  # AIChatの対話。引数や標準入力も渡せる
qwen-code                  # 現在のディレクトリでOpenCodeを起動
qwen-desktop               # 公式Strataアプリを起動
qwen-stop                  # サーバー停止・RAM解放・専用トンネル切断
```

`kcvl-strata`は`kcvl`と同じホストへ接続し、`127.0.0.1:8180`をkcvlの`127.0.0.1:8080`へ転送する。学外では既存の踏み台設定を使う。ポートが他のプロセスに使われていれば起動は失敗する。Macのスリープや接続断後は起動コマンドを再実行する。サーバーは自動起動しないため、kcvl再起動後も同様に開始できる。

初回の`qwen-desktop`は、公式アプリの`~/.strata/data/model-providers.json`へ`kcvl Strata`というカスタム接続を登録する。登録・モデル変更時はアプリを終了してから実行する。他の接続は保持する。初期画面では`Go straight to the app`を選び、Chatのモデル選択から`kcvl Strata`内のQwenを選ぶ。接続はOpenAI Chat Completions、ベースURLは`http://127.0.0.1:8180/v1`。Mac側でローカルモデルの取得やエンジン起動は不要。

APIキーはkcvlの`~/.config/strata-kcvl/api-key`で生成し、Macの`~/.config/strata-kcvl/`へSSHで同期する。生成したAIChat/OpenCode設定とアプリの接続ファイルは所有者だけが読めるモードで保存する。AIChatとOpenCodeは専用設定を使い、キーをコマンド引数へ含めない。OpenCode 2系は`--standalone`で起動し、既存のバックグラウンドサーバーと専用設定が混ざるのを避ける。通常のツール権限確認は維持する。

## projectionと更新

`uncensored`は別の微調整モデルを意味せず、[本家同梱の拒否方向projection](https://github.com/Niko1221/Strata/blob/v0.2.9/data/experimental-speed-projection/README.md)を有効にした構成。本家の公開エンジン引数を`user_args`へ保存し、4〜44層に適用する。設定は`sampling.experimental_speed_projection=true`。APIの`experimental_speed_projection=false`でリクエストごとに無効にできる。すべての拒否が消える保証はなく、通常の回答にも影響する実験機能として確認する。

```sh
# kcvl
systemctl --user status strata-qwen.service
journalctl --user -u strata-qwen.service -n 60
~/.local/bin/strata profile show launch-kcvl-qwen --effective
```

エンジンログの`control vector mode = project`・`layers 4..44`と再起動後の保持を確認する。ログやプロファイルには認証情報が含まれうるため、そのまま共有しない。

更新時は`qwen-stop`後に本家の`strata update --check`で確認し、更新版を選んで`pkgs/strata.nix`の版・ハッシュを更新する。Home Manager適用後に`strata-qwen-setup install`、`prepare`の順で確認する。本家のエンジン更新を試して失敗した場合は`strata components rollback`で以前のエンジンに戻せる。MacアプリはNix管理のため、アプリ内での更新は使わずNix側で更新する。

## 検証

```sh
python3 -m unittest discover -s tests -v
nix develop -c nixfmt --check home/modules/strata.nix pkgs/strata.nix home/modules/ssh.nix home/darwin.nix home/linux.nix
nix eval --raw .#packages.x86_64-linux.home-reohakuta-kcvl.drvPath
nix eval --raw .#darwinConfigurations.reohakase.system.drvPath
```

実機では日本語の複数ターン会話、生成中断、projectionの保持、OpenCodeの一時ディレクトリでの読取・編集・テスト実行、停止時のRAM解放、SSH再接続を確認する。GPU復旧前に実機推論の確認済みとは扱わない。
