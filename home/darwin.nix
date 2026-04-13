{
  config,
  pkgs,
  ...
}:

let
  user = "ReoHakase";
  nixCasks = [ ];
in
{
  imports = [ ./common.nix ];

  home.homeDirectory = "/Users/${user}";

  home.sessionPath = [
    "/etc/profiles/per-user/${user}/bin"
    "/nix/var/nix/profiles/default/bin"
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/.cache/lm-studio/bin"
    "${config.home.homeDirectory}/.antigravity/antigravity/bin"
    "/Library/TeX/texbin"
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
