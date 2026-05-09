return {
  {
    "iamcco/markdown-preview.nvim",
    build = "cd app && npx --yes yarn install",
    ft = "markdown",
    keys = {
      { "<leader>mp", ":MarkdownPreviewToggle<CR>", silent = true, desc = "Toggle Markdown Preview" },
    },
  }
}
