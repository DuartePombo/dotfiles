-- Python environments, like VS Code's "Select Interpreter": <leader>vs lists the Miniforge conda envs (and base)
-- and venvs such as uv's .venv in the project. The selection applies to the language server (basedpyright),
-- the debugger (dap-python runs your program with it), <leader>rr and terminals opened from Neovim (it updates
-- Neovim's own PATH and VIRTUAL_ENV/CONDA_PREFIX), and it is remembered per project.
return {
  'linux-cultist/venv-selector.nvim',
  dependencies = {
    'neovim/nvim-lspconfig',
    'nvim-telescope/telescope.nvim',
    'mfussenegger/nvim-dap-python',
  },
  lazy = false,
  config = function()
    require('venv-selector').setup {
      options = {
        notify_user_on_venv_activation = true,
        -- Show conda env names instead of full paths
        picker_columns = { 'marker', 'search_name', 'search_result' },
        on_telescope_result_callback = function(filename, source)
          if source == 'miniforge_envs' then
            return filename:match '/envs/([^/]+)/' or filename
          elseif source == 'miniforge_base' then
            return 'base (miniforge3)'
          end
          return filename
        end,
      },
      search = {
        miniforge_envs = {
          command = "$FD 'bin/python$' ~/miniforge3/envs --no-ignore-vcs --full-path --color never",
          type = 'anaconda',
        },
        miniforge_base = {
          command = "$FD '/python$' ~/miniforge3/bin --no-ignore-vcs --full-path --color never",
          type = 'anaconda',
        },
      },
    }
  end,
  keys = {
    { '<leader>vs', '<cmd>VenvSelect<cr>', desc = '[V]env [S]elect (Python interpreter)' },
    {
      '<leader>vi',
      function()
        local python = require('venv-selector').python()
        vim.notify(python and ('Python: ' .. python) or 'No environment selected (system python)', vim.log.levels.INFO)
      end,
      desc = '[V]env [I]nfo (active interpreter)',
    },
    { '<leader>vd', function() require('venv-selector').deactivate() end, desc = '[V]env [D]eactivate' },
  },
}
