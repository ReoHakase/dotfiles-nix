{ inputs, pkgs, ... }:

let
  inherit (pkgs.stdenv.hostPlatform) system;
  llmAgentsPkgs = inputs.llm-agents.packages.${system};
in
{
  home.packages = [
    llmAgentsPkgs.codex
    pkgs.bat
    pkgs.bottom
    pkgs.cloc
    pkgs.cmake
    pkgs.eza
    pkgs.fd
    pkgs.gcc
    pkgs.gnumake
    pkgs.hyperfine
    pkgs.markdown-oxide
    pkgs.ninja
    pkgs.nixd
    pkgs.nixfmt
    pkgs.ripgrep
    pkgs.tree-sitter
  ];
}
