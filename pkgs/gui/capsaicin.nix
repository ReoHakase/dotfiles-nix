{
  lib,
  writeShellApplication,
  gh,
}:

writeShellApplication {
  name = "capsaicin-install";
  runtimeInputs = [ gh ];

  text = ''
    if [[ "''${1:-}" == --help || "''${1:-}" == -h ]]; then
      echo "Usage: capsaicin-install [release-tag]"
      echo "Download the latest release, or the specified tag, with gh release."
      exit 0
    fi

    destination="$HOME/Applications/Capsaicin.app"
    if [[ -e "$destination" || -L "$destination" ]]; then
      echo "Quit Capsaicin and move $destination aside before reinstalling." >&2
      exit 1
    fi

    download_dir=$(/usr/bin/mktemp -d -t capsaicin-download)
    trap '/bin/rm -r "$download_dir"' EXIT
    gh release download "$@" --repo koutyuke/Capsaicin \
      --pattern 'Capsaicin-*.zip' --output "$download_dir/Capsaicin.zip"
    gh attestation verify "$download_dir/Capsaicin.zip" --repo koutyuke/Capsaicin
    /usr/bin/ditto -x -k "$download_dir/Capsaicin.zip" "$download_dir/unpacked"
    app="$download_dir/unpacked/Capsaicin.app"
    /usr/bin/codesign --verify --deep --strict "$app"
    /bin/mkdir -p "$HOME/Applications"
    /usr/bin/ditto "$app" "$destination"

    echo "Installed $destination"
  '';

  meta = {
    description = "Download and install Capsaicin using GitHub CLI releases";
    homepage = "https://github.com/koutyuke/Capsaicin";
    license = lib.licenses.mit;
    platforms = [ "aarch64-darwin" ];
  };
}
