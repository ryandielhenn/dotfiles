return {
  {
    "iamcco/markdown-preview.nvim",
    build = "cd app && npx --yes yarn install",
    ft = { "markdown" }, -- lazy-load only for markdown files
  }
}
