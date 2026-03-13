require("jdtls").start_or_attach({
  cmd = { "jdtls" },
  root_dir = vim.fs.dirname(vim.fs.find({ ".git", "gradlew", "mvnw" }, { upward = true })[1]),
})
