local ok, osc52 = pcall(require, "osc52")
if not ok then return end

local last = { lines = nil, regtype = "v" }
local function copy(lines, regtype)
  last.lines = vim.deepcopy(lines)
  last.regtype = regtype or "v"
  osc52.copy(table.concat(lines, "\n"))
end
local function paste()
  if last.lines then return last.lines, last.regtype end
  local s = vim.fn.getreg('"')
  return vim.split(s, "\n", { plain = true, trimempty = false }), vim.fn.getregtype('"')
end

vim.g.clipboard = {
  name  = "osc52",
  copy  = { ["+"] = copy, ["*"] = copy },
  paste = { ["+"] = paste, ["*"] = paste },
}
vim.o.clipboard = "unnamedplus"
