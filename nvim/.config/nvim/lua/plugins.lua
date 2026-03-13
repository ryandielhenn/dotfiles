-- ~/.config/nvim/lua/plugins.lua

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

-- Plugin setup
require("lazy").setup({
  { "sainnhe/everforest" },
  { "ojroques/nvim-osc52" },
  { "junegunn/fzf",         build = "./install --bin" },
  { "junegunn/fzf.vim" },
  { "neovim/nvim-lspconfig" },
  { "stevearc/conform.nvim" },
  {
    "mason-org/mason.nvim",
    opts = {}
  },
  { "williamboman/mason-lspconfig.nvim" },
  { "mfussenegger/nvim-jdtls" },
  {
    'saghen/blink.cmp',
    version = '*',
    opts = {
      keymap = {
        preset = 'default',
        ['<CR>'] = { 'accept', 'fallback' },
        ['<Tab>'] = { 'accept', 'fallback' },
      },
      appearance = { nerd_font_variant = 'mono' },
      completion = { documentation = { auto_show = true } },
      sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
    },
  },
  {
    "vim-airline/vim-airline",
    dependencies = { "vim-airline/vim-airline-themes" },
    init = function()
      vim.g.airline_powerline_fonts = 1
      vim.g["airline#extensions#tabline#enabled"] = 1
      vim.g["airline#extensions#nvimlsp#enabled"] = 1
      vim.g.airline_theme = "everforest"
      vim.opt.laststatus = 2
      vim.opt.showtabline = 2
    end,
  },
  { 'wakatime/vim-wakatime', lazy = false },
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
  install = {
    missing = true, -- auto-install any missing plugins on startup
  },
  checker = {
    enabled = true, -- auto-check for plugin updates
    notify = false, -- don't spam with notifications
  },
  rocks = {
    enabled = true,
    hererocks = true,
  },
})
