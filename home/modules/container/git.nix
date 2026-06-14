{ pkgs, ... }:
{
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options.navigate = true;
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user = {
        name = "Reo Hakuta";
        email = "reonaldhkt@gmail.com";
      };
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
    };
  };

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
    hosts."github.com" = {
      git_protocol = "ssh";
      users.ReoHakase = null;
      user = "ReoHakase";
    };
  };
}
