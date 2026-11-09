-- p / P when the system clipboard holds only an image (a screenshot from Super+Shift+S):
--   in Markdown notes: paste it as an image, like <leader>pi (img-clip saves a PNG in ./assets and inserts the link)
--   anywhere else: say so, instead of pasting old text from Neovim's own registers
-- Text on the clipboard, or another register ("ap), is the normal paste. The clipboard itself only gives Neovim text
-- (vim.g.clipboard in init.lua), so a screenshot never turns into raw PNG bytes.
local M = {}

function M.clipboard_is_image()
  if not vim.env.WAYLAND_DISPLAY or (vim.v.register ~= '+' and vim.v.register ~= '"') then return false end
  local image, text = false, false
  for _, t in ipairs(vim.fn.systemlist { 'wl-paste', '--list-types' }) do
    if t:match '^image/' then image = true end
    if t:match '^text/plain' or t == 'UTF8_STRING' or t == 'STRING' or t == 'TEXT' then text = true end
  end
  return image and not text
end

function M.setup()
  for _, key in ipairs { 'p', 'P' } do
    vim.keymap.set('n', key, function()
      if not M.clipboard_is_image() then return key end
      if vim.bo.filetype == 'markdown' then return '<cmd>PasteImage<cr>' end
      vim.notify('The clipboard holds an image, not text (in a Markdown note, p pastes it as an image)', vim.log.levels.WARN)
      return ''
    end, { expr = true, desc = 'Paste (a screenshot: as an image in Markdown notes)' })
  end
end

return M
