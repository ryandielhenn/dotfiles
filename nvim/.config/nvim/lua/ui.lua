vim.o.termguicolors = true
vim.cmd.colorscheme("everforest")

-- Visual selection color
vim.api.nvim_set_hl(0, "Visual", { bg = "#3a4248", fg = "NONE" })

-- Airline
vim.g.airline_powerline_fonts = 1
vim.g["airline#extensions#tabline#enabled"] = 1
vim.g.airline_theme = "everforest"
vim.g.airline_section_c = "%{coc#status()}"
