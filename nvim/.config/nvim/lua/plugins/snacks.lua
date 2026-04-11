return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = { dashboard = { enabled = false } },
  keys = {
    {
      "<leader>ec",
      function()
        Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
      end,
      desc = "Find Config File",
    },
  },
}
