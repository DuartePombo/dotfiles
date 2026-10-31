return {
  'linux-cultist/venv-selector.nvim',
  dependencies = {
    'neovim/nvim-lspconfig',
    'nvim-telescope/telescope.nvim',
    'mfussenegger/nvim-dap-python',
  },
  lazy = false,
  config = function()
    require('venv-selector').setup({
      options = {
        debug = true,
        -- Hide the search source column (anaconda_envs, anaconda_base)
        picker_columns = { "marker", "search_result" },
        -- Format to show just env name, path will show automatically
        on_telescope_result_callback = function(filename, source)
          if source == "anaconda_envs" then
            return filename:match("/envs/([^/]+)/") or filename
          elseif source == "anaconda_base" then
            return "base"
          end
          return filename
        end,
      },
      search = {
        anaconda_envs = {
          command = "fd 'bin/python$' " .. vim.fn.expand('~/miniforge3/envs') .. " --no-ignore-vcs --full-path --color never",
          type = "anaconda",
        },
        anaconda_base = {
          command = "fd '/python$' " .. vim.fn.expand('~/miniforge3/bin') .. " --full-path --color never",
          type = "anaconda",
        },
      },
    })
  end,
  keys = {
    { '<leader>vs', '<cmd>VenvSelect<cr>', desc = '[V]env [S]elect' },
    { '<leader>vc', '<cmd>VenvSelectCached<cr>', desc = '[V]env Select [C]ached' },
  },
}
