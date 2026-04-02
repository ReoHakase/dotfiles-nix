# Host: reohakase (scutil --get LocalHostName / hostname -s)
{
  pkgs,
  user,
  inputs,
  ...
}:
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

  # Homebrew: cask / tap 専用ツール。`brew bundle --cleanup`（uninstall）は wtp の依存（brew の git 等）と衝突するため `none`。
  # 手元の不要 formula は `brew autoremove` などで個別に整理する。
  homebrew = {
    enable = true;
    onActivation.cleanup = "none";
    # nixpkgs に無いもの・tap 公式のみ（CLI は home/default.nix の home.packages）
    taps = [ "satococoa/tap" ];
    brews = [ "wtp" ];
    casks = [
      "affinity"
      "alt-tab"
      "anki"
      "antigravity"
      "arc"
      "azookey"
      "basictex"
      "betterdisplay"
      "brave-browser"
      "calibre"
      "canva"
      "chatgpt"
      "cmd-eikana"
      "codex-app"
      "creality-print"
      "cursor"
      "discord"
      "dolphin"
      "figma"
      "font-geist"
      "font-geist-mono-nerd-font"
      "font-noto-sans-cjk-jp"
      "font-noto-serif-cjk-jp"
      "ghostty"
      "gstreamer-runtime"
      "imagej"
      "karabiner-elements"
      "keka"
      "lm-studio"
      "microsoft-excel"
      "microsoft-powerpoint"
      "microsoft-word"
      "mono-mdk-for-visual-studio"
      "morisawa-desktop-manager"
      "notion"
      "orbstack"
      "quicklook-video"
      "raycast"
      "rstudio"
      "scilab"
      "slack"
      "stats"
      "thebrowsercompany-dia"
      "tor-browser"
      "unity-hub"
      "visual-studio"
      "visual-studio-code"
      "vlc"
      "voiceink"
      "warp"
      "wine-stable"
      "xquartz"
      "zoom"
    ];
  };
}
