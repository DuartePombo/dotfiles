return {
  {
    "pittcat/codex.nvim",
    cmd = { "CodexOpen", "CodexToggle" },
    keys = {
      { "<leader>ao", "<cmd>CodexOpen<cr>", desc = "[A]I: Codex [O]pen" },
      { "<leader>at", "<cmd>CodexToggle<cr>", desc = "[A]I: Codex [T]oggle" },
    },
    config = function()
      require("codex").setup({})
    end,
  },
}

