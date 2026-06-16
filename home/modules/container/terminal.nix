{
  config,
  lib,
  pkgs,
  ...
}:
let
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
  xdg.configFile."tmux/osc52-tmux-copy" = {
    text = osc52TmuxCopy;
    executable = true;
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
      clipboardCommand = osc52TmuxCopyPath;
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
        set -g status-style "bg=default,fg=#9da5b4"
        set -g window-status-current-style "bg=#23272e,fg=#d7dae0,bold"
        set -g pane-active-border-style "fg=#4aa5f0"

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
