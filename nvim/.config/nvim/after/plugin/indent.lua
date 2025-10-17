-- ~/.config/nvim/after/plugin/indent.lua

-- Define groups of filetypes by indentation style
local two_space = {
  "css", "html", "json", "yaml", "lua", "javascript", "typescript", "tsx", "vue",
  "markdown", "toml", "sh", "zsh"
}

local tabbed = {
  "make", "makefile"
}

-- Create an autocmd that sets options when a buffer is entered
vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function()
    local ft = vim.bo.filetype

    if vim.tbl_contains(two_space, ft) then
      vim.opt_local.expandtab = true
      vim.opt_local.tabstop = 2
      vim.opt_local.shiftwidth = 2
      vim.opt_local.softtabstop = 2

    elseif vim.tbl_contains(tabbed, ft) then
      vim.opt_local.expandtab = false
      vim.opt_local.tabstop = 4
      vim.opt_local.shiftwidth = 4
      vim.opt_local.softtabstop = 0
    end
  end,
})
