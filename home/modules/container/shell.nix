{
  config,
  lib,
  ...
}:
{
  programs.zsh = {
    enable = true;
    dotDir = config.home.homeDirectory;
    envExtra = ''
      typeset -U path PATH
      path=(
        "$HOME/.nix-profile/bin"
        /nix/var/nix/profiles/default/bin
        "$HOME/.local/bin"
        $path
      )
    '';
    initContent = lib.mkAfter ''
      if (( $+functions[compdef] )); then
        compdef _cd z
      fi
    '';
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
        gc = "git commit";
        ghi = "gh issue create";
        ghp = "gh pr create";
        ghw = "gh repo view -w";
        lg = "lazygit";
      };
    };
    shellAliases.ls = "eza";
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
    config.global.hide_env_diff = true;
  };

  programs.mise = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = builtins.fromTOML ''
      "$schema" = 'https://starship.rs/config-schema.json'

      add_newline = true

      format = """
      $username\
      $hostname\
      $directory\
      $git_branch\
      $git_commit\
      $custom\
      $git_status\
      $git_metrics\
      $line_break\
      $character\
      """

      right_format = """
      [\
      $docker_context\
      $container\
      ](bright-black)
      """

      [custom.git_worktree]
      command = """git rev-parse --git-dir | sed -E 's#/\\.git(/.*)?$##; s#.*/##'"""
      when = """git rev-parse --git-dir 2>/dev/null | grep -q 'worktrees'"""
      require_repo = true
      style = "green"
      format = "[worktree:$output]($style) "

      [git_branch]
      symbol = "git:"
      format = "on [$symbol$branch](bold bright-black) "
      truncation_length = 24

      [git_commit]
      commit_hash_length = 7
      only_detached = true
      tag_disabled = false
      tag_symbol = 'tag:'
      style = "italic bright-black"
      format = "[$hash$tag]($style) "

      [git_status]
      format = "([$ahead_behind$all_status]($style))"

      [git_metrics]
      disabled = true

      [container]
      format = '[container:$name](blue bold) '

      [directory]
      format = "in [$path](cyan italic) "

      [username]
      show_always = true
      style_user = "purple"
      style_root = "red"
      format = "[$user]($style) "
      aliases = { root = "root", vscode = "vscode" }

      [hostname]
      ssh_only = true
      format = "at [$hostname](green) "
    '';
  };

  programs.fzf.enable = true;

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
}
