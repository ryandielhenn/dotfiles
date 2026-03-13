local o, wo = vim.o, vim.wo
o.number = true                  -- show line numbers
o.tabstop = 4                    -- tab character displays as 4 spaces
o.softtabstop = 4                -- tab key moves 4 spaces in insert mode
o.shiftwidth = 4                 -- >> and << indent by 4 spaces
o.expandtab = true               -- pressing tab inserts spaces, not a tab character
o.hidden = true                  -- lets you switch buffers without saving first
o.encoding = "utf-8"
o.updatetime = 300               -- ms before CursorHold fires, affects LSP responsiveness

o.shortmess = o.shortmess .. "c" -- suppresses "match 1 of 2" completion menu messages
wo.signcolumn = "yes"            -- always show the gutter column (stops layout shifting when diagnostics appear)
o.report = 0                     -- always report number of lines changed (default only reports if > 2)vim.g.netrw_banner = 0

vim.g.netrw_browse_split = 0     -- open files in same window
vim.g.netrw_winsize = 25         -- explorer takes 25% of width

-- Keymap helper
local map = function(m, l, r, o)
  o = vim.tbl_extend("force", { silent = true, noremap = true }, o or {})
  vim.keymap.set(m, l, r, o)
end

-- Keymappings
map("n", "<leader>ff", ":Files<CR>")    -- fuzzy file find
map("n", "<leader>fg", ":Rg ")          -- ripgrep inside vim
map("n", "<leader>fb", ":Buffers<CR>")  --
map("n", "<leader>fe", ":Lexplore<CR>") -- file explorer
map("n", "gf", ":GFiles<CR>")           -- fuzzy find files tracked by git
map("n", "gb", ":Git blame<CR>")        -- git blame
map("n", "bn", ":bn<CR>")               -- next buffer
map("n", "bp", ":bp<CR>")               -- previous buffer

-- Colorscheme
vim.o.termguicolors = true
pcall(vim.cmd.colorscheme, "everforest")

-- Treesitter config
pcall(function()
  require("nvim-treesitter.configs").setup({
    highlight = { enable = true },
    indent    = { enable = true },
  })
end)

-- MarkdownPreview
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
    lua = { "stylua" },
  },
})

-- FZF config
vim.g.fzf_layout = { down = "40%" }
vim.api.nvim_create_user_command("Rg", function(opts)
  local query = table.concat(opts.fargs, " ")
  local cmd = "rg --column --line-number --no-heading --color=always " .. query
  local wp = vim.fn["fzf#vim#with_preview"]
  local spec = opts.bang and wp("up:60%") or wp("right:50%:hidden", "?")
  vim.fn["fzf#vim#grep"](cmd, 1, spec, opts.bang)
end, { bang = true, nargs = "*" })
