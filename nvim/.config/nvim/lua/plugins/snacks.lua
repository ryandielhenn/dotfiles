return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = { dashboard = { enabled = false } },
  keys = {
    {
      "<leader>rg",
      function() Snacks.picker.grep() end,
      desc = "Grep (Root Dir)"
    },
    {
      "<leader>gw",
      function() Snacks.picker.grep_word() end,
      desc = "Visual selection or word under cursor",
      mode = { "n", "x" }
    },
    {
      "<leader>ec",
      function()
        Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
      end,
      desc = "Find Config File",
    },
    {
      "<leader>ed",
      function()
        Snacks.picker.files({
          cwd = vim.fn.expand("~/.dotfiles"),
          hidden = true,
          exclude = { "nvim" },
        })
      end,
      desc = "Find Dotfiles",
    },
  },
}
