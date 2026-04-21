# npm 由来 CLI を in-tree で管理するオーバーレイ。nixpkgs の追従遅延を避け、
# `buildNpmPackage` / 上流の prebuilt tarball を用いて最新に pin する。
# bump 手順は `pkgs/npm/README.md`。
final: _prev: {
  claude-code = final.callPackage ./claude-code/package.nix { };
  codex = final.callPackage ./codex/package.nix { };
}
