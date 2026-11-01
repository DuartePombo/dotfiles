-- Debugging (DAP) for Python, C/C++ and JavaScript/TypeScript, with VS Code-style keys.
--
-- F5 starts debugging the current file (or continues when stopped), F9 toggles a breakpoint, F10/F11/Shift+F11
-- step over/into/out, Shift+F5 stops, Ctrl+Shift+F5 restarts. Everything is also under <leader>d (see
-- docs/neovim.md). The debugger UI opens by itself: variables, watches, call stack, breakpoints, and the program's
-- terminal; it stays open after the program ends (toggle it with <leader>du or F7).
--
-- Python runs with the interpreter picked in venv-selector (<leader>vs): the program doesn't need debugpy, the
-- adapter is Mason's. C/C++ files are compiled with -g into ~/.cache/nvim/run/ (same as <leader>rr).
-- Adapters (debugpy, codelldb, js-debug-adapter) are installed by mason-tool-installer (init.lua).
-- A project's .vscode/launch.json is read too: <leader>dc lists its configurations.

local function mason_bin(name)
  return vim.fn.stdpath 'data' .. '/mason/bin/' .. name
end

-- F5 / <leader>dd: continue a running session, else debug the current file with its language's first configuration
local function debug_current_file()
  local dap = require 'dap'
  if dap.session() then return dap.continue() end
  local configs = dap.configurations[vim.bo.filetype]
  if not configs or #configs == 0 then return dap.continue() end
  dap.run(configs[1])
end

-- dap-python's test debugging (pytest if the project uses it, else unittest), with the same interpreter as F5
local function python_test_opts()
  return { config = { pythonPath = require('custom.run').python(), cwd = vim.fn.getcwd() } }
end

local function python_only(fn)
  return function()
    if vim.bo.filetype ~= 'python' then return vim.notify('Test debugging is for Python files', vim.log.levels.WARN) end
    fn()
  end
end

return {
  'mfussenegger/nvim-dap',
  dependencies = {
    'rcarriga/nvim-dap-ui',
    'nvim-neotest/nvim-nio',
    'mfussenegger/nvim-dap-python',
    -- Variable values shown next to the code while stopped
    { 'theHamsta/nvim-dap-virtual-text', opts = {} },
  },
  keys = {
    -- VS Code keys
    { '<F5>', debug_current_file, desc = 'Debug: start (current file) / continue' },
    { '<S-F5>', function() require('dap').terminate() end, desc = 'Debug: stop' },
    { '<C-S-F5>', function() require('dap').restart() end, desc = 'Debug: restart' },
    { '<F9>', function() require('dap').toggle_breakpoint() end, desc = 'Debug: toggle breakpoint' },
    { '<F10>', function() require('dap').step_over() end, desc = 'Debug: step over' },
    { '<F11>', function() require('dap').step_into() end, desc = 'Debug: step into' },
    { '<S-F11>', function() require('dap').step_out() end, desc = 'Debug: step out' },
    { '<F7>', function() require('dapui').toggle() end, desc = 'Debug: toggle UI' },

    -- The same and more under <leader>d
    { '<leader>dd', debug_current_file, desc = '[D]ebug current file / continue' },
    { '<leader>dc', function() require('dap').continue() end, desc = '[C]ontinue / pick a configuration' },
    { '<leader>dL', function() require('dap').run_last() end, desc = 'Run [L]ast configuration again' },
    { '<leader>dC', function() require('dap').run_to_cursor() end, desc = 'Run to [C]ursor' },
    { '<leader>db', function() require('dap').toggle_breakpoint() end, desc = 'Toggle [B]reakpoint' },
    {
      '<leader>dB',
      function() require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ') end,
      desc = 'Conditional [B]reakpoint',
    },
    {
      '<leader>dl',
      function() require('dap').set_breakpoint(nil, nil, vim.fn.input 'Log message ({expr} is evaluated): ') end,
      desc = '[L]og point',
    },
    { '<leader>dX', function() require('dap').clear_breakpoints() end, desc = 'Clear all breakpoints' },
    { '<leader>dE', function() require('dap').set_exception_breakpoints() end, desc = '[E]xception breakpoints' },
    { '<leader>dn', function() require('dap').step_over() end, desc = 'Step over ([N]ext line)' },
    { '<leader>di', function() require('dap').step_into() end, desc = 'Step [I]nto' },
    { '<leader>do', function() require('dap').step_out() end, desc = 'Step [O]ut' },
    { '<leader>dk', function() require('dap').up() end, desc = 'Call stack up (caller)' },
    { '<leader>dj', function() require('dap').down() end, desc = 'Call stack down' },
    { '<leader>dp', function() require('dap').pause() end, desc = '[P]ause' },
    { '<leader>dx', function() require('dap').terminate() end, desc = 'Stop (terminate)' },
    { '<leader>dR', function() require('dap').restart() end, desc = '[R]estart' },
    { '<leader>du', function() require('dapui').toggle() end, desc = 'Toggle debugger [U]I' },
    { '<leader>dr', function() require('dap').repl.toggle() end, desc = 'Toggle [R]EPL' },
    { '<leader>de', function() require('dapui').eval(nil, { enter = true }) end, mode = { 'n', 'v' }, desc = '[E]valuate expression' },
    {
      '<leader>dw',
      function() require('dapui').elements.watches.add(vim.fn.expand '<cexpr>') end,
      desc = '[W]atch expression under cursor',
    },
    { '<leader>dt', python_only(function() require('dap-python').test_method(python_test_opts()) end), desc = 'Debug [T]est (Python method)' },
    { '<leader>dT', python_only(function() require('dap-python').test_class(python_test_opts()) end), desc = 'Debug [T]est class (Python)' },
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'
    local utils = require 'dap.utils'

    local function ask_args()
      return utils.splitstr(vim.fn.input 'Arguments: ')
    end

    ---------------------------------------------------------------- Python (debugpy via nvim-dap-python)
    -- The adapter runs from Mason's debugpy venv; the program runs with the interpreter from custom.run.python():
    -- the one picked in venv-selector, else $VIRTUAL_ENV/$CONDA_PREFIX, ./.venv, then the system python3.
    require('dap-python').setup(vim.fn.stdpath 'data' .. '/mason/packages/debugpy/venv/bin/python', { include_configs = false })
    local function python_path()
      return require('custom.run').python()
    end
    dap.configurations.python = {
      { type = 'python', request = 'launch', pythonPath = python_path, name = 'Python: current file', program = '${file}', cwd = '${workspaceFolder}', console = 'integratedTerminal' },
      { type = 'python', request = 'launch', pythonPath = python_path, name = 'Python: current file with arguments', program = '${file}', args = ask_args, cwd = '${workspaceFolder}', console = 'integratedTerminal' },
      { type = 'python', request = 'launch', pythonPath = python_path, name = 'Python: current file, step into libraries too', program = '${file}', cwd = '${workspaceFolder}', console = 'integratedTerminal', justMyCode = false },
      {
        type = 'python', request = 'launch', pythonPath = python_path, name = 'Python: module (python -m ...)', cwd = '${workspaceFolder}', console = 'integratedTerminal',
        module = function() return vim.fn.input 'Module: ' end,
      },
      {
        type = 'python', request = 'attach', name = 'Python: attach to debugpy (localhost:5678)',
        connect = { host = '127.0.0.1', port = 5678 },
      },
    }

    ---------------------------------------------------------------- C and C++ (codelldb)
    dap.adapters.codelldb = {
      type = 'server',
      port = '${port}',
      executable = { command = mason_bin 'codelldb', args = { '--port', '${port}' } },
    }

    -- Compile the current file with debug info; on errors fill the quickfix list and cancel the session
    local function build_current_file()
      local file, ft = vim.api.nvim_buf_get_name(0), vim.bo.filetype
      vim.cmd 'silent update'
      local cmd, out = require('custom.run').compile_cmd(file, ft)
      local result = vim.system({ 'bash', '-c', cmd }, { text = true }):wait()
      if result.code ~= 0 then
        vim.fn.setqflist({}, ' ', { title = 'Build: ' .. vim.fn.fnamemodify(file, ':t'), lines = vim.split(result.stderr, '\n') })
        vim.schedule(function() vim.cmd 'copen' end)
        vim.notify('Build failed, see the quickfix list', vim.log.levels.ERROR)
        return dap.ABORT
      end
      return out
    end

    dap.configurations.c = {
      { type = 'codelldb', request = 'launch', name = 'C/C++: build and debug current file', program = build_current_file, cwd = '${workspaceFolder}', stopOnEntry = false },
      { type = 'codelldb', request = 'launch', name = 'C/C++: build and debug current file with arguments', program = build_current_file, args = ask_args, cwd = '${workspaceFolder}', stopOnEntry = false },
      {
        type = 'codelldb', request = 'launch', name = 'C/C++: debug an executable (pick one)', cwd = '${workspaceFolder}', stopOnEntry = false,
        program = function() return utils.pick_file { executables = true } end, args = ask_args,
      },
      { type = 'codelldb', request = 'attach', name = 'C/C++: attach to a process', pid = utils.pick_process },
    }
    dap.configurations.cpp = dap.configurations.c

    ---------------------------------------------------------------- JavaScript and TypeScript (js-debug)
    for _, adapter in ipairs { 'pwa-node', 'pwa-chrome' } do
      dap.adapters[adapter] = {
        type = 'server',
        host = 'localhost',
        port = '${port}',
        executable = { command = mason_bin 'js-debug-adapter', args = { '${port}' } },
      }
    end
    local skip = { '<node_internals>/**', '${workspaceFolder}/node_modules/**' }
    local js_configs = {
      -- Node runs TypeScript directly (type stripping), so .ts files need no build step
      { type = 'pwa-node', request = 'launch', name = 'Node: current file', program = '${file}', cwd = '${workspaceFolder}', console = 'integratedTerminal', skipFiles = skip },
      { type = 'pwa-node', request = 'launch', name = 'Node: current file with arguments', program = '${file}', args = ask_args, cwd = '${workspaceFolder}', console = 'integratedTerminal', skipFiles = skip },
      { type = 'pwa-node', request = 'attach', name = 'Node: attach to a process (node --inspect)', processId = utils.pick_process, cwd = '${workspaceFolder}', skipFiles = skip },
      {
        type = 'pwa-chrome', request = 'launch', name = 'Chrome: open a URL (dev server)', webRoot = '${workspaceFolder}',
        runtimeExecutable = '/usr/bin/google-chrome-stable',
        url = function() return vim.fn.input('URL: ', 'http://localhost:5173') end,
      },
    }
    for _, ft in ipairs { 'javascript', 'typescript', 'javascriptreact', 'typescriptreact' } do
      dap.configurations[ft] = js_configs
    end

    ---------------------------------------------------------------- UI
    dapui.setup {
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
    }

    vim.api.nvim_set_hl(0, 'DapBreak', { fg = '#e51400' })
    vim.api.nvim_set_hl(0, 'DapLogPoint', { fg = '#61afef' })
    vim.api.nvim_set_hl(0, 'DapStop', { fg = '#ffcc00' })
    -- Line where execution is stopped
    vim.api.nvim_set_hl(0, 'DapLine', { bg = '#3d3d00' })
    local signs = {
      DapBreakpoint = { text = '●', texthl = 'DapBreak' },
      DapBreakpointCondition = { text = '◆', texthl = 'DapBreak' },
      DapBreakpointRejected = { text = '○', texthl = 'Comment' },
      DapLogPoint = { text = '◉', texthl = 'DapLogPoint' },
      DapStopped = { text = '→', texthl = 'DapStop', linehl = 'DapLine', numhl = 'DapStop' },
    }
    for name, sign in pairs(signs) do
      vim.fn.sign_define(name, sign)
    end

    -- Open the UI when a session starts. It stays open after the program ends, so its output and the last
    -- variables remain visible; close it with <leader>du (F7).
    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
  end,
}
