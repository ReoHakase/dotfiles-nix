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

    packageRef = lib.mkOption {
      type = lib.types.str;
      default = "ReoHakase/dotfiles-nix";
      description = "APM package reference used for user-scope global installation.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      apm
    ];

    home.activation.installGlobalApm =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        set -euo pipefail

        echo "APM: installing global agent package ${cfg.packageRef}"
        ${lib.getExe apm} install -g ${lib.escapeShellArg cfg.packageRef} --target ${lib.escapeShellArg cfg.targets}
      '';
  };
}
