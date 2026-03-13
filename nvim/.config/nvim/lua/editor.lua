local o, wo = vim.o, vim.wo
o.number = true
o.tabstop = 4
o.softtabstop = 4
o.shiftwidth = 4
o.expandtab = true
o.hidden = true
o.encoding = "utf-8"
o.backup = false
o.writebackup = false
o.updatetime = 300
o.shortmess = o.shortmess .. "c"
wo.signcolumn = "yes"
o.report = 0
vim.g.netrw_banner = 0
vim.g.netrw_liststyle = 3
vim.g.netrw_browse_split = 0
vim.g.netrw_winsize = 25

local map = function(m, l, r, o)
  o = vim.tbl_extend("force", { silent = true, noremap = true }, o or {})
  vim.keymap.set(m, l, r, o)
end

map("n", "<leader>ff", ":Files<CR>")
map("n", "<leader>fg", ":Rg ")
map("n", "<leader>fb", ":Buffers<CR>")
map("n", "<leader>fe", ":Lexplore<CR>")
map("n", "gf", ":GFiles<CR>")
map("n", "gb", ":Git blame<CR>")
map("n", "bn", ":bn<CR>")
map("n", "bp", ":bp<CR>")

vim.o.termguicolors = true
pcall(vim.cmd.colorscheme, "everforest")

pcall(function()
  require("nvim-treesitter.configs").setup({
    highlight = { enable = true },
    indent    = { enable = true },
  })
end)

-- MarkdownPreview bits
vim.g.mkdp_filetypes = { "markdown" }
vim.g.mkdp_auto_close = 1
map("n", "<leader>mp", ":MarkdownPreviewToggle<CR>")

-- Conform plugin settings for code formatting
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

vim.g.fzf_layout = { down = "40%" }
vim.api.nvim_create_user_command("Rg", function(opts)
  local query = table.concat(opts.fargs, " ")
  local cmd = "rg --column --line-number --no-heading --color=always " .. query
  local wp = vim.fn["fzf#vim#with_preview"]
  local spec = opts.bang and wp("up:60%") or wp("right:50%:hidden", "?")
  vim.fn["fzf#vim#grep"](cmd, 1, spec, opts.bang)
end, { bang = true, nargs = "*" })
