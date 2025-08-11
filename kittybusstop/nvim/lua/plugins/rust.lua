return {
  -- Enable rust-tools with rust-analyzer
  {
    "simrat39/rust-tools.nvim",
    dependencies = { "neovim/nvim-lspconfig" },
    ft = { "rust" },
    config = function()
      local rt = require("rust-tools")

      rt.setup({
        server = {
          on_attach = function(_, bufnr)
            -- Example keybindings for LSP
            local opts = { buffer = bufnr }
            vim.keymap.set("n", "K", rt.hover_actions.hover_actions, opts)
            vim.keymap.set("n", "<leader>ca", rt.code_action_group.code_action_group, opts)
          end,
        },
      })
    end,
  },
}
