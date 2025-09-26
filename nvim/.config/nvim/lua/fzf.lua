vim.g.fzf_layout = { down = "40%" }
vim.api.nvim_create_user_command("Rg", function(opts)
  local query = table.concat(opts.fargs, " ")
  local cmd = "rg --column --line-number --no-heading --color=always " .. query
  local wp = vim.fn["fzf#vim#with_preview"]
  local spec = opts.bang and wp("up:60%") or wp("right:50%:hidden", "?")
  vim.fn["fzf#vim#grep"](cmd, 1, spec, opts.bang)
end, { bang = true, nargs = "*" })
