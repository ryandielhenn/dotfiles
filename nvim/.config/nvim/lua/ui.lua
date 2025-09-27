vim.o.termguicolors = true
pcall(vim.cmd.colorscheme, "everforest")
-- Override Visual highlight after colorscheme loads
vim.api.nvim_set_hl(0, "Visual", { bg = "#3a4248", fg = "NONE", bold = false })
