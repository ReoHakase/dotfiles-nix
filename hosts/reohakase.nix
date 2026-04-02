# Host: reohakase (scutil --get LocalHostName / hostname -s)
{ pkgs, user, inputs, ... }:
{
  # nix-homebrew: brew を Nix 管理にし、`/run/current-system/sw/bin/brew` 系のランチャと連携（既存 /opt/homebrew は autoMigrate）
  nix-homebrew = {
    enable = true;
    user = user;
    autoMigrate = true;
  };

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

  # nix を正とする手順: まず `cleanup = "check"` で activation を試し、列挙された「余分な」brew を
  # すべて `brews` / `casks` に追記する。一致したら `cleanup = "uninstall"` へ。
  # ブラウザ等のユーザデータを強く掃除したくないなら `zap` は使わない（MANUAL 参照）。
  homebrew = {
    enable = true;
    onActivation.cleanup = "check";
    taps = [ "satococoa/tap" ];
    brews = [ "wtp" ];
  };
}
