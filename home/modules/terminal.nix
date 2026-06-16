{
  config,
  lib,
  pkgs,
  ...
}:

let
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
  tmuxPowerkit = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux-powerkit";
    version = "unstable-2026-01-12";
    src = pkgs.fetchFromGitHub {
      owner = "fabioluciano";
      repo = "tmux-powerkit";
      rev = "372b891e6c1884dd3b959f101336c92fa89056ec";
      hash = "sha256-rYDxaELzJNmn2+ndLBjhUSNZjwg8tf7lT4iwCAU4nfQ=";
    };
    rtpFilePath = "tmux-powerkit.tmux";
  };
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
  osc52TmuxCopyPath = "${config.xdg.configHome}/tmux/osc52-tmux-copy";
  osc52TmuxCopy = ''
    #!${pkgs.runtimeShell}
    set -eu

    tmp="$(${pkgs.coreutils}/bin/mktemp "''${TMPDIR:-/tmp}/osc52-tmux-copy.XXXXXX")"
    trap '${pkgs.coreutils}/bin/rm -f -- "$tmp"' EXIT
    ${pkgs.coreutils}/bin/cat > "$tmp"

    encoded="$(${pkgs.coreutils}/bin/base64 -w 0 < "$tmp")"
    if [ -n "''${TMUX-}" ]; then
      client_tty="$(${pkgs.tmux}/bin/tmux display-message -p '#{client_tty}' 2>/dev/null || true)"
      if [ -n "$client_tty" ] && [ -w "$client_tty" ]; then
        printf '\033]52;c;%s\a' "$encoded" > "$client_tty"
        exit 0
      fi
    fi

    printf '\033]52;c;%s\a' "$encoded"
  '';
in
{
  xdg.configFile = {
    "ghostty/config".source = ../../config/ghostty/config;
    "ghostty/shaders".source = ghosttyCursorShaders;
  }
  // lib.optionalAttrs (!pkgs.stdenv.isDarwin) {
    "tmux/osc52-tmux-copy" = {
      text = osc52TmuxCopy;
      executable = true;
    };
  };

  programs.lazygit = {
    enable = true;
    settings = {
      gui.nerdFontsVersion = "3";
      git = {
        allBranchesLogCmds = [
          "git log --graph --color=always --date=format:'%Y-%m-%d %H:%M' --pretty=format:'%C(240 reverse)%h%Creset %C(14)%ad%Creset %C(202)%an <%ae>%Creset %C(11 reverse)%d%Creset %n%C(15 bold)%s%Creset%n' --all --"
        ];
        branchLogCmd = "git log --graph --color=always --date=format:'%Y-%m-%d %H:%M' --pretty=format:'%C(240 reverse)%h%Creset %C(14)%ad%Creset %C(202)%an <%ae>%Creset %C(11 reverse)%d%Creset %n%C(15 bold)%s%Creset%n' {{branchName}} --";
        pagers = [
          {
            pager = "delta --dark --paging=never";
            colorArg = "always";
          }
        ];
      };
    };
  };

  programs.tmux =
    let
      clipboardCommand = if pkgs.stdenv.isDarwin then "/usr/bin/pbcopy" else osc52TmuxCopyPath;
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
        set -g set-clipboard external
        set -as terminal-features ',xterm-256color:clipboard,tmux-256color:clipboard,screen-256color:clipboard'
        set -g copy-command "${clipboardCommand}"
        set -g mode-style "bg=#677696,fg=#d7dae0"

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
          "Copy word" c "copy-mode -q ; set-buffer -w '#{q:mouse_word}'" \
          "Copy line" l "copy-mode -q ; set-buffer -w '#{q:mouse_line}'" \
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
}
