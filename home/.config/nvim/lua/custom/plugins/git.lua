-- Git, VS Code style. Under <leader>g:
--   gg  Source Control screen (Neogit): staged / unstaged / untracked files, s stage, u unstage, x discard,
--       c commit, P push, p pull, b branches, l log, Tab shows a file's diff inline, ? all keys
--   gd  side-by-side diff of all changes, with the file tree on the left (Diffview; q closes it)
--   gh  history of this file (Diffview)      gl  commit graph of the repository (Neogit log)
--   gc  commit menu: c commits the staged changes (the message opens in a buffer: :wq commits, q cancels),
--       a amends the last commit, w rewords it
--   gb  switch branch (list with preview)
-- Changes in the margin, stage/reset single hunks, blame: gitsigns (<leader>h..., ]c / [c), see init.lua.
local close_diffview = { 'n', 'q', '<cmd>DiffviewClose<cr>', { desc = 'Close Diffview' } }

return {
  {
    'sindrets/diffview.nvim',
    dependencies = 'nvim-lua/plenary.nvim',
    cmd = { 'DiffviewOpen', 'DiffviewFileHistory', 'DiffviewClose' },
    keys = {
      { '<leader>gd', '<cmd>DiffviewOpen<cr>', desc = '[G]it [D]iff: all changes side by side' },
      { '<leader>gh', '<cmd>DiffviewFileHistory %<cr>', desc = '[G]it [H]istory of this file' },
    },
    opts = {
      enhanced_diff_hl = true,
      view = { merge_tool = { layout = 'diff3_mixed' } },
      keymaps = {
        view = { close_diffview },
        file_panel = { close_diffview },
        file_history_panel = { close_diffview },
      },
    },
  },
  {
    'NeogitOrg/neogit',
    dependencies = { 'nvim-lua/plenary.nvim', 'sindrets/diffview.nvim', 'nvim-telescope/telescope.nvim' },
    cmd = 'Neogit',
    keys = {
      { '<leader>gg', function() require('neogit').open() end, desc = '[G]it: Source Control screen' },
      { '<leader>gc', function() require('neogit').open { 'commit' } end, desc = '[G]it [C]ommit menu (then c)' },
      {
        '<leader>gl',
        function() require('neogit').action('log', 'log_current', { '--graph', '--decorate' })() end,
        desc = '[G]it [L]og: commit graph',
      },
      { '<leader>gb', function() require('telescope.builtin').git_branches() end, desc = '[G]it [B]ranches: switch' },
    },
    opts = {
      graph_style = 'unicode',
      integrations = { diffview = true, telescope = true },
    },
  },
}
