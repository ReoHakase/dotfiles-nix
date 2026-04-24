{
  config,
  pkgs,
  inputs,
  ...
}:

let
  llmAgentsPkgs = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  # Home Manager manual generation pulls in options.json and currently emits
  # a string-context warning during evaluation. We don't need the local
  # `home-configuration.nix` manpage in this setup.
  manual.manpages.enable = false;

  fonts.fontconfig.enable = true;

  xdg.enable = true;

  programs.zsh = {
    enable = true;
    dotDir = config.home.homeDirectory;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    defaultKeymap = "emacs";
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
        lg = "lazygit";
      };
    };
    shellAliases = {
      ls = "eza";
    };
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  xdg.configFile = {
    "starship.toml".source = ../config/starship.toml;
    "gh/config.yml".source = ../config/gh/config.yml;
    "gh/hosts.yml".source = ../config/gh/hosts.yml;
    "mise/config.toml".source = ../config/mise/config.toml;
    "nvim".source = ../config/nvim;
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withPython3 = false;
    withRuby = false;
  };

  # https://github.com/dandavison/delta — pager + diff filter (bat-compatible themes)
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
    };
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    signing.format = "openpgp";
    settings = {
      merge.conflictStyle = "zdiff3";
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

  programs.gh.enable = false;

  programs.fzf.enable = true;

  programs.mise = {
    enable = true;
    enableZshIntegration = true;
  };

  # LuaLaTeX + 日本語（luatexja / ltjsbook）。macOS の BasicTeX は使わず Nix に統一。
  home.file.".latexmkrc".source = ../config/latex/latexmkrc;

  home.packages = with pkgs; [
    geist-font
    nerd-fonts.geist-mono
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif

    actrun
    act
    arp-scan
    bat
    bottom
    brotli
    cloc
    llmAgentsPkgs.apm
    llmAgentsPkgs.claude-code
    llmAgentsPkgs.codex
    dnsutils
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
    hyperfine
    inetutils
    jdk
    just
    lazygit
    libwebp
    lzo
    lz4
    # Markdown LSP (PKM). aerial.nvim の treesitter backend は nvim 0.12 の
    # Query:iter_matches API 変更（`all = false` 削除）で Markdown を開くと
    # クラッシュする。LSP が attach すれば aerial は LSP backend を使うので
    # その経路を経由しなくなる。ついでに wikilink / backlink / todo 補完が効く。
    markdown-oxide
    mise
    nixd
    nixfmt
    nmap
    opencode
    openssl
    pkgconf
    rWrapper
    ripgrep
    supabase-cli
    tcl
    tk
    tmux
    tree-sitter
    typst
    (texliveSmall.withPackages (
      ps: with ps; [
        collection-langjapanese
        latexmk
        biber
      ]
    ))
    uv
    wget
    yazi
    xz
    zstd
  ];
}
