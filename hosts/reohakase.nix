# Host: reohakase (scutil --get LocalHostName / hostname -s)
{ pkgs, user, inputs, ... }:
{
  nixpkgs.hostPlatform = "aarch64-darwin";

  nixpkgs.config = {
    allowUnfree = true;
  };

  # Determinate Nix は独自デーモンでインストールを管理するため、nix-darwin の Nix 管理と両立しない。
  # `nix.enable = false` にしないと activation が中止される（「Determinate detected, aborting activation」）。
  # flakes や trusted-users は Determinate / 手元の `/etc/nix/nix.conf` 側で調整する。
  nix.enable = false;

  system.stateVersion = 5;

  # Required for system.defaults.* (activation runs as root)
  system.primaryUser = user;

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
  home-manager.extraSpecialArgs = { inherit inputs; };
  # 既存の ~/.zshrc や ~/.config/gh/config.yml などと HM が衝突するとき、拡張子付きで退避してからリンクする
  home-manager.backupFileExtension = "hm-backup";
  home-manager.users.${user} = import ../home;

  # Optional: keep Homebrew only for casks / oddballs — uncomment and list casks
  # homebrew = {
  #   enable = true;
  #   onActivation.cleanup = "zap";
  #   casks = [ "karabiner-elements" "orbstack" ];
  # };
}
