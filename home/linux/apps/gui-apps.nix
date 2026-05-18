{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ghostty
    cursor-appimage
    proton-vpn
    veracrypt
    vicinae-appimage
  ];
}
