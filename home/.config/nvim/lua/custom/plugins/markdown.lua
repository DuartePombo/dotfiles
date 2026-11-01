-- Reading Markdown in Neovim (docs, READMEs, ~/projects/nvim-tutorial):
-- render-markdown draws headings, tables, code blocks, checkboxes and "> [!TIP]" boxes in the buffer (the line
-- under the cursor shows the raw text, for editing). <leader>tm switches between rendered and raw.
-- Enter / gd on a link opens it, Enter on a "- [ ]" task ticks it: lua/custom/markdown_links.lua
return {
  'MeanderingProgrammer/render-markdown.nvim',
  version = '*',
  ft = { 'markdown' },
  dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' },
  init = function()
    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('custom-markdown-links', { clear = true }),
      pattern = 'markdown',
      callback = function(ev) require('custom.markdown_links').attach(ev.buf) end,
    })
  end,
  keys = {
    { '<leader>tm', '<cmd>RenderMarkdown toggle<cr>', desc = '[T]oggle [M]arkdown rendering', ft = 'markdown' },
  },
  opts = {
    heading = { sign = false },
    code = { sign = false, width = 'block', min_width = 60, right_pad = 2 },
  },
}
