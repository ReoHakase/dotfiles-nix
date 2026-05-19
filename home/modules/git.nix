{ pkgs, ... }:
{
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

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "https";
      editor = "";
      prompt = "enabled";
      pager = "";
      aliases.co = "pr checkout";
      http_unix_socket = "";
      browser = "";
      version = "1";
    };
    hosts = {
      "github.com" = {
        git_protocol = "ssh";
        users.ReoHakase = null;
        user = "ReoHakase";
      };
    };
  };
}
