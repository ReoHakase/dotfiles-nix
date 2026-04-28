{
  config,
  pkgs,
  inputs,
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;
  llmAgentsPkgs = inputs.llm-agents.packages.${system};
  apm = pkgs.callPackage ../pkgs/apm-codex-user-scope.nix {
    inherit (llmAgentsPkgs) apm;
  };
  tmuxAutoreload = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux-autoreload";
    version = "0.0.1";
    src = pkgs.fetchFromGitHub {
      owner = "b0o";
      repo = "tmux-autoreload";
      rev = "v0.0.1";
      hash = "sha256-SYzn18gMYFwrsBKIu1HSStSq96MFJQc36QSGfI7bTZo=";
    };
    rtpFilePath = "tmux-autoreload.tmux";
  };
  tmuxPowerkit = pkgs.callPackage (
    pkgs.fetchFromGitHub {
      owner = "fabioluciano";
      repo = "tmux-powerkit";
      rev = "372b891e6c1884dd3b959f101336c92fa89056ec";
      hash = "sha256-rYDxaELzJNmn2+ndLBjhUSNZjwg8tf7lT4iwCAU4nfQ=";
    }
    + "/default.nix"
  ) { };
in
{
  imports = [ ../modules/apm.nix ];

  home.stateVersion = "24.11";

  reohakase.apmGlobal.enable = true;

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
    "lazygit/config.yml".source = ../config/lazygit/config.yml;
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

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        forwardAgent = false;
        addKeysToAgent = "no";
        compression = false;
        serverAliveInterval = 0;
        serverAliveCountMax = 3;
        hashKnownHosts = false;
        userKnownHostsFile = "~/.ssh/known_hosts";
        controlMaster = "no";
        controlPath = "~/.ssh/master-%r@%n:%p";
        controlPersist = "no";
        setEnv.TERM = "xterm-256color";
      };
      kcvl = {
        hostname = "192.168.100.149";
        user = "reohakuta";
        proxyJump = "reoo.hakuta@gw.vision.is.kit.ac.jp";
      };
    };
  };

  programs.gh.enable = false;

  programs.fzf.enable = true;

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.mise = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.tmux =
    let
      clipboardCommand =
        if pkgs.stdenv.isDarwin then
          "/usr/bin/pbcopy"
        else
          "${pkgs.xclip}/bin/xclip -selection clipboard -in";
    in
    {
      enable = true;
      aggressiveResize = true;
      escapeTime = 0;
      historyLimit = 50000;
      mouse = true;
      shell = "${pkgs.zsh}/bin/zsh";
      terminal = "tmux-256color";
      plugins = with pkgs.tmuxPlugins; [
        sensible
        tmux-fzf
        session-wizard
        resurrect
        continuum
        tmuxAutoreload
        {
          plugin = tmuxPowerkit;
          extraConfig = ''
            set -g @powerkit_plugins "datetime,battery,cpu,memory,git,hostname"
            set -g @powerkit_theme "onedark"
            set -g @powerkit_theme_variant "dark"
            set -g @powerkit_separator_style "rounded"
            set -g @powerkit_elements_spacing "both"
            set -g @powerkit_status_interval "5"
            set -g @powerkit_transparent "true"
          '';
        }
      ];
      extraConfig = ''
        set -g status-interval 5
        set -g renumber-windows on
        set -g default-command "exec ${pkgs.zsh}/bin/zsh"
        set -g set-clipboard on
        set -g copy-command "${clipboardCommand}"

        source-file ${pkgs.tmuxPlugins.tmux-which-key}/share/tmux-plugins/tmux-which-key/plugin/init.example.tmux
      '';
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
    commitlint-rs
    apm
    dotenvx
    entr
    lefthook
    llmAgentsPkgs.claude-code
    llmAgentsPkgs.codex
    dnsutils
    eternal-terminal
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
    sesh
    supabase-cli
    tcl
    tk
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
