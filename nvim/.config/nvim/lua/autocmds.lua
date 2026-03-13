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

-- LSP commands
require("mason-lspconfig").setup({ automatic_enable = true })
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local buf = args.buf
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = buf })
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = buf })
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, { buffer = buf })
    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { buffer = buf })
  end
})

vim.diagnostic.config({
  float = { border = "rounded" },
})

vim.api.nvim_create_autocmd("CursorHold", {
  callback = function()
    vim.diagnostic.open_float(nil, { focus = false })
  end,
})

vim.opt.updatetime = 500
