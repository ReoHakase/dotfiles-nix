{
  lib,
  pkgs,
  ...
}:

let
  lazysshMetadata = {
    paras.tags = [
      "96gb"
      "6000-ada-x2"
      "lab"
      "gpu"
    ];
    snorlax.tags = [
      "96gb"
      "6000-pro-blackwell-max-q"
      "lab"
      "gpu"
    ];
    squirtle.tags = [
      "48gb"
      "3090ti-x2"
      "lab"
      "gpu"
      "retiring-soon"
    ];
    nidoking.tags = [
      "128gb"
      "preparing"
      "lab"
    ];
    nidoqueen.tags = [
      "128gb"
      "preparing"
      "lab"
    ];
  };
  lazysshMetadataFile = pkgs.writeText "lazyssh-metadata.json" (builtins.toJSON lazysshMetadata);
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        ForwardAgent = false;
        AddKeysToAgent = "no";
        Compression = false;
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "no";
        SetEnv.TERM = "xterm-256color";
      };
      kcvl = {
        HostName = "192.168.100.149";
        User = "reohakuta";
        ProxyJump = "reoo.hakuta@gw.vision.is.kit.ac.jp";
      };
      # 96GB; RTX 6000 Ada x2
      "paras paras02 paras02.lan" = {
        HostName = "paras02.lan";
        User = "student";
        ProxyJump = "reoo.hakuta@gw.vision.is.kit.ac.jp";
      };
      # 96GB; RTX 6000 Pro Blackwell Max-Q
      "snorlax snorlax06 snorlax06.lan" = {
        HostName = "snorlax06.lan";
        User = "student";
        ProxyJump = "reoo.hakuta@gw.vision.is.kit.ac.jp";
      };
      # 48GB; RTX 3090 Ti x2; retiring soon
      "squirtle squirtle05 squirtle05.lan" = {
        HostName = "squirtle05.lan";
        User = "student";
        ProxyJump = "reoo.hakuta@gw.vision.is.kit.ac.jp";
      };
      # 128GB; preparing
      "nidoking nidoking07 nidoking07.lan" = {
        HostName = "nidoking07.lan";
        User = "student";
        ProxyJump = "reoo.hakuta@gw.vision.is.kit.ac.jp";
      };
      # 128GB; preparing
      "nidoqueen nidoqueen08 nidoqueen08.lan" = {
        HostName = "nidoqueen08.lan";
        User = "student";
        ProxyJump = "reoo.hakuta@gw.vision.is.kit.ac.jp";
      };
    };
  };

  home.activation.configureLazysshMetadata = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    set -euo pipefail

    metadata_path="$HOME/.lazyssh/metadata.json"
    metadata_dir="$(dirname "$metadata_path")"
    desired_metadata=${lib.escapeShellArg lazysshMetadataFile}

    run mkdir -p "$metadata_dir"
    run chmod 750 "$metadata_dir"

    if [ -L "$metadata_path" ]; then
      run rm -f "$metadata_path"
    fi

    if [ -s "$metadata_path" ]; then
      tmp_file="$(mktemp)"
      if ${lib.getExe pkgs.jq} -s '.[0] * .[1]' "$metadata_path" "$desired_metadata" > "$tmp_file"; then
        run install -m 600 "$tmp_file" "$metadata_path"
      else
        echo "LazySSH: replacing invalid metadata at $metadata_path"
        run install -m 600 "$desired_metadata" "$metadata_path"
      fi
      run rm -f "$tmp_file"
    else
      run install -m 600 "$desired_metadata" "$metadata_path"
    fi
  '';
}
