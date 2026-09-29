{
  config,
  pkgs,
  ...
}:

let
  user = "ReoHakase";
  nixCasks = [ ];
in
{
  imports = [ ./common.nix ];

  home.username = user;
  home.homeDirectory = "/Users/${user}";

  home.sessionPath = [
    "/etc/profiles/per-user/${user}/bin"
    "/nix/var/nix/profiles/default/bin"
    "${config.home.homeDirectory}/.local/bin"
    # bun install -g（例: kanna-code）— mise 利用時は ~/.cache/.bun/bin になることがある
    "${config.home.homeDirectory}/.cache/.bun/bin"
    "${config.home.homeDirectory}/.cache/lm-studio/bin"
    "${config.home.homeDirectory}/.antigravity/antigravity/bin"
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
  ];

  xdg.configFile = {
    "karabiner/karabiner.json".source = ../config/karabiner/karabiner.json;
    "karabiner/assets".source = ../config/karabiner/assets;
  };

  home.packages = nixCasks ++ [
    (pkgs.writeShellApplication {
      name = "orca-kcvl-tunnel";
      runtimeInputs = [
        pkgs.gawk
        pkgs.coreutils
      ];
      text = ''
        # Resolve the existing kcvl target, including Match/ProxyJump, but omit
        # unrelated forwards. A separate connection owns only this tunnel.
        # OpenSSH closes process-substitution descriptors before reading -F.
        ssh_config=$(mktemp "''${TMPDIR:-/tmp}/orca-kcvl.XXXXXX")
        trap 'rm -f "$ssh_config"' EXIT
        /usr/bin/ssh -G kcvl | awk '
          $1 !~ /^(localforward|remoteforward|dynamicforward)$/
        ' > "$ssh_config"
        /usr/bin/ssh -F "$ssh_config" -S none -o ControlMaster=no -o ExitOnForwardFailure=yes \
          -N -T -L 127.0.0.1:16768:127.0.0.1:6768 kcvl
      '';
    })
  ];
}
