-- Run the current file, and a reusable terminal at the bottom (like VS Code's "Run File" and terminal panel).
--   <leader>tt  toggle the terminal         <leader>rr  run the current file
--   <leader>ra  run with arguments          <leader>rl  run the last command again
-- Python runs with the interpreter selected in venv-selector (<leader>vs). C and C++ are compiled with debug info
-- into ~/.cache/nvim/run/ first (the same binaries the debugger uses, see lua/kickstart/plugins/debug.lua).
local M = {}

local term = { buf = nil, win = nil, env = nil }
local last_cmd = nil

-- Terminals inherit Neovim's environment when they start; venv-selector changes PATH/VIRTUAL_ENV/CONDA_PREFIX.
local function env_key()
  return table.concat({ vim.env.VIRTUAL_ENV or '', vim.env.CONDA_PREFIX or '' }, '|')
end

local function term_valid()
  return term.buf and vim.api.nvim_buf_is_valid(term.buf)
end

-- Show the terminal (starting it if needed) and return its job id
local function show_terminal(enter_insert)
  if term_valid() and term.env ~= env_key() then
    -- started with another Python environment: replace it so `python` means the selected one
    vim.api.nvim_buf_delete(term.buf, { force = true })
    term.buf = nil
  end
  if not (term.win and vim.api.nvim_win_is_valid(term.win)) then
    vim.cmd 'botright 15split'
    term.win = vim.api.nvim_get_current_win()
    if term_valid() then vim.api.nvim_win_set_buf(term.win, term.buf) end
  else
    vim.api.nvim_set_current_win(term.win)
  end
  if not term_valid() then
    vim.cmd.terminal()
    term.buf = vim.api.nvim_get_current_buf()
    term.env = env_key()
    vim.bo[term.buf].buflisted = false
  end
  if enter_insert then vim.cmd.startinsert() end
  return vim.b[term.buf].terminal_job_id
end

function M.toggle_terminal()
  if term.win and vim.api.nvim_win_is_valid(term.win) then
    vim.api.nvim_win_hide(term.win)
    term.win = nil
  else
    show_terminal(true)
  end
end

-- Type a command into the terminal and run it, keeping the cursor in the code window
function M.send(cmd)
  local code_win = vim.api.nvim_get_current_win()
  local job = show_terminal(false)
  vim.fn.chansend(job, cmd .. '\n')
  vim.api.nvim_win_call(term.win, function() vim.cmd 'normal! G' end)
  if vim.api.nvim_win_is_valid(code_win) then vim.api.nvim_set_current_win(code_win) end
  last_cmd = cmd
end

-- The Python interpreter for running and debugging, in this order: the one picked with venv-selector (<leader>vs),
-- an env that was active in the shell Neovim started from, the project's .venv/venv (uv; looked up from the
-- file's folder upwards, like uv does, then in Neovim's working folder), then the system python3.
-- (Without this, the debugger would fall back to Mason's debugpy interpreter, which has none of your packages.)
function M.python()
  local ok, vs = pcall(require, 'venv-selector')
  local python = ok and vs.python() or nil
  if python then return python end
  local prefix = vim.env.VIRTUAL_ENV or vim.env.CONDA_PREFIX
  if prefix then return prefix .. '/bin/python' end
  local file_dir = vim.fn.expand '%:p:h'
  local starts = { vim.fn.isdirectory(file_dir) == 1 and file_dir or nil, vim.fn.getcwd() }
  for _, start in ipairs(starts) do
    for _, venv in ipairs(vim.fs.find({ '.venv', 'venv' }, { upward = true, path = start, stop = vim.env.HOME, type = 'directory' })) do
      if vim.fn.executable(venv .. '/bin/python') == 1 then return venv .. '/bin/python' end
    end
  end
  return vim.fn.exepath 'python3'
end

-- Compile a C/C++ file with debug info; returns the shell command and the binary path
function M.compile_cmd(file, filetype)
  local out_dir = vim.fn.stdpath 'cache' .. '/run'
  local out = out_dir .. '/' .. vim.fn.fnamemodify(file, ':t:r')
  local compiler = filetype == 'cpp' and 'g++ -std=gnu++23' or 'gcc -std=gnu23' -- same as home/.config/clangd/config.yaml
  local cmd = string.format('mkdir -p %s && %s -g -O0 -Wall -Wextra %s -o %s -lm', vim.fn.shellescape(out_dir), compiler,
    vim.fn.shellescape(file), vim.fn.shellescape(out))
  return cmd, out
end

local function run_cmd_for(file, ft)
  local f = vim.fn.shellescape(file)
  if ft == 'python' then
    return vim.fn.shellescape(M.python()) .. ' ' .. f
  elseif ft == 'c' or ft == 'cpp' then
    local compile, out = M.compile_cmd(file, ft)
    return compile .. ' && ' .. vim.fn.shellescape(out)
  elseif ft == 'javascript' or ft == 'typescript' then
    return 'node ' .. f -- Node runs TypeScript directly (type stripping)
  elseif ft == 'sh' or ft == 'bash' then
    return 'bash ' .. f
  elseif ft == 'lua' then
    return 'nvim -l ' .. f
  elseif ft == 'java' then
    return 'java ' .. f -- single-file source launch
  elseif ft == 'html' then
    return 'xdg-open ' .. f
  end
end

function M.run_file(with_args)
  local file = vim.api.nvim_buf_get_name(0)
  if file == '' then return vim.notify('Save the file first', vim.log.levels.WARN) end
  vim.cmd 'silent update'
  local cmd = run_cmd_for(file, vim.bo.filetype)
  if not cmd then return vim.notify('No runner for filetype "' .. vim.bo.filetype .. '"', vim.log.levels.WARN) end
  if with_args then
    local args = vim.fn.input 'Arguments: '
    if args ~= '' then cmd = cmd .. ' ' .. args end
  end
  M.send(cmd)
end

function M.run_last()
  if not last_cmd then return vim.notify('Nothing has run yet', vim.log.levels.WARN) end
  M.send(last_cmd)
end

function M.setup()
  local map = vim.keymap.set
  map('n', '<leader>tt', M.toggle_terminal, { desc = '[T]oggle [T]erminal' })
  map('n', '<leader>rr', function() M.run_file(false) end, { desc = '[R]un current file' })
  map('n', '<leader>ra', function() M.run_file(true) end, { desc = '[R]un with [A]rguments' })
  map('n', '<leader>rl', M.run_last, { desc = '[R]un [L]ast command again' })
end

return M
