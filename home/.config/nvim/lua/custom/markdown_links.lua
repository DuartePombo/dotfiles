-- Markdown as a little help system (used by ~/pombo/projects/nvim-tutorial, works in any .md file):
--   Enter (or gd) on a link   opens it: another file, a heading in it, or a web page; Ctrl+o comes back
--   Enter on a task "- [ ]"   ticks it ("- [x]") or unticks it; :w keeps the ticks
-- Link targets: path relative to this file (or ~/...), optional #anchor:
--   notes.md#some-heading   the heading "Some heading" (GitHub-style anchor)
--   run.lua#M.python        in a non-Markdown file: the first line containing "M.python"
--   main.c#L12              line 12
--   https://...             opens in the browser
local M = {}

-- GitHub-style heading anchor: lower case, punctuation dropped, spaces become hyphens
function M.slug(heading)
  local s = heading:lower():gsub('[^%w%s_-]', ''):gsub('%s', '-')
  return s
end

-- The [text](target) link under the cursor, if any (targets may carry a "title")
local function link_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  for start, target, finish in line:gmatch '()!?%[[^%]]*%]%(([^)]*)%)()' do
    if col >= start and col < finish then return target:match '^%s*<?([^%s>]+)' end
  end
  local cfile = vim.fn.expand '<cfile>'
  if cfile:match '^https?://' then return cfile end
end

local function decode(s)
  return (s:gsub('%%(%x%x)', function(hex) return string.char(tonumber(hex, 16)) end))
end

local function jump_to_heading(anchor)
  local in_code = false
  for lnum, text in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    if text:match '^%s*```' then in_code = not in_code end
    local heading = not in_code and text:match '^#+%s+(.-)%s*$'
    if heading and M.slug(heading) == anchor then
      vim.api.nvim_win_set_cursor(0, { lnum, 0 })
      vim.cmd 'normal! zt'
      return true
    end
  end
  return false
end

-- Open a link target; returns false (with a message) if it can't
function M.open(target)
  if target:match '^%a[%w+.-]*://' or target:match '^mailto:' then
    vim.ui.open(target)
    return true
  end
  local path, anchor = target:match '^([^#]*)#?(.*)$'
  path, anchor = decode(path), decode(anchor)
  if path == '' then
    path = vim.api.nvim_buf_get_name(0)
  elseif path:sub(1, 1) == '~' then
    path = vim.env.HOME .. path:sub(2)
  elseif path:sub(1, 1) ~= '/' then
    path = vim.fn.expand '%:p:h' .. '/' .. path
  end
  path = vim.fn.simplify(path)
  if vim.fn.isdirectory(path) == 0 and vim.fn.filereadable(path) == 0 then
    vim.notify('Link target not found: ' .. path, vim.log.levels.WARN)
    return false
  end
  vim.cmd "normal! m'" -- so Ctrl+o comes back here
  if path ~= vim.api.nvim_buf_get_name(0) then vim.cmd.edit(vim.fn.fnameescape(path)) end
  if anchor == '' then return true end
  if vim.bo.filetype == 'markdown' then
    if not jump_to_heading(anchor) then vim.notify('No heading "#' .. anchor .. '" in this file', vim.log.levels.WARN) end
  elseif anchor:match '^L%d+$' then
    vim.api.nvim_win_set_cursor(0, { math.min(tonumber(anchor:sub(2)), vim.fn.line '$'), 0 })
    vim.cmd 'normal! zz'
  else
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    if vim.fn.search('\\V' .. vim.fn.escape(anchor, '\\'), 'c') == 0 then
      vim.notify('"' .. anchor .. '" not found in this file', vim.log.levels.WARN)
    end
    vim.cmd 'normal! zz'
  end
  return true
end

-- Tick or untick a "- [ ]" / "1. [ ]" task on the current line; returns false if it isn't one
local function toggle_task()
  local line = vim.api.nvim_get_current_line()
  local before, mark, after = line:match '^(%s*[-*+]%s+%[)([ xX])(%].*)$'
  if not before then before, mark, after = line:match '^(%s*%d+[.)]%s+%[)([ xX])(%].*)$' end
  if not before then return false end
  vim.api.nvim_set_current_line(before .. (mark == ' ' and 'x' or ' ') .. after)
  return true
end

function M.attach(buf)
  local function follow_or(fallback)
    return function()
      local target = link_under_cursor()
      if target then return M.open(target) end
      if fallback == '<CR>' and toggle_task() then return end
      vim.api.nvim_feedkeys(vim.keycode(fallback), 'n', false)
    end
  end
  vim.keymap.set('n', '<CR>', follow_or '<CR>', { buffer = buf, desc = 'Open link / tick task' })
  vim.keymap.set('n', 'gd', follow_or 'gd', { buffer = buf, desc = 'Open link' })
  vim.wo.linebreak = true -- wrap long lines at word boundaries
end

return M
