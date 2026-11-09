-- Reading Markdown in Neovim (docs, READMEs, ~/pombo/projects/nvim-tutorial):
-- render-markdown draws headings, tables, code blocks, checkboxes and "> [!TIP]" boxes in the buffer (the line
-- under the cursor shows the raw text, for editing). <leader>tm switches between rendered and raw.
-- Enter / gd on a link opens it, Enter on a "- [ ]" task ticks it: lua/custom/markdown_links.lua
-- Notes with screenshots: Super+Shift+S copies a screenshot, <leader>pi pastes it: img-clip saves it as a PNG in
-- ./assets next to the note and inserts the link; image.nvim (jupyter.lua) shows images inline in kitty.
return {
  {
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
  },
  {
    'HakonHarnes/img-clip.nvim',
    ft = { 'markdown' },
    -- p / P with a screenshot on the clipboard also paste it as an image in notes: lua/custom/paste.lua
    keys = {
      { '<leader>pi', '<cmd>PasteImage<cr>', desc = '[P]aste [I]mage from the clipboard', ft = 'markdown' },
    },
    opts = {
      default = {
        dir_path = 'assets', -- next to the note
        relative_to_current_file = true,
        prompt_for_file_name = false,
        file_name = '%Y-%m-%d_%H-%M-%S',
        extension = 'png',
      },
    },
  },
}
