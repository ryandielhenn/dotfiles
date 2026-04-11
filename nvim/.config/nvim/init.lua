vim.g.mapleader = " "
vim.g.editorconfig = false

-- Bootstrap lazy.nvim if not installed
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins", {
  install = {
    missing = true,
  },
  checker = {
    enabled = true,
    notify = false,
  },
  rocks = {
    enabled = true,
    hererocks = true,
  },
})

require("plugins")
require("editor")
require("lsp")
require("clipboard")
require("notebooks")
