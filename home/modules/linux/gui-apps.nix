{ pkgs, ... }:
{
  # Electron（Cursor / VS Code 系の nixpkgs ラッパー）: NIXOS_OZONE_WL と WAYLAND_DISPLAY の両方があるときだけ
  # Ozone/Wayland 向けフラグが付く（nixpkgs vscode generic.nix）。
  # GNOME + Mutter on X11 では通常 WAYLAND_DISPLAY が無いのでこの分岐は効かず、普段は X11 経路。Wayland セッションに
  # 切り替えたとき用に NIXOS_OZONE_WL だけ先に立てておく（X11 のみでも害はない）。
  home.sessionVariables.NIXOS_OZONE_WL = "1";

  home.packages = with pkgs; [
    ghostty
    cursor-appimage
    proton-vpn
    veracrypt
    vicinae-appimage
  ];
}
