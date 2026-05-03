{
  config,
  lib,
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

  tmuxCowboy = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "cowboy";
    version = "2021-05-11";
    src = pkgs.fetchFromGitHub {
      owner = "tmux-plugins";
      repo = "tmux-cowboy";
      rev = "75702b6d0a866769dd14f3896e9d19f7e0acd4f2";
      hash = "sha256-KJNsdDLqT2Uzc25U4GLSB2O1SA/PThmDj9Aej5XjmJs=";
    };
  };
  ghosttyCursorShaders = pkgs.fetchFromGitHub {
    owner = "sahaj-b";
    repo = "ghostty-cursor-shaders";
    rev = "4faa83e4b9306750fc8de64b38c6f53c57862db8";
    hash = "sha256-ruhEqXnWRCYdX5mRczpY3rj1DTdxyY3BoN9pdlDOKrE=";
  };
  tmuxPowerkitOneDarkProNightFlat = pkgs.writeText "tmux-powerkit-onedark-pro-night-flat.sh" ''
    declare -gA THEME_COLORS=(
      [background]="default"

      [statusbar-bg]="default"
      [statusbar-fg]="#9da5b4"

      [session-bg]="#4aa5f0"
      [session-fg]="#16191d"
      [session-prefix-bg]="#d18f52"
      [session-copy-bg]="#42b3c2"
      [session-search-bg]="#d18f52"
      [session-command-bg]="#c162de"

      [window-active-base]="#23272e"
      [window-active-style]="bold"
      [window-inactive-base]="#1e2227"
      [window-inactive-style]="none"
      [window-activity-style]="italics"
      [window-bell-style]="bold"
      [window-zoomed-bg]="#42b3c2"

      [pane-border-active]="#4aa5f0"
      [pane-border-inactive]="#3e4452"

      [ok-base]="#23272e"
      [good-base]="#8cc265"
      [info-base]="#42b3c2"
      [warning-base]="#d18f52"
      [error-base]="#e05561"
      [disabled-base]="#667187"

      [message-bg]="default"
      [message-fg]="#abb2bf"

      [popup-bg]="#1e2227"
      [popup-fg]="#abb2bf"
      [popup-border]="#3e4452"
      [menu-bg]="#1e2227"
      [menu-fg]="#abb2bf"
      [menu-selected-bg]="#2c313a"
      [menu-selected-fg]="#d7dae0"
      [menu-border]="#3e4452"
    )
  '';
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
    "ghostty/config".source = ../config/ghostty/config;
    "ghostty/shaders".source = ghosttyCursorShaders;
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
    signing = {
      format = "openpgp";
      signByDefault = true;
    };
    settings = {
      user = {
        name = "Reo Hakuta";
        email = "reonaldhkt@gmail.com";
      };
      # Host-specific signing keys are intentionally kept out of the repo.
      # Put `user.signingKey = ...` in ~/.config/git/local on each machine.
      include.path = "~/.config/git/local";
      init.defaultBranch = "main";
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

  # Git reads ~/.gitconfig after ~/.config/git/config. Keep this managed so old
  # local identity values cannot override the declarative identity above, while
  # still allowing each host to set its own signing key in ~/.config/git/local.
  home.file.".gitconfig".text = ''
    [include]
      path = ~/.config/git/local
  '';

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
        tmuxCowboy
        tmux-fzf
        session-wizard
        resurrect
        continuum
        tmuxAutoreload
        {
          plugin = tmuxPowerkit;
          extraConfig =
            let
              powerkitPlugins =
                if pkgs.stdenv.isDarwin then
                  "datetime,battery,cpu,memory,netspeed,git,hostname"
                else
                  "datetime,battery,cpu,memory,gpu,netspeed,git,hostname";
              powerkitGpuConfig = lib.optionalString (!pkgs.stdenv.isDarwin) ''
                set -g @powerkit_plugin_gpu_metric "usage,memory"
              '';
            in
            ''
              set -g @powerkit_plugins "${powerkitPlugins}"
            set -g @powerkit_plugin_datetime_format "%b %d %H:%M"
            ${powerkitGpuConfig}
            set -g @powerkit_plugin_netspeed_interface "auto"
            set -g @powerkit_plugin_netspeed_format "both"
            set -g @powerkit_theme "custom"
            set -g @powerkit_theme_variant "night-flat"
            set -g @powerkit_custom_theme_path "${tmuxPowerkitOneDarkProNightFlat}"
            set -g @powerkit_separator_style "none"
            set -g @powerkit_edge_separator_style "none"
            set -g @powerkit_initial_separator_style "none"
            set -g @powerkit_elements_spacing "false"
            set -g @powerkit_status_interval "5"
            set -g @powerkit_transparent "true"
          '';
        }
      ];
      extraConfig = ''
        set -g status-interval 5
        set -g base-index 1
        set -g pane-base-index 1
        set -g renumber-windows on
        set -g default-command "exec ${pkgs.zsh}/bin/zsh"
        set -g set-clipboard on
        set -g copy-command "${clipboardCommand}"

        source-file ${pkgs.tmuxPlugins.tmux-which-key}/share/tmux-plugins/tmux-which-key/plugin/init.example.tmux
        unbind-key -q -T prefix Space
        bind-key -T root C-Space show-wk-menu-root
        set -g @wk_menu_root \
          'Detach "d" detach-client \
          "Kill pane" "x" "confirm-before -p \"Kill pane #P? (y/n)\" kill-pane" \
          "" \
          Run "space" command-prompt \
          "Last window" "tab" last-window \
          "Last pane" "`" last-pane \
          Copy "c" "show-wk-menu #{@wk_menu_copy}" \
          "" \
          "+Windows" "w" "show-wk-menu #{@wk_menu_windows}" \
          "+Panes" "p" "show-wk-menu #{@wk_menu_panes}" \
          "+Buffers" "b" "show-wk-menu #{@wk_menu_buffers}" \
          "+Sessions" "s" "show-wk-menu #{@wk_menu_sessions}" \
          "+Client" "C" "show-wk-menu #{@wk_menu_client}" \
          "" \
          Time "T" clock-mode \
          "Show messages" "\~" show-messages \
          "+Keys" "?" "list-keys -N"'

        bind-key -T copy-mode MouseDragEnd1Pane send-keys -X copy-pipe-no-clear
        bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-no-clear

        unbind-key -q -T root MouseDown3Pane
        unbind-key -q -T root MouseDown3Status
        unbind-key -q -T root MouseDown3StatusLeft
        bind-key -T root MouseUp3Pane display-menu -T "#[align=centre]#{pane_index} (#{pane_id})" -t = -x M -y M \
          "Copy word" c "copy-mode -q ; set-buffer '#{q:mouse_word}'" \
          "Copy line" l "copy-mode -q ; set-buffer '#{q:mouse_line}'" \
          "" \
          "Horizontal split" h "split-window -h" \
          "Vertical split" v "split-window -v" \
          "Zoom" z "resize-pane -Z" \
          "Kill pane" X "kill-pane"
        bind-key -T root MouseUp3Status display-menu -T "#[align=centre]#{window_index}:#{window_name}" -t = -x W -y W \
          "New window" w "new-window" \
          "Rename window" n "command-prompt -F -I '#W' 'rename-window -t \"#{window_id}\" -- \"%%\"'" \
          "Kill window" X "kill-window"
        bind-key -T root MouseUp3StatusLeft display-menu -T "#[align=centre]#{session_name}" -t = -x M -y W \
          "Next session" n "switch-client -n" \
          "Previous session" p "switch-client -p" \
          "Rename session" r "command-prompt -I '#S' 'rename-session -- \"%%\"'" \
          "New session" s "new-session"

        # Interactive pane picker.
        bind-key -T prefix P displayp -d 0
        bind-key -T root C-Tab displayp -d 0
      '';
    };

  home.activation.reloadTmuxConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if command -v tmux >/dev/null 2>&1 && tmux info >/dev/null 2>&1; then
      run tmux source-file "$HOME/.config/tmux/tmux.conf"
    fi
  '';

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
    copilot-language-server
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
