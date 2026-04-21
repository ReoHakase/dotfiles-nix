{
  config,
  pkgs,
  lib,
  ...
}:

let
  user = "ReoHakase";
  nixCasks = [ ];
in
{
  imports = [ ./common.nix ];

  home.username = user;
  home.homeDirectory = "/Users/${user}";

  # gpg-agent.conf は Nix が入れた pinentry-mac の絶対パスを指す。
  # home-manager が書き換えるので手編集しない。反映には `gpgconf --kill gpg-agent` が必要。
  home.file.".gnupg/gpg-agent.conf".text = ''
    pinentry-program ${lib.getExe pkgs.pinentry_mac}
  '';

  home.sessionPath = [
    "/etc/profiles/per-user/${user}/bin"
    "/nix/var/nix/profiles/default/bin"
    "${config.home.homeDirectory}/.local/bin"
    # bun install -g（例: kanna-code）— mise 利用時は ~/.cache/.bun/bin になることがある
    "${config.home.homeDirectory}/.cache/.bun/bin"
    "${config.home.homeDirectory}/.cache/lm-studio/bin"
    "${config.home.homeDirectory}/.antigravity/antigravity/bin"
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
  ];

  programs.zsh.initContent = builtins.readFile ../config/zsh/init-extra.zsh;

  xdg.configFile = {
    "glide/glide.toml".source = ../config/glide/glide.toml;
    "karabiner/karabiner.json".source = ../config/karabiner/karabiner.json;
    "karabiner/assets".source = ../config/karabiner/assets;
  };

  home.packages =
    with pkgs;
    [
      pinentry_mac
      terminal-notifier
    ]
    ++ nixCasks;
}
