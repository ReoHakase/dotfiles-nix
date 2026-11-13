{
  config,
  pkgs,
  ...
}:

let
  user = "ReoHakase";
  nixCasks = [ pkgs.openscreen ];
in
{
  imports = [
    ./common.nix
    ./modules/strata.nix
  ];

  home.username = user;
  home.homeDirectory = "/Users/${user}";

  programs.java = {
    enable = true;
    package = pkgs.jdk17;
  };

  # SDK 本体と AVD は Android Studio の SDK / Device Manager で管理する。
  home.sessionVariables.ANDROID_HOME = "${config.home.homeDirectory}/Library/Android/sdk";

  home.sessionPath = [
    "/etc/profiles/per-user/${user}/bin"
    "/nix/var/nix/profiles/default/bin"
    "${config.home.homeDirectory}/.local/bin"
    # bun install -g（例: kanna-code）— mise 利用時は ~/.cache/.bun/bin になることがある
    "${config.home.homeDirectory}/.cache/.bun/bin"
    "${config.home.homeDirectory}/.cache/lm-studio/bin"
    "${config.home.homeDirectory}/.antigravity/antigravity/bin"
    "${config.home.sessionVariables.ANDROID_HOME}/platform-tools"
    "${config.home.sessionVariables.ANDROID_HOME}/emulator"
    "${config.home.sessionVariables.ANDROID_HOME}/cmdline-tools/latest/bin"
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
  ];

  xdg.configFile = {
    "karabiner/karabiner.json".source = ../config/karabiner/karabiner.json;
    "karabiner/assets".source = ../config/karabiner/assets;
    "macos/cloudflare-dns.mobileconfig".source = ../config/macos/cloudflare-dns.mobileconfig;
  };

  home.packages = nixCasks;
}
