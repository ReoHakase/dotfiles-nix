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

  home.username = user;
  home.homeDirectory = "/Users/${user}";

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

  xdg.configFile = {
    "karabiner/karabiner.json".source = ../config/karabiner/karabiner.json;
    "karabiner/assets".source = ../config/karabiner/assets;
  };

  home.packages = [ pkgs.terminal-notifier ] ++ nixCasks;
}
