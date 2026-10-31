-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  -- Diffview for side-by-side git diffs (like VSCode)
  {
    'sindrets/diffview.nvim',
    dependencies = 'nvim-lua/plenary.nvim',
    lazy = false, -- Load immediately, not lazy
    keys = {
      { '<leader>gd', '<cmd>DiffviewOpen<cr>', desc = '[G]it [D]iff View' },
      { '<leader>gh', '<cmd>DiffviewFileHistory %<cr>', desc = '[G]it File [H]istory' },
      { '<leader>gc', '<cmd>DiffviewClose<cr>', desc = '[G]it Diff [C]lose' },
    },
    opts = {
      enhanced_diff_hl = true,
      view = {
        merge_tool = {
          layout = 'diff3_mixed',
        },
      },
    },
  },
}
