-- aerial.nvim の treesitter backend は Markdown を開くと落ちる。
-- 原因は Neovim 0.12 の破壊的変更で `Query:iter_matches` から `all = false`
-- オプションが削除されたこと（neovim/neovim#33070, 2026-03-23 マージ）。
-- aerial 側はまだ `{ all = false }` を渡して単一ノードを前提としているため、
-- キャプチャごとに返るノードのリストを TSNode とみなして `:type()` を呼び、
-- extensions.lua:115 で nil メソッド呼び出しになる。aerial master も同じ
-- コードのままなので upstream 修正を待てない。
--
-- 本命の対策は plugins/astrolsp.lua で markdown-oxide LSP を登録すること。
-- LSP が attach すれば aerial は先に LSP backend を採用し、壊れた
-- treesitter 経路を踏まない。
--
-- ただし root_markers (.git / .obsidian / .moxide.toml) が無い孤立 md
-- ファイルでは LSP が attach しない。その場合 aerial の既定順は
-- lsp → treesitter → markdown なので、treesitter にフォールバックして
-- 再び落ちる。保険として markdown の backend 順序から treesitter を
-- 除外し、lsp が落ちたら非 treesitter の "markdown" backend に直接
-- フォールバックさせる。
---@type LazySpec
return {
  "stevearc/aerial.nvim",
  opts = {
    backends = {
      markdown = { "lsp", "markdown" },
    },
  },
}
