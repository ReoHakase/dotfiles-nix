{
  config,
  lib,
  pkgs,
  ...
}:

let
  checkPort = pkgs.writeShellScript "orca-check-port" ''
    if [ -n "$(${pkgs.iproute2}/bin/ss -H -ltn 'sport = :6768')" ]; then
      echo "Orca port 6768 is already in use; refusing a fallback port." >&2
      exit 1
    fi
  '';
in
{
  home.packages = [ pkgs.orca-ide ];

  systemd.user.services.orca-serve = {
    Unit = {
      Description = "Orca headless agent runtime";
      StartLimitIntervalSec = 300;
      StartLimitBurst = 5;
    };
    Service = {
      Type = "simple";
      WorkingDirectory = config.home.homeDirectory;
      ExecStartPre = checkPort;
      ExecStart = "${lib.getExe pkgs.orca-ide} serve --port 6768 --pairing-address ws://127.0.0.1:16768 --json";
      Environment = [
        "LIBGL_ALWAYS_SOFTWARE=1"
        "PATH=${config.home.profileDirectory}/bin:${config.home.homeDirectory}/.local/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin"
      ];
      UnsetEnvironment = [
        "DISPLAY"
        "WAYLAND_DISPLAY"
        "NIXOS_OZONE_WL"
        "ELECTRON_RUN_AS_NODE"
      ];
      StandardOutput = "journal";
      StandardError = "journal";
      KillMode = "mixed";
      Restart = "on-failure";
      RestartPreventExitStatus = 3;
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
