-- aerial.nvim の treesitter バックエンドは Markdown で落ちる（線 115 の
-- extensions.lua で `level_node:type()` が nil メソッドになる）。
-- 原因: Neovim 0.11+ の `query:iter_matches` は `{ all = false }` を渡しても
-- キャプチャごとに「ノードのリスト」を返すことがあり、aerial 側は単一の
-- TSNode を想定して `.node` をそのまま使うため、`match.level.node` が
-- テーブルになって `:type()` 呼び出しが失敗する。upstream master も
-- 同じコードのままなので修正版を待てない。
--
-- Markdown 専用の非 treesitter バックエンド（"markdown"）は見出しを自前で
-- パースするので影響を受けない。Markdown では lsp → markdown の順だけに
-- 切り詰めて treesitter を経由させない。
---@type LazySpec
return {
  "stevearc/aerial.nvim",
  opts = {
    backends = {
      markdown = { "lsp", "markdown" },
    },
  },
}
