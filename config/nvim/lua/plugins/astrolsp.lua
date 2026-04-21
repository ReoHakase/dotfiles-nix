-- markdown-oxide を AstroLSP に登録する。
-- バイナリ自体は home.packages に入れている（home/common.nix）。
--
-- nvim-lspconfig 同梱の `lsp/markdown_oxide.lua` に既定の
-- cmd = { "markdown-oxide" } / filetypes = { "markdown" } /
-- root_markers = { ".git", ".obsidian", ".moxide.toml" } が載っているので、
-- ここでは AstroLSP の `servers` にサーバ名だけ足して自動セットアップに
-- 任せる（設定上書きが必要になったら `config.markdown_oxide = { ... }` を
-- 追加する）。
--
-- これにより Markdown バッファでは aerial の既定順 { "lsp", "treesitter",
-- ... } の先頭である LSP backend が採用され、壊れた treesitter 経路は
-- 踏まなくなる。root_markers が見つからない孤立ファイルを開いた場合の
-- 保険として plugins/aerial.lua の backends 上書きも併用する。
---@type LazySpec
return {
  "AstroNvim/astrolsp",
  ---@type AstroLSPOpts
  opts = {
    servers = { "markdown_oxide" },
  },
}
