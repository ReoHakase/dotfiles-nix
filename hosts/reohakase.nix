# Host: reohakase (scutil --get LocalHostName / hostname -s)
{ pkgs, user, ... }:
{
  nixpkgs.hostPlatform = "aarch64-darwin";

  nixpkgs.config = {
    allowUnfree = true;
  };

  nix = {
    settings = {
      experimental-features = "nix-command flakes";
      trusted-users = [ user ];
    };
    optimise.automatic = true;
  };

  system.stateVersion = 5;

  users.users.${user} = {
    name = user;
    home = "/Users/${user}";
    shell = pkgs.zsh;
  };

  environment.shells = [ pkgs.zsh ];

  programs.zsh.enable = true;

  # Declarative macOS defaults (extend as needed)
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      AppleShowAllExtensions = true;
      NSAutomaticWindowAnimationsEnabled = false;
    };
    finder = {
      AppleShowAllExtensions = true;
      FXEnableExtensionChangeWarning = false;
      QuitMenuItem = true;
    };
    dock = {
      autohide = true;
      mru-spaces = false;
      show-recents = false;
    };
    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
    };
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.${user} = import ../home;

  # Optional: keep Homebrew only for casks / oddballs — uncomment and list casks
  # homebrew = {
  #   enable = true;
  #   onActivation.cleanup = "zap";
  #   casks = [ "karabiner-elements" "orbstack" ];
  # };
}
