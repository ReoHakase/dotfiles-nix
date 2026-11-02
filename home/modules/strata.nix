{
  config,
  lib,
  pkgs,
  ...
}:

let
  release = import ../../pkgs/strata.nix { inherit pkgs; };
  client =
    operation:
    pkgs.writeShellApplication {
      name = "qwen-${operation}";
      runtimeInputs = [
        pkgs.openssh
        pkgs.aichat
        pkgs.opencode
      ];
      text = ''
        export STRATA_DESKTOP_APP=${lib.escapeShellArg "${release.desktop}/Applications/Strata.app"}
        exec ${lib.getExe pkgs.python3} ${../../scripts/qwen.py} ${operation} "$@"
      '';
    };
  setup = pkgs.writeShellApplication {
    name = "strata-qwen-setup";
    runtimeInputs = [
      pkgs.curl
      pkgs.coreutils
      pkgs.python3
    ];
    text = ''
      export STRATA_FEED=${lib.escapeShellArg release.feed}
      export STRATA_INSTALLER=${release.installer}
      export STRATA_VECTOR=${release.vector}
      ${builtins.readFile ../../scripts/setup-strata.sh}
    '';
  };
in
lib.mkMerge [
  (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    home.packages = [
      release.desktop
    ]
    ++ map client [
      "start"
      "stop"
      "chat"
      "code"
      "desktop"
    ];
  })
  (lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    home.packages = [ setup ];
    # No WantedBy: loading a 125B model is an explicit, on-demand operation.
    systemd.user.services.strata-qwen = {
      Unit.Description = "Qwen3.8-Flash-Next via the official Strata engine";
      Service = {
        ExecStart = "${config.home.homeDirectory}/.local/bin/strata serve --profile launch-kcvl-qwen --host 127.0.0.1 --port 8080 --parallel 1";
        UMask = "0077";
        KillMode = "control-group";
        TimeoutStopSec = 60;
      };
    };
  })
]
