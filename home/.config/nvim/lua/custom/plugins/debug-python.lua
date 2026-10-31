return {
  'mfussenegger/nvim-dap-python',
  dependencies = {
    'mfussenegger/nvim-dap',
  },
  config = function()
    -- Use debugpy from Mason (simpler, direct path approach)
    local debugpy_python = vim.fn.stdpath('data') .. '/mason/packages/debugpy/venv/bin/python'
    
    -- Setup Python debugging
    require('dap-python').setup(debugpy_python)
  end,
}
