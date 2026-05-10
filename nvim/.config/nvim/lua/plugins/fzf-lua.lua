return {
  {
    "ibhagwan/fzf-lua",
    -- optional for icon support
    -- or if using mini.icons/mini.nvim
    -- dependencies = { "nvim-mini/mini.icons" },
    dependencies = { "nvim-tree/nvim-web-devicons" },
    ---@module "fzf-lua"
    ---@type fzf-lua.Config|{}
    ---@diagnostic disable: missing-fields
    opts = {
      winopts = {
        split = "botright " .. math.floor(vim.o.lines * 0.4) .. "new",
      },
    },
    ---@diagnostic enable: missing-fields
    keys = {
      {
        "<leader>fb",
        ":FzfLua buffers<CR>",
        silent = true,
        desc = "Telescope buffers"
      },
      {
        "<leader>ff",
        ":FzfLua files<CR>",
        silent = true,
        desc = "Fuzzy file find"
      },
      {
        "gf",
        ":FzfLua git_files<CR>",
        silent = true,
        desc = "Fuzzy find git-tracked files"
      },
      {
        "<leader>rg",
        ":FzfLua live_grep<CR>",
        silent = true,
        desc = "Live grep"
      },
      {
        "<leader>gw",
        ":FzfLua grep_cword<CR>",
        silent = true,
        desc = "Grep word under cursor",
        mode = "n",
      },
      {
        "<leader>gw",
        ":<C-u>FzfLua grep_visual<CR>",
        silent = true,
        desc = "Grep visual selection",
        mode = "x",
      },
      {
        "<leader>ec",
        function()
          require("fzf-lua").files({ cwd = vim.fn.stdpath("config") })
        end,
        desc = "Find Config File",
      },
      {
        "<leader>ed",
        function()
          require("fzf-lua").files({
            cwd = vim.fn.expand("~/.dotfiles"),
            hidden = true,
            fd_opts = "--color=never --type f --hidden --follow --exclude .git --exclude nvim",
          })
        end,
        desc = "Find Dotfiles",
      },
    },
  },
}
