{ inputs, ... }:
let
  envOr =
    name: fallback:
    let
      value = builtins.getEnv name;
    in
    if value != "" then value else fallback;
in
{
  imports = [
    inputs.agent-skills.homeManagerModules.default
    ./modules/editor.nix
    ./modules/skills.nix
    ./modules/container/git.nix
    ./modules/container/packages.nix
    ./modules/container/shell.nix
    ./modules/container/terminal.nix
  ];

  home.username = envOr "DOTFILES_HM_USERNAME" "vscode";
  home.homeDirectory = envOr "DOTFILES_HM_HOME" "/home/vscode";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;
  manual.manpages.enable = false;
  xdg.enable = true;
}
