return {
  'mfussenegger/nvim-jdtls',
  dependencies = {
    'mfussenegger/nvim-dap',
    'williamboman/mason.nvim',
  },
  ft = 'java',
  config = function()
    -- 1. Construct the path to the jdtls executable manually
    --    This avoids using the mason-registry API which was causing the crash
    local mason_path = vim.fn.stdpath('data') .. '/mason'
    local jdtls_bin = mason_path .. '/packages/jdtls/bin/jdtls'

    -- Check if jdtls is actually installed to prevent crashing
    if vim.fn.filereadable(jdtls_bin) ~= 1 then
      vim.notify("JDTLS not found. Please run :MasonInstall jdtls", vim.log.levels.ERROR)
      return
    end

    -- 2. Calculate the workspace directory
    --    This creates a unique data folder for every project to prevent conflicts
    local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
    local workspace_dir = vim.fn.stdpath('data') .. '/site/java/workspace-root/' .. project_name

    -- 3. Define the configuration
    local config = {
      cmd = {
        jdtls_bin,
        '-data', workspace_dir,
      },
      root_dir = require('jdtls.setup').find_root { '.git', 'mvnw', 'gradlew', 'pom.xml', 'build.gradle' },
      
      -- Attach blink.cmp capabilities
      capabilities = require('blink.cmp').get_lsp_capabilities(),
      
      settings = {
        java = {
          eclipse = { downloadSources = true },
          configuration = { updateBuildConfiguration = 'interactive' },
          maven = { downloadSources = true },
          implementationsCodeLens = { enabled = true },
          referencesCodeLens = { enabled = true },
          inlayHints = { parameterNames = { enabled = 'all' } },
        },
      },
    }

    -- 4. Start the Server
    require('jdtls').start_or_attach(config)
    
    -- 5. Keymaps
    vim.keymap.set('n', '<leader>co', "<cmd>lua require'jdtls'.organize_imports()<CR>", { desc = 'Organize Imports' })
    vim.keymap.set('n', '<leader>crv', "<cmd>lua require'jdtls'.extract_variable()<CR>", { desc = 'Extract Variable' })
    vim.keymap.set('v', '<leader>crv', "<esc><cmd>lua require'jdtls'.extract_variable(true)<CR>", { desc = 'Extract Variable' })
    vim.keymap.set('n', '<leader>crc', "<cmd>lua require'jdtls'.extract_constant()<CR>", { desc = 'Extract Constant' })
    vim.keymap.set('v', '<leader>crc', "<esc><cmd>lua require'jdtls'.extract_constant(true)<CR>", { desc = 'Extract Constant' })
    vim.keymap.set('v', '<leader>crm', "<esc><cmd>lua require'jdtls'.extract_method(true)<CR>", { desc = 'Extract Method' })
  end,
}
