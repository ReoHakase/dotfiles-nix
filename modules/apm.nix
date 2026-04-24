{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.reohakase.apmGlobal;
  system = pkgs.stdenv.hostPlatform.system;
  llmAgentsPkgs = inputs.llm-agents.packages.${system};
  apm = pkgs.callPackage ../pkgs/apm-codex-user-scope.nix {
    inherit (llmAgentsPkgs) apm;
  };
in
{
  options.reohakase.apmGlobal = {
    enable = lib.mkEnableOption "global APM install during Home Manager activation";

    targets = lib.mkOption {
      type = lib.types.str;
      default = "claude,cursor,codex";
      description = "Comma-separated APM targets for global installation.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      apm
    ];

    home.file = {
      ".apm/apm.yml".source = ../config/apm/apm.yml;
    };

    home.activation.installGlobalApm =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        set -euo pipefail

        echo "APM: installing global agent dependencies from ~/.apm/apm.yml"
        ${lib.getExe apm} install -g --target ${lib.escapeShellArg cfg.targets}
      '';
  };
}
