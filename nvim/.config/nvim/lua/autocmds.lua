-- Yank highlight colors (Everforest-aware)
if vim.g.colors_name and string.match(vim.g.colors_name, "everforest") then
  vim.api.nvim_set_hl(0, "YankHighlight", { bg = "#a7c080", fg = "NONE", bold = true })
else
  vim.api.nvim_set_hl(0, "YankHighlight", { bg = "#444444", fg = "#ffffff", bold = true })
end

local grp = vim.api.nvim_create_augroup("highlight_yank", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
  group = grp,
  callback = function()
    vim.highlight.on_yank({ higroup = "YankHighlight", timeout = 150 })
  end,
})
