-- kdheepak/lazygit.nvim — Neovim から lazygit を floating window で起動する。
-- lazygit 本体は home/common.nix の home.packages で入れている。
--
-- コマンド/キーで lazy-load するので起動コストはかからない。plenary.nvim は
-- AstroNvim が既に依存として入れているが、単独運用でも成り立つよう明示する。
--
-- キーマップ: `<Leader>gg` = LazyGit (current cwd) / `<Leader>gG` =
-- LazyGit (current file's repo)。AstroNvim の `<Leader>g` は Git プレフィクス
-- なのでその直下に置く。
---@type LazySpec
return {
  "kdheepak/lazygit.nvim",
  cmd = {
    "LazyGit",
    "LazyGitConfig",
    "LazyGitCurrentFile",
    "LazyGitFilter",
    "LazyGitFilterCurrentFile",
  },
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    { "<Leader>gg", "<Cmd>LazyGit<CR>", desc = "LazyGit (cwd)" },
    { "<Leader>gG", "<Cmd>LazyGitCurrentFile<CR>", desc = "LazyGit (current file repo)" },
  },
}
