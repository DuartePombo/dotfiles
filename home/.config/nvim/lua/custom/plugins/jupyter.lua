-- Jupyter notebooks in Neovim.
--
-- Opening a .ipynb shows it as Python with "# %%" cell markers (jupytext), so the language server, formatter and
-- debugger work as in any .py file; saving writes the .ipynb back. The same cells work in plain .py files
-- (VS Code's "# %%" style). molten-nvim runs cells in a Jupyter kernel of the environment picked with <leader>vs,
-- and shows the output under each cell (plots as images in kitty, through image.nvim).
--
-- Keys (<leader>j): ji start the kernel, jr run cell (or selection), jn run cell and go to the next one,
-- ja run all, jA run all above, jl run line, jo/jh show/hide output, jd delete output, jx interrupt, jR restart,
-- jq stop the kernel, jb/jm new code/markdown cell below, je save outputs into the .ipynb; ]j/[j next/previous cell.
--
-- Neovim's Python host is the conda env "nvim" (packages/conda/nvim.yml): it runs molten and has the jupytext
-- command. Kernels for your environments are registered on first use (python -m ipykernel install --user).

local nvim_env = vim.fn.expand '~/miniforge3/envs/nvim'
local has_host = vim.fn.executable(nvim_env .. '/bin/python') == 1
-- Images need kitty (also inside tmux started from kitty, with allow-passthrough in tmux.conf)
local has_images = vim.env.KITTY_WINDOW_ID ~= nil or vim.env.TERM == 'xterm-kitty'

if has_host then
  vim.g.python3_host_prog = nvim_env .. '/bin/python'
  -- jupytext.nvim runs `jupytext` from PATH. Add a directory holding only that command (at the end of PATH, so
  -- `python` and `jupyter` in Neovim's terminals still mean your own environment's).
  local bin = vim.fn.stdpath 'data' .. '/jupytext-bin'
  if not vim.uv.fs_stat(bin .. '/jupytext') then
    vim.fn.mkdir(bin, 'p')
    vim.uv.fs_symlink(nvim_env .. '/bin/jupytext', bin .. '/jupytext')
  end
  if not vim.env.PATH:find(bin, 1, true) then vim.env.PATH = vim.env.PATH .. ':' .. bin end
end

-- IPython magics (%timeit, %%time, !pip install ...) run fine in the kernel, but the language servers see
-- them as Python syntax errors (Neovim can't hand notebooks to basedpyright in its notebook mode). In .ipynb
-- buffers, drop the diagnostics on those lines.
local diagnostic_set = vim.diagnostic.set
---@diagnostic disable-next-line: duplicate-set-field
vim.diagnostic.set = function(namespace, bufnr, diagnostics, opts)
  if vim.api.nvim_buf_get_name(bufnr):match '%.ipynb$' then
    diagnostics = vim.tbl_filter(function(d)
      local line = vim.api.nvim_buf_get_lines(bufnr, d.lnum, d.lnum + 1, false)[1] or ''
      return not line:match '^%s*[%%!]'
    end, diagnostics)
  end
  return diagnostic_set(namespace, bufnr, diagnostics, opts)
end

---------------------------------------------------------------------------------------------------- cells
-- Cells start at lines like "# %%" (in other languages, their comment leader + "%%")
local function marker_pattern()
  local leader = vim.trim((vim.bo.commentstring ~= '' and vim.bo.commentstring or '# %s'):gsub('%%s.*', ''))
  return '^' .. vim.pesc(leader) .. '%s*%%%%'
end

local function is_marker(lnum, pattern)
  return vim.fn.getline(lnum):match(pattern) ~= nil
end

-- The cell around line lnum: its marker line (0 if above the first marker), first/last code lines, and the next
-- cell's marker line (nil if it's the last cell)
local function cell_at(lnum)
  local pattern, last = marker_pattern(), vim.fn.line '$'
  local header = lnum
  while header >= 1 and not is_marker(header, pattern) do
    header = header - 1
  end
  local stop = math.max(lnum, header) + 1
  while stop <= last and not is_marker(stop, pattern) do
    stop = stop + 1
  end
  local first, final = header + 1, stop - 1
  while final >= first and vim.fn.getline(final):match '^%s*$' do
    final = final - 1
  end
  return {
    header = header,
    first = first,
    last = final,
    markdown = header >= 1 and vim.fn.getline(header):match '%[markdown%]' ~= nil,
    next = stop <= last and stop or nil,
  }
end

-- Cells worth sending to the kernel: code cells with at least one line that isn't blank or a comment (this skips
-- markdown cells and jupytext's header, which molten couldn't match to a notebook cell when saving outputs)
local function has_code(cell)
  if cell.markdown then return false end
  local leader = vim.pesc(vim.trim((vim.bo.commentstring ~= '' and vim.bo.commentstring or '# %s'):gsub('%%s.*', '')))
  for l = cell.first, cell.last do
    local line = vim.fn.getline(l)
    if not line:match '^%s*$' and not line:match('^%s*' .. leader) then return true end
  end
  return false
end

local function all_cells()
  local cells, lnum = {}, 1
  while lnum and lnum <= vim.fn.line '$' do
    local cell = cell_at(lnum)
    table.insert(cells, cell)
    lnum = cell.next and cell.next or nil
  end
  return cells
end

local function goto_cell(direction)
  local pattern, lnum = marker_pattern(), vim.fn.line '.'
  local step, limit = direction == 'next' and 1 or -1, direction == 'next' and vim.fn.line '$' or 1
  local header = cell_at(lnum).header
  local from = direction == 'next' and lnum + 1 or (header >= 1 and header - 1 or 0)
  for l = from, limit, step do
    if l >= 1 and is_marker(l, pattern) then
      vim.api.nvim_win_set_cursor(0, { math.min(l + 1, vim.fn.line '$'), 0 })
      return
    end
  end
  -- no marker above: the code before the first marker is the first cell
  if direction == 'prev' then vim.api.nvim_win_set_cursor(0, { 1, 0 }) end
end

-- New cell after the current one: "# %%" (or "# %% [markdown]"), then insert mode on its first line
local function add_cell(markdown)
  local cell = cell_at(vim.fn.line '.')
  local leader = vim.trim(vim.bo.commentstring:gsub('%%s.*', ''))
  local marker = leader .. ' %%' .. (markdown and ' [markdown]' or '')
  local body = markdown and (leader .. ' ') or ''
  local at, lines, cursor
  if cell.next then
    -- before the next cell's marker, keeping one blank line between cells
    at, lines = cell.next - 1, { marker, body, '' }
    cursor = at + 2
  else
    at = vim.fn.line '$'
    lines = vim.fn.getline(at):match '^%s*$' and { marker, body } or { '', marker, body }
    cursor = at + #lines
  end
  vim.api.nvim_buf_set_lines(0, at, at, false, lines)
  vim.api.nvim_win_set_cursor(0, { cursor, #body })
  vim.cmd 'startinsert!'
end

---------------------------------------------------------------------------------------------------- kernels
local function molten_ready()
  if vim.fn.exists ':MoltenInit' ~= 2 then
    vim.notify('molten is not registered: run :UpdateRemotePlugins and restart Neovim', vim.log.levels.ERROR)
    return false
  end
  return true
end

-- Kernel name for an interpreter: the conda env's name, "<project>-venv" for a project .venv, ...
local function kernel_name(python)
  local prefix = vim.fn.fnamemodify(python, ':h:h')
  local tail = vim.fn.fnamemodify(prefix, ':t')
  local name = tail
  if prefix == vim.fn.expand '~/miniforge3' then
    name = 'conda-base'
  elseif tail == '.venv' or tail == 'venv' then
    name = vim.fn.fnamemodify(prefix, ':h:t') .. '-venv'
  elseif prefix == '/usr' then
    name = 'system-python'
  end
  return (name:lower():gsub('[^%w%._-]', '-'))
end

-- Register a Jupyter kernel for the selected interpreter (once), so molten can start it
local function ensure_kernelspec(python, name)
  local spec = vim.fn.expand '~/.local/share/jupyter/kernels/' .. name .. '/kernel.json'
  if vim.fn.filereadable(spec) == 1 then
    local ok, json = pcall(vim.json.decode, table.concat(vim.fn.readfile(spec), '\n'))
    if ok and json.argv and json.argv[1] == python then return true end
  end
  if vim.system({ python, '-c', 'import ipykernel' }):wait().code ~= 0 then
    vim.notify(
      ('%s has no ipykernel, which Jupyter needs to run code there.\nInstall it (conda: conda install -n <env> ipykernel; '
        .. 'uv project: uv add --dev ipykernel), or pick another environment with <leader>vs.'):format(python),
      vim.log.levels.ERROR
    )
    return false
  end
  local result = vim.system({ python, '-m', 'ipykernel', 'install', '--user', '--name', name, '--display-name', 'Python (' .. name .. ')' }, { text = true }):wait()
  if result.code ~= 0 then
    vim.notify('Registering the kernel failed:\n' .. (result.stderr or ''), vim.log.levels.ERROR)
    return false
  end
  return true
end

local function running_kernels()
  local ok, kernels = pcall(vim.fn.MoltenRunningKernels, true)
  return ok and kernels or {}
end

-- Code sent to a kernel that is still starting loses its output (molten connects to the kernel's output channel
-- while it starts, and the cell stays "On Hold"), so code waits until molten reports the kernel ready.
local ready, pending = {}, {}
vim.api.nvim_create_autocmd('User', {
  group = vim.api.nvim_create_augroup('custom-molten-ready', { clear = true }),
  pattern = 'MoltenKernelReady',
  callback = function(ev)
    local id = ev.data and ev.data.kernel_id
    if not id then return end
    ready[id] = true
    local queue = pending[id] or {}
    pending[id] = nil
    vim.schedule(function()
      for _, fn in ipairs(queue) do
        fn()
      end
    end)
  end,
})

-- Start a kernel for the environment picked with <leader>vs (switching kernels if another one runs here)
local function init_kernel()
  if not molten_ready() then return nil end
  local python = require('custom.run').python()
  local name = kernel_name(python)
  local running = running_kernels()
  if vim.tbl_contains(running, name) then return name end
  if not ensure_kernelspec(python, name) then return nil end
  if #running > 0 then vim.cmd 'MoltenDeinit' end
  -- molten writes the kernel's connection file into Jupyter's runtime directory without creating it (fails on
  -- a machine where Jupyter never ran)
  vim.fn.mkdir(vim.fn.expand '~/.local/share/jupyter/runtime', 'p', tonumber('700', 8))
  ready[name] = false
  vim.cmd('MoltenInit ' .. name)
  if not vim.wait(5000, function() return vim.tbl_contains(running_kernels(), name) end, 100) then
    vim.notify('The kernel "' .. name .. '" did not start (see :messages)', vim.log.levels.ERROR)
    return nil
  end
  -- Show the outputs saved in the notebook
  if vim.fn.expand '%:e' == 'ipynb' then pcall(vim.cmd, 'MoltenImportOutput') end
  return name
end

-- Run fn(kernel) in this buffer once its kernel is ready, starting the kernel first if needed
local function with_kernel(fn)
  local buf = vim.api.nvim_get_current_buf()
  local kernel = running_kernels()[1] or init_kernel()
  if not kernel then return end
  local run = function()
    if vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_call(buf, function() fn(kernel) end) end
  end
  if ready[kernel] ~= false then -- true, or nil: started outside these keys and long ready
    run()
  else
    pending[kernel] = pending[kernel] or {}
    table.insert(pending[kernel], run)
  end
end

-- Run line ranges ({first, last} pairs, taken now, so typing while the kernel starts doesn't shift them)
local function run_ranges(ranges)
  ranges = vim.tbl_filter(function(r) return r[2] >= r[1] end, ranges)
  if #ranges == 0 then return end
  with_kernel(function(kernel)
    for _, r in ipairs(ranges) do
      vim.fn.MoltenEvaluateRange(kernel, r[1], r[2])
    end
  end)
end

local function run_cell(move)
  local cell = cell_at(vim.fn.line '.')
  if has_code(cell) then run_ranges { { cell.first, cell.last } } end
  if move then
    if cell.next then
      vim.api.nvim_win_set_cursor(0, { math.min(cell.next + 1, vim.fn.line '$'), 0 })
    else
      add_cell(false)
      vim.cmd 'stopinsert'
    end
  end
end

local function run_cells(up_to_cursor)
  local cursor, ranges = vim.fn.line '.', {}
  for _, cell in ipairs(all_cells()) do
    if up_to_cursor and cell.header > cursor then break end
    if has_code(cell) then table.insert(ranges, { cell.first, cell.last }) end
  end
  run_ranges(ranges)
end

local function run_selection()
  local first, last = vim.fn.line 'v', vim.fn.line '.'
  if first > last then first, last = last, first end
  vim.api.nvim_feedkeys(vim.keycode '<Esc>', 'nx', false)
  run_ranges { { first, last } }
end

-- After a restart the kernel starts again: hold new code until it's ready
local function restart_kernel()
  if not molten_ready() then return end
  for _, k in ipairs(running_kernels()) do
    ready[k] = false
  end
  vim.cmd 'MoltenRestart!'
end

local function molten_cmd(cmd)
  return function()
    if molten_ready() then vim.cmd(cmd) end
  end
end

return {
  {
    'benlubas/molten-nvim',
    cond = has_host,
    lazy = false,
    build = ':UpdateRemotePlugins',
    dependencies = { '3rd/image.nvim' },
    init = function()
      vim.g.molten_image_provider = has_images and 'image.nvim' or 'none'
      vim.g.molten_auto_open_output = false -- output shows under the cell; <leader>jo opens it in a window
      vim.g.molten_virt_text_output = true
      vim.g.molten_wrap_output = true
      vim.g.molten_output_win_max_height = 20
      vim.g.molten_output_show_exec_time = true
      vim.g.molten_auto_init_behavior = 'raise'
    end,
    config = function()
      local map = vim.keymap.set
      map('n', '<leader>ji', function()
        local name = init_kernel()
        if name then vim.notify('Kernel: ' .. name) end
      end, { desc = '[I]nit kernel (selected Python env)' })
      map('n', '<leader>jk', molten_cmd 'MoltenInit', { desc = 'Pick a [K]ernel from the list' })
      map('n', '<leader>jr', function() run_cell(false) end, { desc = '[R]un cell' })
      map('x', '<leader>jr', run_selection, { desc = '[R]un selection' })
      map('n', '<leader>jn', function() run_cell(true) end, { desc = 'Run cell, go to [N]ext' })
      map('n', '<leader>ja', function() run_cells(false) end, { desc = 'Run [A]ll cells' })
      map('n', '<leader>jA', function() run_cells(true) end, { desc = 'Run [A]ll cells above, and this one' })
      map('n', '<leader>jl', function() run_ranges { { vim.fn.line '.', vim.fn.line '.' } } end, { desc = 'Run [L]ine' })
      map('n', '<leader>jo', molten_cmd 'noautocmd MoltenEnterOutput', { desc = '[O]pen output (again to enter it)' })
      map('n', '<leader>jh', molten_cmd 'MoltenHideOutput', { desc = '[H]ide output window' })
      map('n', '<leader>jd', molten_cmd 'MoltenDelete', { desc = '[D]elete cell output' })
      map('n', '<leader>jx', molten_cmd 'MoltenInterrupt', { desc = 'Interrupt (stop running code)' })
      map('n', '<leader>jR', restart_kernel, { desc = '[R]estart kernel (clears variables)' })
      map('n', '<leader>jq', molten_cmd 'MoltenDeinit', { desc = '[Q]uit kernel' })
      map('n', '<leader>je', molten_cmd 'MoltenExportOutput!', { desc = '[E]xport outputs into the .ipynb' })
      map('n', '<leader>jb', function() add_cell(false) end, { desc = 'New code cell [B]elow' })
      map('n', '<leader>jm', function() add_cell(true) end, { desc = 'New [M]arkdown cell below' })
      map({ 'n', 'x', 'o' }, ']j', function() goto_cell 'next' end, { desc = 'Next notebook cell' })
      map({ 'n', 'x', 'o' }, '[j', function() goto_cell 'prev' end, { desc = 'Previous notebook cell' })

      -- Saving a notebook also saves the outputs of the cells you ran (jupytext keeps the other ones)
      vim.api.nvim_create_autocmd('BufWritePost', {
        group = vim.api.nvim_create_augroup('custom-molten-export', { clear = true }),
        pattern = '*.ipynb',
        callback = function()
          if #running_kernels() > 0 then pcall(vim.cmd, 'MoltenExportOutput!') end
        end,
      })
    end,
  },
  {
    '3rd/image.nvim',
    cond = has_host and has_images,
    opts = {
      backend = 'kitty',
      processor = 'magick_cli', -- ImageMagick's command line tools (packages/pacman.txt), no Lua rock needed
      integrations = {
        markdown = { enabled = false },
        neorg = { enabled = false },
        typst = { enabled = false },
        html = { enabled = false },
        css = { enabled = false },
      },
      -- Sizes recommended by molten
      max_width = 100,
      max_height = 12,
      max_height_window_percentage = math.huge,
      max_width_window_percentage = math.huge,
      window_overlap_clear_enabled = true,
      window_overlap_clear_ft_ignore = { 'cmp_menu', 'cmp_docs', 'blink-cmp-menu', 'blink-cmp-documentation', '' },
    },
  },
  {
    -- .ipynb <-> "# %%" Python text (hydrogen style: IPython magics like %timeit stay runnable)
    'GCBallesteros/jupytext.nvim',
    cond = has_host,
    lazy = false,
    init = function()
      -- `nvim new.ipynb` (a notebook that doesn't exist yet) would fail in jupytext.nvim, which reads the file's
      -- metadata. Start it as an empty Python notebook; it's removed again if you quit without saving.
      -- (Defined before jupytext.nvim's own handler, so it runs first.)
      local empty = vim.json.encode {
        cells = { { cell_type = 'code', execution_count = vim.NIL, metadata = vim.empty_dict(), outputs = {}, source = {} } },
        metadata = {
          kernelspec = { display_name = 'Python 3', language = 'python', name = 'python3' },
          language_info = { name = 'python' },
        },
        nbformat = 4,
        nbformat_minor = 5,
      }
      vim.api.nvim_create_autocmd('BufReadCmd', {
        group = vim.api.nvim_create_augroup('custom-new-notebook', { clear = true }),
        pattern = '*.ipynb',
        callback = function(ev)
          local file = vim.fn.fnamemodify(ev.match, ':p')
          if vim.fn.filereadable(file) == 1 then return end
          vim.fn.mkdir(vim.fn.fnamemodify(file, ':h'), 'p')
          vim.fn.writefile({ empty }, file)
          -- registered after jupytext.nvim's own unload handler (which still needs the file to remove its temporary
          -- .py), so this one runs last
          vim.schedule(function()
            vim.api.nvim_create_autocmd('BufUnload', {
              buffer = ev.buf,
              once = true,
              callback = function()
                if vim.fn.filereadable(file) == 1 and table.concat(vim.fn.readfile(file), '\n') == empty then vim.fn.delete(file) end
              end,
            })
          end)
        end,
      })
    end,
    opts = { style = 'hydrogen', output_extension = 'auto' },
  },
}
