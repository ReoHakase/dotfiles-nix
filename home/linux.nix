{
  config,
  pkgs,
  lib,
  ...
}:

let
  user = "reohakuta";
  tsStateDir = "${config.home.homeDirectory}/.local/state/tailscale";
  tsState = "${tsStateDir}/tailscaled.state";
  tsSocketDir = "${config.home.homeDirectory}/.tailscale";
  tsSocket = "${tsSocketDir}/tailscaled.sock";

  # tailscale CLI は既定で /var/run/tailscale/tailscaled.sock を見に行き、
  # TS_SOCKET 等の環境変数は読まない。user service で動かしている
  # tailscaled のソケットを指すよう、symlinkJoin + makeWrapper で
  # bin/tailscale に --socket=<user socket> を前置する。
  # tailscaled 本体は同梱の symlink 経由でそのまま利用できる。
  tailscaleCli = pkgs.symlinkJoin {
    name = "tailscale-usersock-${pkgs.tailscale.version}";
    paths = [ pkgs.tailscale ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm -f $out/bin/tailscale
      makeWrapper ${pkgs.tailscale}/bin/tailscale $out/bin/tailscale \
        --add-flags "--socket=${tsSocket}"
    '';
    inherit (pkgs.tailscale) meta;
  };
in
{
  imports = [
    ./common.nix
    ./linux/apps/gui-apps.nix
  ];

  home.username = user;
  home.homeDirectory = "/home/${user}";

  # gpg-agent.conf は Nix が入れた pinentry(gtk2) の絶対パスを指す。
  # home-manager が書き換えるので手編集しない。反映には `gpgconf --kill gpg-agent` が必要。
  home.file.".gnupg/gpg-agent.conf".text = ''
    pinentry-program ${lib.getExe pkgs.pinentry-gtk2}
  '';

  # tailscale CLI 自身はこの env var を読まないが、ユーザのスクリプトや
  # 手打ち (`tailscale --socket="$TS_SOCKET" ...`) 用に残す。
  # 標準の `tailscale` 実行パスは上の tailscaleCli ラッパー経由で user socket を向く。
  home.sessionVariables.TS_SOCKET = tsSocket;

  # Standalone Home Manager でも nix-darwin 側の backupFileExtension と同じ退避名にする。
  home.activation.setHomeManagerBackupExtension = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    export HOME_MANAGER_BACKUP_EXT=hm-backup
  '';

  # Electron（Cursor / VS Code 系の nixpkgs ラッパー）: NIXOS_OZONE_WL と WAYLAND_DISPLAY の両方があるときだけ
  # Ozone/Wayland 向けフラグが付く（nixpkgs vscode generic.nix）。
  # GNOME + Mutter on X11 では通常 WAYLAND_DISPLAY が無いのでこの分岐は効かず、普段は X11 経路。Wayland セッションに
  # 切り替えたとき用に NIXOS_OZONE_WL だけ先に立てておく（X11 のみでも害はない）。
  home.sessionVariables.NIXOS_OZONE_WL = "1";

  # 注意: systemd --user からはシステムの network-online.target を After にできない（無視・失敗の原因になる）。
  # ログイン前から常時起動したい場合は: sudo loginctl enable-linger ${user}
  # これは user unit なので `sudo systemctl ...` では見つからない。操作は `systemctl --user ...` を使う。
  # 初回のみ `tailscale up` でブラウザ認証が必要。完了するまで状態は NeedsLogin のままで tailnet に参加しない。
  systemd.user.services.tailscaled = {
    Unit = {
      Description = "Tailscale node agent (userspace networking)";
      After = [ "basic.target" ];
    };
    Service = {
      ExecStartPre = "${lib.getExe' pkgs.coreutils "mkdir"} -p ${tsStateDir} ${tsSocketDir}";
      ExecStart = "${lib.getExe' pkgs.tailscale "tailscaled"} --state=${tsState} --socket=${tsSocket} --tun=userspace-networking";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "default.target" ];
  };

  # デスクトップなら HM の services.tailscale-systray.enable = true も可（graphical-session 必須）

  home.sessionPath = [
    "${config.home.homeDirectory}/.nix-profile/bin"
    "/nix/var/nix/profiles/default/bin"
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/.cache/lm-studio/bin"
    "${config.home.homeDirectory}/.antigravity/antigravity/bin"
  ];

  programs.zsh.initContent = builtins.readFile ../config/zsh/init-extra-linux.zsh;

  # Apptainer + GPU の前提・`uv` とコンテナの役割分けは MANUAL を参照
  programs.zsh.shellAliases = {
    apx-nv = "apptainer exec --nv";
  };

  home.packages = with pkgs; [
    pinentry-gtk2
    tailscaleCli
    # Neovim / nvim-treesitter / Lazy プラグインのビルド（make / CMake）
    gnumake
    cmake
    ninja
  ];
}
