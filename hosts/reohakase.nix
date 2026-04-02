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

  # macOS システム設定（`defaults read` に基づく。変更後は `apply-system.sh` で反映）
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      AppleShowAllExtensions = true;
      NSAutomaticWindowAnimationsEnabled = false;
      # Finder サイドバーアイコン: 1=小 / 2=中 / 3=大（現在の手元は 2）
      NSTableViewDefaultSizeMode = 2;
      # 「自然なスクロール」がオフ = 従来型（コンテンツではなくスクロールバー基準。いわゆる「逆」にした状態）
      "com.apple.swipescrolldirection" = false;
      # トラックパッドの強めクリック（Force Click）
      "com.apple.trackpad.forceClick" = true;
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

    # `defaults read com.apple.AppleMultitouchTrackpad` 相当（内蔵／Bluetooth トラックパッドの既定に合わせる）
    trackpad = {
      ActuateDetents = true;
      Clicking = true;
      Dragging = false;
      DragLock = false;
      FirstClickThreshold = 1;
      SecondClickThreshold = 1;
      TrackpadCornerSecondaryClick = 0;
      TrackpadFourFingerHorizSwipeGesture = 2;
      TrackpadFourFingerPinchGesture = 2;
      TrackpadFourFingerVertSwipeGesture = 2;
      TrackpadMomentumScroll = true;
      TrackpadPinch = true;
      TrackpadRightClick = true;
      TrackpadRotate = true;
      TrackpadThreeFingerDrag = false;
      TrackpadThreeFingerHorizSwipeGesture = 2;
      TrackpadThreeFingerTapGesture = 0;
      TrackpadThreeFingerVertSwipeGesture = 2;
      TrackpadTwoFingerDoubleTapGesture = true;
      TrackpadTwoFingerFromRightEdgeSwipeGesture = 3;
    };
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = { inherit inputs; };
  # 既存の ~/.zshrc や ~/.config/gh/config.yml などと HM が衝突するとき、拡張子付きで退避してからリンクする
  home-manager.backupFileExtension = "hm-backup";
  home-manager.users.${user} = import ../home;

  # Homebrew: cask のみ（formula / tap は空）。CLI は home/default.nix の nixpkgs。`wtp` / brew の `opencode` は使わない。
  homebrew = {
    enable = true;
    onActivation.cleanup = "uninstall";
    taps = [ ];
    brews = [ ];
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
