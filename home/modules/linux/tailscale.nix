{
  config,
  lib,
  pkgs,
  ...
}:

let
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
  # tailscale CLI 自身はこの env var を読まないが、ユーザのスクリプトや
  # 手打ち (`tailscale --socket="$TS_SOCKET" ...`) 用に残す。
  # 標準の `tailscale` 実行パスは上の tailscaleCli ラッパー経由で user socket を向く。
  home.sessionVariables.TS_SOCKET = tsSocket;

  # 注意: systemd --user からはシステムの network-online.target を After にできない（無視・失敗の原因になる）。
  # ログイン前から常時起動したい場合は: sudo loginctl enable-linger <user>
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

  home.packages = [ tailscaleCli ];
}
