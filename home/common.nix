{ ... }:
{
  imports = [
    ./modules/apm.nix
    ./modules/editor.nix
    ./modules/git.nix
    ./modules/gpg-agent.nix
    ./modules/packages.nix
    ./modules/shell.nix
    ./modules/ssh.nix
    ./modules/terminal.nix
    ./modules/tex.nix
  ];

  home.stateVersion = "24.11";

  reohakase.apmGlobal.enable = true;

  programs.home-manager.enable = true;

  # Home Manager manual generation pulls in options.json and currently emits
  # a string-context warning during evaluation. We don't need the local
  # `home-configuration.nix` manpage in this setup.
  manual.manpages.enable = false;

  fonts.fontconfig.enable = true;

  xdg.enable = true;
}
