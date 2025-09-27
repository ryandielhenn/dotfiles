-- ~/.config/nvim/lua/plugins.lua

-- Bootstrap lazy.nvim if not installed
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Plugin setup
require("lazy").setup({
  { "sainnhe/everforest" },
  { "ojroques/nvim-osc52" },
  { "junegunn/fzf", build = "./install --bin" },
  { "junegunn/fzf.vim" },
  { "neoclide/coc.nvim", branch = "release" },
  {
    "vim-airline/vim-airline",
    dependencies = { "vim-airline/vim-airline-themes" },
    init = function()
      vim.g.airline_powerline_fonts = 1
      vim.g["airline#extensions#tabline#enabled"] = 1
      vim.g.airline_theme = "everforest"
      vim.g["airline#extensions#coc#enabled"] = 1
      vim.g.airline_section_c = [[%{coc#status()}]]

      vim.opt.laststatus = 2
      vim.opt.showtabline = 2
    end,
  },
  { "edkolev/tmuxline.vim" },
  {
    "iamcco/markdown-preview.nvim",
    build = "cd app && npx --yes yarn install",
    ft = { "markdown" }, -- lazy-load only for markdown files
  },
  { "tpope/vim-fugitive" },
  { "airblade/vim-gitgutter" },
  { "skywind3000/asyncrun.vim" },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
  },
  { "tpope/vim-vinegar" },
}, {
  install = {
    missing = true, -- auto-install any missing plugins on startup
  },
  checker = {
    enabled = true,  -- auto-check for plugin updates
    notify = false,  -- don't spam with notifications
  },
})
