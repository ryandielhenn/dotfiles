return {
  'nvim-telescope/telescope.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  keys = {
    { "<leader>fb", ":Telescope buffers<CR>", silent = true, desc = "Telescope buffers" },
  },
}
