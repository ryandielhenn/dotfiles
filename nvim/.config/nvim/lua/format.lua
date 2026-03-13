require("conform").setup({
  format_on_save = { timeout_ms = 500, lsp_format = "fallback" },
  formatters_by_ft = {
    go = { "goimports", "gofmt" },
    rust = { "rustfmt" },
    java = { "google-java-format" },
    python = { "black" },
    c = { "clang_format" },
  },
})
