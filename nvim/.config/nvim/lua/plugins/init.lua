-- ~/.config/nvim/lua/plugins/init.lua

-- Plugin setup
return {
  { "sainnhe/everforest" },
  { "tpope/vim-vinegar" },
  { "junegunn/fzf",                     build = "./install --bin" },
  { "junegunn/fzf.vim" },
  { "nvim-treesitter/nvim-treesitter",  build = ":TSUpdate" },
  { "mason-org/mason.nvim",             opts = {} },
  { "neovim/nvim-lspconfig" },
  { "stevearc/conform.nvim" },
  { "williamboman/mason-lspconfig.nvim" },
  { "mfussenegger/nvim-jdtls" },
  { 'wakatime/vim-wakatime',            lazy = false },
  { "edkolev/tmuxline.vim" },
  { "tpope/vim-fugitive" },
  { "airblade/vim-gitgutter" },
}
