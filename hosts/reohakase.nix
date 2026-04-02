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

  # Homebrew: 手元の `brew tap` / `brew list` を 2026-04 にスナップショット。以後はここを正とする。
  # `zap` は使わず `uninstall` のみ（ブラウザ等のユーザデータを強掃除しない）。追加・削除はこのリストを編集してから switch。
  homebrew = {
    enable = true;
    onActivation.cleanup = "uninstall";
    taps = [
      "anomalyco/tap"
      "f/mcptools"
      "homebrew/services"
      "koekeishiya/formulae"
      "olets/tap"
      "satococoa/tap"
      "supabase/tap"
      "theboredteam/boring-notch"
      "tw93/tap"
    ];
    brews = [
      "aom"
      "bind"
      "brotli"
      "ca-certificates"
      "cairo"
      "dav1d"
      "fontconfig"
      "freetype"
      "gcc"
      "gettext"
      "giflib"
      "glib"
      "gmp"
      "graphite2"
      "guetzli"
      "harfbuzz"
      "highway"
      "icu4c@77"
      "imath"
      "isl"
      "jemalloc"
      "jpeg-turbo"
      "jpeg-xl"
      "json-c"
      "libassuan@2"
      "libavif"
      "libdeflate"
      "libgpg-error"
      "libiconv"
      "libidn2"
      "libmpc"
      "libnghttp2"
      "libpng"
      "libtiff"
      "libtommath"
      "libunistring"
      "libuv"
      "libvmaf"
      "libx11"
      "libxau"
      "libxcb"
      "libxdmcp"
      "libxext"
      "libxrender"
      "little-cms2"
      "lz4"
      "lzo"
      "mpfr"
      "openblas"
      "opencode"
      "openexr"
      "openjdk"
      "openjph"
      "openssl@3"
      "pcre2"
      "pinentry-mac"
      "pixman"
      "pkgconf"
      "r"
      "readline"
      "tcl-tk"
      "telnet"
      "userspace-rcu"
      "wtp"
      "xorgproto"
      "xz"
      "zstd"
    ];
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
