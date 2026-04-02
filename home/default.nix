{ config, pkgs, ... }:

let
  user = "ReoHakase";
in
{
  home.username = user;
  home.homeDirectory = "/Users/${user}";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  xdg.enable = true;

  programs.zsh = {
    enable = true;
    dotDir = config.home.homeDirectory;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    defaultKeymap = "emacs";
    initExtra = ''
      export GPG_TTY=$(tty)
      source ${pkgs.zsh-abbr}/share/zsh-abbr/zsh-abbr.zsh
    '';
    shellAliases = {
      ls = "eza";
      ll = "eza -l";
      la = "eza -la";
    };
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  xdg.configFile."starship.toml".source = ../config/starship.toml;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
  };

  programs.gh.enable = true;

  programs.fzf.enable = true;

  programs.mise = {
    enable = true;
    enableZshIntegration = true;
  };

  home.packages = with pkgs; [
    bat
    eza
    fd
    ffmpeg
    fzf
    gh
    git
    gnupg
    graphviz
    hyperfine
    nmap
    ripgrep
    terminal-notifier
    tmux
    tree-sitter
    typst
    uv
    wget
    yt-dlp
    zsh-abbr
  ];
}
