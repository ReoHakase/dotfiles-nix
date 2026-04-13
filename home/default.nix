{
  config,
  pkgs,
  inputs,
  ...
}:

let
  user = "ReoHakase";
  inherit (pkgs) lib;
  # NixCasks: add GUI apps here (after CI is green). Example:
  # nixCasks = with inputs.nix-casks.packages.${pkgs.system}; [ raycast slack ];
  nixCasks = [ ];
in
{
  home.username = user;
  home.homeDirectory = "/Users/${user}";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  # フォントは nixpkgs（`home.packages`）。Darwin では HM が ~/Library/Fonts/HomeManager へ同期
  fonts.fontconfig.enable = true;

  xdg.enable = true;

  # Nix / HM の bin を先に。続けて Homebrew（`brew` コマンド用。CLI の重複は Nix が優先）。
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

  programs.zsh = {
    enable = true;
    dotDir = config.home.homeDirectory;
    # zsh-autosuggestions / zsh-syntax-highlighting は nixpkgs 由来（HM が .zshrc に source する）。brew 版は不要。
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    defaultKeymap = "emacs";
    # brew shellenv / path_helper のあとでも Nix の bin を先頭に（initContent 末尾で付け直し）
    "zsh-abbr" = {
      enable = true;
      abbreviations = {
        gs = "git switch";
        gsc = "git switch -c";
        gpush = "git push origin HEAD";
        gpull = "git pull origin HEAD";
        "gc-" = "git reset --soft HEAD^";
        gc = "git commit -S";
        ghi = "gh issue create";
        ghp = "gh pr create";
        ghw = "gh repo view -w";
      };
    };
    initContent = builtins.readFile ../config/zsh/init-extra.zsh;
    shellAliases = {
      ls = "eza";
    };
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  xdg.configFile = {
    "starship.toml".source = ../config/starship.toml;
    "gh/config.yml".source = ../config/gh/config.yml;
    "gh/hosts.yml".source = ../config/gh/hosts.yml;
    "glide/glide.toml".source = ../config/glide/glide.toml;
    "mise/config.toml".source = ../config/mise/config.toml;
    "karabiner/karabiner.json".source = ../config/karabiner/karabiner.json;
    "karabiner/assets".source = ../config/karabiner/assets;
    "nvim".source = ../config/nvim;
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    # nixd / Nix の filetype は `config/nvim/lua/polish.lua`（リポジトリの `~/.config/nvim`）
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    # Silence HM warning: legacy default for stateVersion < 25.05
    signing.format = "openpgp";
    settings = {
      credential."https://gist.github.com".helper = [
        ""
        "${pkgs.gh}/bin/gh auth git-credential"
      ];
      credential."https://github.com".helper = [
        ""
        "${pkgs.gh}/bin/gh auth git-credential"
      ];
      gpg.format = "openpgp";
      "gpg \"openpgp\"".program = "${pkgs.gnupg}/bin/gpg";
    };
  };

  # `~/.config/gh/*` は xdg でリポジトリ管理。HM の programs.gh は二重生成を避けるため無効
  programs.gh.enable = false;

  programs.fzf.enable = true;

  programs.mise = {
    enable = true;
    enableZshIntegration = true;
  };

  home.packages =
    with pkgs;
    [
      # フォント（旧 Homebrew cask: font-geist, font-geist-mono-nerd-font, font-noto-*-cjk-jp）
      geist-font
      nerd-fonts.geist-mono
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif

      # CLI は nixpkgs 優先。Homebrew は cask のみ（`hosts` の `brews` / `taps` は空）。
      actrun # github.com/mizchi/actrun（flake オーバーレイ。upstream nixpkgs 未収録）
      act
      arp-scan
      bat
      brotli
      cloc
      dnsutils # dig / host など（brew の bind クライアント相当）
      eza
      fastfetch
      fd
      ffmpeg
      fzf
      gcc
      gettext
      gh
      git
      gnupg
      graphviz
      # guetzli — nixpkgs は x86_64 のみで aarch64-darwin 不可。必要なら `brew install guetzli` や Rosetta
      hyperfine
      inetutils # telnet / ftp など
      jdk
      libwebp # cwebp, dwebp, …
      lzo
      lz4
      mise
      nixd
      nixfmt
      nmap
      opencode
      openssl
      pinentry_mac
      pkgconf
      rWrapper
      ripgrep
      supabase-cli
      tcl
      terminal-notifier
      tk # tcl-tk / wish 用（brew の tcl-tk の一部）
      tmux
      tree-sitter
      typst
      uv
      wget
      xz
      zstd
    ]
    ++ nixCasks;
}
