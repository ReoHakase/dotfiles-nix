{ inputs, pkgs, ... }:

let
  inherit (pkgs.stdenv.hostPlatform) system;
  gitBranchlessWithCompletions = pkgs.symlinkJoin {
    name = "${pkgs.git-branchless.name}-with-zsh-completion";
    paths = [ pkgs.git-branchless ];
    postBuild = ''
      install -Dm444 ${../../config/zsh/completions/_git-branchless} \
        "$out/share/zsh/site-functions/_git-branchless"
    '';
  };
  llmAgentsPkgs = inputs.llm-agents.packages.${system};
in
{
  home.packages = with pkgs; [
    geist-font
    harano-aji-fonts
    nerd-fonts.geist-mono
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif

    actrun
    bat
    bottom
    brotli
    cloc
    commitlint-rs
    copilot-language-server
    dotenvx
    entr
    lefthook
    llmAgentsPkgs.claude-code
    llmAgentsPkgs.codex
    dnsutils
    exiftool
    eza
    fastfetch
    fd
    ffmpeg
    fzf
    gcc
    gettext
    gh
    git
    gitBranchlessWithCompletions
    gnupg
    graphviz
    hyperfine
    inetutils
    lazygit
    lazyssh
    imagemagick
    libwebp
    libtiff
    lzo
    lz4
    # Markdown LSP (PKM). aerial.nvim の treesitter backend は nvim 0.12 の
    # Query:iter_matches API 変更（`all = false` 削除）で Markdown を開くと
    # クラッシュする。LSP が attach すれば aerial は LSP backend を使うので
    # その経路を経由しなくなる。ついでに wikilink / backlink / todo 補完が効く。
    markdown-oxide
    mise
    nixd
    nixfmt
    nmap
    openssl
    p7zip
    pkgconf
    ripgrep
    supabase-cli
    termsvg
    turso-cli
    # Official https://get.tur.so/install.sh also drops libsql's sqld next to turso (~/.turso).
    # nixpkgs turso-cli is CLI-only; nixpkgs sqld supplies the local server binary.
    sqld
    tree-sitter
    typst
    uv
    vips
    wget
    yazi
    xz
    zstd
  ];
}
