vim.g.copilot_filetypes = {
	--["*"] = false,
}

vim.keymap.set('i', '<C-l>', '<Plug>(copilot-suggest)')
vim.keymap.set('i', '<C-k>', '<Plug>(copilot-previous)')
vim.keymap.set('i', '<C-j>', '<Plug>(copilot-next)')
vim.keymap.set('i', '<C-h>', '<Plug>(copilot-dismiss)')
