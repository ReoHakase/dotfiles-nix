{
  lib,
  fetchFromGitHub,
  writeShellApplication,
  just,
  xcodegen,
}:

let
  source = fetchFromGitHub {
    owner = "koutyuke";
    repo = "Capsaicin";
    rev = "8719cbf73da5a289df81e1aa2ef7a9b119e61ece";
    hash = "sha256-8IfnCMyhDAYxKrQFkwV6JKaXJzPd3n9Jmo/JMxEjDmM=";
  };
in
writeShellApplication {
  name = "capsaicin-install";
  runtimeInputs = [
    just
    xcodegen
  ];

  # Xcode and signing use the host, outside the Nix build sandbox.
  text = ''
    if [[ "$(/usr/bin/uname -m)" != arm64 ]]; then
      echo "Capsaicin requires an Apple Silicon Mac." >&2
      exit 1
    fi

    macos_version=$(/usr/bin/sw_vers -productVersion)
    if (( ''${macos_version%%.*} < 26 )); then
      echo "Capsaicin requires macOS 26 or later." >&2
      exit 1
    fi

    xcode_version=$(/usr/bin/xcodebuild -version | /usr/bin/awk 'NR == 1 { print $2 }')
    IFS=. read -r xcode_major xcode_minor _ <<< "$xcode_version"
    if (( xcode_major < 27 || (xcode_major == 27 && ''${xcode_minor:-0} < 2) )); then
      echo "Capsaicin requires Xcode 27.2 or later (found $xcode_version)." >&2
      exit 1
    fi

    destination="$HOME/Applications/Capsaicin.app"
    if [[ -e "$destination" || -L "$destination" ]]; then
      echo "Quit Capsaicin and move $destination aside before reinstalling." >&2
      exit 1
    fi

    build_dir=$(/usr/bin/mktemp -d -t capsaicin-build)
    trap '/bin/rm -rf "$build_dir"' EXIT
    /bin/cp -R ${source}/. "$build_dir/"
    /bin/chmod -R u+w "$build_dir"
    cd "$build_dir"

    just build-release
    app="$build_dir/.build/xcode/Build/Products/Release/Capsaicin.app"
    /usr/bin/codesign --verify --deep --strict "$app"
    /bin/mkdir -p "$HOME/Applications"
    /usr/bin/ditto "$app" "$destination"

    echo "Installed $destination"
    echo "Before opening it, completely quit other keep-awake apps and disable Karabiner's Manipulate caps lock LED for each keyboard."
  '';

  meta = {
    description = "Build and install Capsaicin from pinned source using host Xcode";
    homepage = "https://github.com/koutyuke/Capsaicin";
    license = lib.licenses.mit;
    platforms = [ "aarch64-darwin" ];
  };
}
