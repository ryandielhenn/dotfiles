-- ~/.config/nvim/lua/plugins/init.lua

-- Plugin setup
return {
  { "sainnhe/everforest" },
  {
    "tpope/vim-vinegar",
    keys = {
      { "<leader>fe", ":Lexplore<CR>", silent = true, desc = "File explorer" },
    },
  },
  {
    "junegunn/fzf",
    build = "./install --bin",
  },
  {
    "junegunn/fzf.vim",
    keys = {
      { "<leader>ff", ":Files<CR>",  silent = true, desc = "Fuzzy file find" },
      { "gf",         ":GFiles<CR>", silent = true, desc = "Fuzzy find git-tracked files" },
    },
  },
  { "nvim-treesitter/nvim-treesitter", branch = "main", build = ":TSUpdate" },
  {
    "mason-org/mason.nvim",
    opts = {},
    keys = {
      { "<leader>ma", ":Mason<CR>", silent = true, desc = "Open Mason" },
    },
  },
  { "neovim/nvim-lspconfig" },
  { "stevearc/conform.nvim" },
  { "williamboman/mason-lspconfig.nvim" },
  { "mfussenegger/nvim-jdtls",          ft = { "java" } },
  { 'wakatime/vim-wakatime',            lazy = false, },
  { "edkolev/tmuxline.vim" },
  {
    "tpope/vim-fugitive",
    keys = {
      { "<leader>gd", ":Gdiffsplit<CR>", silent = true, desc = "Git diff split" },
      { "gb",         ":Git blame<CR>",  silent = true, desc = "Git blame" },
    },
  },
  { "airblade/vim-gitgutter" },
}
