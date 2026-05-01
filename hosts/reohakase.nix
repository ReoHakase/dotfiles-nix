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

  nixpkgs.overlays = [
    inputs.actrun.overlays.default
  ];

  nixpkgs.config = {
    allowUnfree = true;
  };

  # Determinate Nix は独自デーモンでインストールを管理するため、nix-darwin の Nix 管理と両立しない。
  # `nix.enable = false` にしないと activation が中止される（「Determinate detected, aborting activation」）。
  # flakes や trusted-users は Determinate / 手元の `/etc/nix/nix.conf` 側で調整する。
  nix.enable = false;

  system.stateVersion = 5;

  # nix-darwin's local manual/options docs generation currently emits an
  # upstream string-context warning during evaluation. Disable only that
  # documentation bundle; `programs.man` / `programs.info` remain available.
  documentation.enable = false;

  # Required for system.defaults.* (activation runs as root)
  system.primaryUser = user;

  users.users.${user} = {
    name = user;
    home = "/Users/${user}";
    shell = pkgs.zsh;
  };

  environment.shells = [ pkgs.zsh ];

  programs.zsh.enable = true;

  # sudo に Touch ID（および設定済みなら Apple Watch）。`/etc/pam.d/sudo_local` を nix-darwin が管理。
  # reattach: tmux / screen 内でも pam_tid が効くようにする（pam-reattach）。
  security.pam.services.sudo_local.touchIdAuth = true;
  security.pam.services.sudo_local.reattach = true;

  # Tailscale: launchd で tailscaled、CLI は environment.systemPackages（HM の home.packages には足さない）
  services.tailscale.enable = true;

  # macOS 既定と同じ値は書かない（nix-darwin マニュアル各オプションの default / 説明文を参照）。
  # 変更後は `apply-system.sh`。手元の確認: `defaults read NSGlobalDomain|com.apple.finder|com.apple.dock|com.apple.screencapture …`
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      AppleShowAllExtensions = true;
      NSAutomaticWindowAnimationsEnabled = false;
      # 既定は 3（大）。手元は中サイズ。
      NSTableViewDefaultSizeMode = 2;
      # 既定は「自然なスクロール」オン。手元は従来型（オフ）。
      "com.apple.swipescrolldirection" = false;
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

    # 既定は file。手元はクリップボードへ保存。
    screencapture.target = "clipboard";
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = { inherit inputs; };
  # 既存の ~/.zshrc や ~/.config/gh/config.yml などと HM が衝突するとき、拡張子付きで退避してからリンクする
  home-manager.backupFileExtension = "hm-backup";
  home-manager.users.${user} = import ../home;

  # Homebrew: cask のみ（formula / tap は空）。CLI・フォントは home/darwin.nix（common）の nixpkgs。
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
      "ghostty"
      "glide"
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
      "windows-app"
      "wine-stable"
      "xquartz"
      "zoom"
    ];
  };
}
