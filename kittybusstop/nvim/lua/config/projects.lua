require("project_nvim").setup({
  manual_mode = false,
  detection_methods = { "pattern", "lsp" },
  patterns = { ".git", "Makefile", "package.json" },
  -- Set your base directory to scan for projects:
  datapath = vim.fn.expand("/home/levinoppers/Coding/"),
  -- Or just rely on root patterns if your projects have .git folders
})

require("telescope").load_extension("projects")
