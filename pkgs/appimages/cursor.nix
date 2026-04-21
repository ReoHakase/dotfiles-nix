# Ubuntu（非 NixOS）では /nix/store 内の chrome-sandbox を root:root/4755 に
# できないため、Electron の SUID sandbox 前提で起動すると abort する。
# nixpkgs の code-cursor をそのまま使わず、symlinkJoin + makeWrapper で
# bin/cursor に --no-sandbox を注入したラッパーを公開する。
# トレードオフ: Chromium のサンドボックス保護は無効になる。
pkgs:
let
  base = pkgs."code-cursor";
in
pkgs.symlinkJoin {
  name = "cursor-nosandbox-${base.version or "wrapped"}";
  paths = [ base ];
  nativeBuildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    rm -f $out/bin/cursor
    makeWrapper ${base}/bin/cursor $out/bin/cursor \
      --add-flags "--no-sandbox"
  '';
  inherit (base) meta;
}
