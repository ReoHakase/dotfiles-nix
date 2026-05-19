{ pkgs, ... }:
{
  # LuaLaTeX + 日本語（luatexja / ltjsbook）。macOS の BasicTeX は使わず Nix に統一。
  home.file.".latexmkrc".source = ../../config/latex/latexmkrc;

  home.packages = [
    (pkgs.texliveSmall.withPackages (
      ps: with ps; [
        collection-langjapanese
        latexmk
        biber
      ]
    ))
  ];
}
