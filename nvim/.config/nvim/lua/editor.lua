vim.g.editorconfig = false
if vim.env.SSH_TTY ~= nil or vim.env.SSH_CLIENT ~= nil then
  vim.g.clipboard = {
    name  = "osc52",
    copy  = {
      ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
      ["*"] = require("vim.ui.clipboard.osc52").copy("*")
    },
    paste = {
      ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
      ["*"] = require("vim.ui.clipboard.osc52").paste("+")
    },
  }
end
vim.o.clipboard = "unnamedplus"

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

vim.opt.splitbelow = true
vim.opt.splitright = true

-- Keymap helper
local map = function(m, l, r, o)
  o = vim.tbl_extend("force", { silent = true, noremap = true }, o or {})
  vim.keymap.set(m, l, r, o)
end

-- Leader Keymappings
map("n", "<leader>ll", ":Lazy<CR>") -- open Lazy plugin manager
map("n", "<leader>ra", ":%s/")      -- replace all

-- buffer navigation
map("n", "bn", ":bn<CR>") -- next buffer
map("n", "bp", ":bp<CR>") -- previous buffer

-- terminal keymappings
map("t", "<esc><esc>", "<C-\\><C-n>")
map("n", "<leader>th", ":term<CR>")
map("n", "<leader>tv", ":vert term<CR>")

-- sync cwd with buffer
local function get_cwd_from_pid(pid)
  if vim.fn.has('mac') == 1 then
    local out = vim.fn.system({ 'lsof', '-a', '-p', tostring(pid), '-d', 'cwd', '-Fn' })
    if vim.v.shell_error ~= 0 then return nil end
    return out:match('\nn(/[^\n]*)')
  else
    return vim.fn.resolve('/proc/' .. pid .. '/cwd')
  end
end

vim.api.nvim_create_autocmd({ 'BufEnter', 'TermEnter', 'TermLeave' }, {
  desc = 'cd to terminal cwd on enter',
  pattern = 'term://*',
  callback = function()
    local pid = vim.b.terminal_job_pid
    if not pid then return end
    local cwd = get_cwd_from_pid(pid)
    if not cwd or vim.fn.isdirectory(cwd) == 0 then return end
    vim.fn.chdir(cwd)
  end,
})

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
