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
  imports = [
    ./common.nix
    ./linux/apps/gui-apps.nix
  ];

  home.username = user;
  home.homeDirectory = "/home/${user}";

  # tailscale / tailscaled CLI がユーザーデーモンと同じソケットを使う（userspace モード）
  home.sessionVariables.TS_SOCKET = tsSocket;

  # Electron（Cursor / VS Code 系の nixpkgs ラッパー）は NixOS 以外だと未設定になりがち。
  # WAYLAND_DISPLAY があるときだけ --ozone-platform-hint=auto 等が付与される（nixpkgs vscode generic.nix）。
  home.sessionVariables.NIXOS_OZONE_WL = "1";

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

  # Apptainer + GPU の前提・`uv` とコンテナの役割分けは MANUAL を参照
  programs.zsh.shellAliases = {
    apx-nv = "apptainer exec --nv";
  };

  home.packages = with pkgs; [
    pinentry-gtk2
    tailscale
    # Neovim / nvim-treesitter / Lazy プラグインのビルド（make / CMake）
    gnumake
    cmake
    ninja
  ];
}
