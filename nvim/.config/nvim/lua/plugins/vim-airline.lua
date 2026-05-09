return {
  {
    "vim-airline/vim-airline",
    dependencies = { "vim-airline/vim-airline-themes" },
    init = function()
      vim.g.airline_powerline_fonts = 1
      vim.g["airline#extensions#tabline#enabled"] = 1
      vim.g["airline#extensions#tabline#ignore_bufadd_pat"] = "gundo|undotree|vimfiler|tagbar|nerd_tree"
      vim.g["airline#extensions#nvimlsp#enabled"] = 1
      vim.g.airline_theme = "everforest"
      vim.opt.laststatus = 2
      vim.opt.showtabline = 2
    end,
  }
}
