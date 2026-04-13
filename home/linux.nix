{
  config,
  pkgs,
  ...
}:

let
  user = "ReoHakase";
in
{
  imports = [ ./common.nix ];

  home.homeDirectory = "/home/${user}";

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
  ];
}
