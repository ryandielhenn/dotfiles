-- ~/.config/nvim/lua/plugins/init.lua

-- Plugin setup
return {
  { "sainnhe/everforest" },
  { "tpope/vim-vinegar" },
  { "ojroques/nvim-osc52" },
  { "junegunn/fzf",                     build = "./install --bin" },
  { "junegunn/fzf.vim" },
  { "neovim/nvim-lspconfig" },
  { "stevearc/conform.nvim" },
  { "williamboman/mason-lspconfig.nvim" },
  { "mfussenegger/nvim-jdtls" },
  { 'wakatime/vim-wakatime',            lazy = false },
  { "edkolev/tmuxline.vim" },
  { "tpope/vim-fugitive" },
  { "airblade/vim-gitgutter" },
  { "skywind3000/asyncrun.vim" },
}
