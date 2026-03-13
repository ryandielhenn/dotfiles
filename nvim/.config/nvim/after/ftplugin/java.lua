local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.resolveSupport = {
  properties = { "documentation", "detail", "additionalTextEdits" }
}

require("jdtls").start_or_attach({
  cmd = { "jdtls" },
  root_dir = vim.fs.dirname(vim.fs.find({ ".git", "gradlew", "mvnw" }, { upward = true })[1]),
  capabilities = capabilities,
})
