require("mateusz.remap")
require("mateusz.set")
require("mateusz.commands")

vim.cmd[[colorscheme gruvbox-material]]
vim.opt.termguicolors = true
vim.opt.background = "dark"
vim.api.nvim_set_hl(0, "Normal", { bg = "#000000" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "#000000" })

local wilder = require('wilder')
wilder.setup({modes = {':', '/', '?'}})

vim.opt.cursorline = true

require('smear_cursor').enabled = true
