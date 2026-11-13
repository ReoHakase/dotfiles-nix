{
  lib,
  writeShellApplication,
  gh,
}:

writeShellApplication {
  name = "capsaicin-install";
  runtimeInputs = [ gh ];

  text = ''
    if (( $# > 1 )); then
      echo "Usage: capsaicin-install [release-tag]" >&2
      exit 1
    fi
    if [[ "''${1:-}" == --help || "''${1:-}" == -h ]]; then
      echo "Usage: capsaicin-install [release-tag]"
      echo "Download the latest release, or the specified tag, with gh release."
      exit 0
    fi

    if [[ "$(/usr/bin/uname -m)" != arm64 ]]; then
      echo "Capsaicin requires an Apple Silicon Mac." >&2
      exit 1
    fi

    macos_version=$(/usr/bin/sw_vers -productVersion)
    if (( ''${macos_version%%.*} < 26 )); then
      echo "Capsaicin requires macOS 26 or later." >&2
      exit 1
    fi

    destination="$HOME/Applications/Capsaicin.app"
    if [[ -e "$destination" || -L "$destination" ]]; then
      echo "Quit Capsaicin and move $destination aside before reinstalling." >&2
      exit 1
    fi

    download_dir=$(/usr/bin/mktemp -d -t capsaicin-download)
    trap '/bin/rm -r "$download_dir"' EXIT
    gh release download "$@" --repo koutyuke/Capsaicin \
      --pattern 'Capsaicin-*.zip' --pattern SHA256SUMS.txt --dir "$download_dir"
    cd "$download_dir"

    shopt -s nullglob
    archives=(Capsaicin-*.zip)
    if (( ''${#archives[@]} != 1 )); then
      echo "Expected exactly one Capsaicin release archive." >&2
      exit 1
    fi
    /usr/bin/shasum -a 256 -c SHA256SUMS.txt
    gh attestation verify "''${archives[0]}" --repo koutyuke/Capsaicin
    /usr/bin/ditto -x -k "''${archives[0]}" "$download_dir/unpacked"
    app="$download_dir/unpacked/Capsaicin.app"
    /usr/bin/codesign --verify --deep --strict "$app"
    /bin/mkdir -p "$HOME/Applications"
    /usr/bin/ditto "$app" "$destination"

    echo "Installed $destination"
    echo "Before opening it, completely quit other keep-awake apps and disable Karabiner's Manipulate caps lock LED for each keyboard."
  '';

  meta = {
    description = "Download and install Capsaicin using GitHub CLI releases";
    homepage = "https://github.com/koutyuke/Capsaicin";
    license = lib.licenses.mit;
    platforms = [ "aarch64-darwin" ];
  };
}
