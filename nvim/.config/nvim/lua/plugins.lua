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
  {
    "benlubas/molten-nvim",
    version = "^1.0.0",
    dependencies = { "3rd/image.nvim" },
    build = ":UpdateRemotePlugins",
    init = function()
      vim.g.molten_image_provider = "image.nvim"
      vim.g.molten_output_win_max_height = 40
      vim.g.molten_wrap_output = true
      
      -- Enable floating output window
      vim.g.molten_auto_open_output = true
      vim.g.molten_virt_text_output = false
      vim.g.molten_output_virt_lines = true
      vim.g.molten_virt_lines_off_by_1 = true
    end,
    config = function()
      vim.keymap.set("n", "<leader>mi", ":MoltenInit python3<CR>")
      vim.keymap.set("n", "<leader>rr", ":MoltenReevaluateCell<CR>")
      vim.keymap.set("n", "<leader>rl", ":MoltenEvaluateLine<CR>")
      vim.keymap.set("v", "<leader>r", ":<C-u>MoltenEvaluateVisual<CR>gv")
      vim.keymap.set("n", "<leader>e", ":MoltenEvaluateOperator<CR>")
      
      -- Enter the output window to scroll through it
      vim.keymap.set("n", "<leader>oe", ":noautocmd MoltenEnterOutput<CR>", { desc = "Enter output window" })
      vim.keymap.set("n", "<leader>oh", ":MoltenHideOutput<CR>", { desc = "Hide output" })
      vim.keymap.set("n", "<leader>os", ":MoltenShowOutput<CR>", { desc = "Show output" })
    end,
  },  
  {
    -- see the image.nvim readme for more information about configuring this plugin
    "3rd/image.nvim",
    opts = {
        backend = "kitty", -- whatever backend you would like to use
        max_width = 100,
        max_height = 12,
        max_height_window_percentage = math.huge,
        max_width_window_percentage = math.huge,
        window_overlap_clear_enabled = true, -- toggles images when windows are overlapped
        window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
    },
  },
  {
    "GCBallesteros/jupytext.nvim",
    config = true,
    lazy = false,
  },
  install = {
    missing = true, -- auto-install any missing plugins on startup
  },
  checker = {
    enabled = true,  -- auto-check for plugin updates
    notify = false,  -- don't spam with notifications
  },
  rocks = {
    enabled = true,
    hererocks = true,
  },
})
