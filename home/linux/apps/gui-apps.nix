{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ghostty
    cursor-appimage
    vicinae-appimage
  ];
}
