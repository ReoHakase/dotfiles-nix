{
  lib,
  pkgs,
  ...
}:

let
  pinentryPackage = if pkgs.stdenv.isDarwin then pkgs.pinentry_mac else pkgs.pinentry-gtk2;
in
{
  # gpg-agent.conf は Nix が入れた pinentry の絶対パスを指す。
  # home-manager が書き換えるので手編集しない。反映には `gpgconf --kill gpg-agent` が必要。
  home.file.".gnupg/gpg-agent.conf".text = ''
    pinentry-program ${lib.getExe pinentryPackage}
  '';

  home.packages = [ pinentryPackage ];
}
