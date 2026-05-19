{
  config,
  pkgs,
  lib,
  ...
}:

let
  user = "reohakuta";
in
{
  imports = [
    ./common.nix
    ./modules/linux/gui-apps.nix
    ./modules/linux/tailscale.nix
  ];

  home.username = user;
  home.homeDirectory = "/home/${user}";

  # Standalone Home Manager でも nix-darwin 側の backupFileExtension と同じ退避名にする。
  home.activation.setHomeManagerBackupExtension = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    export HOME_MANAGER_BACKUP_EXT=hm-backup
  '';

  home.sessionVariables.PYTHONNOUSERSITE = "1";

  home.sessionPath = [
    "${config.home.homeDirectory}/.nix-profile/bin"
    "/nix/var/nix/profiles/default/bin"
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/.cache/lm-studio/bin"
    "${config.home.homeDirectory}/.antigravity/antigravity/bin"
  ];

  # Apptainer + GPU の前提・`uv` とコンテナの役割分けは MANUAL を参照
  programs.zsh.shellAliases = {
    apx-nv = "apptainer exec --nv";
  };

  home.packages = with pkgs; [
    sshfs
    # Neovim / nvim-treesitter / Lazy プラグインのビルド（make / CMake）
    gnumake
    cmake
    ninja
  ];
}
