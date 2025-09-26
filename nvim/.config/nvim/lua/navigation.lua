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
