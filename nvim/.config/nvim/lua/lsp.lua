require("mason-lspconfig").setup({
  automatic_enable = true
})

-- LSP configs
vim.lsp.config("rust_analyzer", {
  settings = {
    ["rust-analyzer"] = {
      cargo = {
        allFeatures = true,
        loadOutDirsFromCheck = true,
        runBuildScripts = true,
      },
    }
  }
})

-- LSP commands
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local buf = args.buf
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = buf })
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = buf })
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, { buffer = buf })
    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { buffer = buf })
  end
})

-- Diagnostics
vim.diagnostic.config({
  float = { border = "rounded" },
})

-- Diagnostics when cursor held on error
vim.api.nvim_create_autocmd("CursorHold", {
  callback = function()
    vim.diagnostic.open_float(nil, { focus = false })
  end,
})

vim.opt.updatetime = 500
