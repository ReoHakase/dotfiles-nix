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
in
{
  imports = [ ./common.nix ];

  home.username = user;
  home.homeDirectory = "/home/${user}";

  # tailscale / tailscaled CLI がユーザーデーモンと同じソケットを使う（userspace モード）
  home.sessionVariables.TS_SOCKET = tsSocket;

  systemd.user.services.tailscaled = {
    Unit = {
      Description = "Tailscale node agent (userspace networking)";
      After = [ "network-online.target" ];
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

  home.packages = with pkgs; [
    pinentry-gtk2
    tailscale
  ];
}
