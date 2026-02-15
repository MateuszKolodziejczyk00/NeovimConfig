vim.g.mapleader = " "
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- Open corresponding file
vim.keymap.set("n", "<leader>l", function()
	local file = vim.fn.expand("%:p")
	local ext = vim.fn.expand("%:e")
	local base = vim.fn.expand("%:p:r")
	
	local extensions = {}
	if ext == "h" or ext == "hpp" then
		extensions = {"cpp", "c", "cc", "cxx"}
	elseif ext == "cpp" or ext == "c" or ext == "cc" or ext == "cxx" then
		extensions = {"h", "hpp", "hxx"}
	else
		print("Not a C/C++ header or source file")
		return
	end
	
	for _, new_ext in ipairs(extensions) do
		local target = base .. "." .. new_ext
		if vim.fn.filereadable(target) == 1 then
			vim.cmd("edit " .. vim.fn.fnameescape(target))
			return
		end
	end
	
	print("No corresponding file found")
end, { desc = "Switch between header and source file" })

vim.keymap.set("v", "<C-c>", '"+y', { desc = "Copy to system clipboard" })
vim.keymap.set("n", "<C-v>", '"+p', { desc = "Paste from system clipboard" })
vim.keymap.set("i", "<C-v>", '<C-r>+', { desc = "Paste from system clipboard in insert mode" })
vim.keymap.set("v", "<C-v>", '"+p', { desc = "Paste from system clipboard in visual mode" })

vim.keymap.set("n", "<M-q>", "<cmd>close<CR>", { desc = "Close window" })
vim.keymap.set("n", "<M-h>", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<M-j>", "<C-w>j", { desc = "Move to window below" })
vim.keymap.set("n", "<M-k>", "<C-w>k", { desc = "Move to window above" })
vim.keymap.set("n", "<M-l>", "<C-w>l", { desc = "Move to right window" })
vim.keymap.set("n", "<M-v>", "<cmd>vsplit<CR>", { desc = "Vertical Split" })
vim.keymap.set("n", "<leader>]", "<cmd>copen25<CR>zz", { desc = "Open quickfix" })

vim.keymap.set("n", "<leader>[", "<cmd>cclose<CR>zz", { desc = "Close quickfix" })
vim.keymap.set("n", "<C-]>", "<cmd>cnext<CR>zz", { desc = "Next quickfix" })
vim.keymap.set("n", "<C-[>", "<cmd>cprev<CR>zz", { desc = "Previous quickfix" })

vim.keymap.set("n", "m", "<Plug>(easymotion-prefix)")

vim.keymap.set("n", "<leader>y", function() require("yazi").yazi() end)

vim.keymap.set("n", "<leader>w", '<cmd>:w<CR>', { desc = "Save file" })

vim.keymap.set("n", "<leader>q", '<cmd>:cexpr []<CR>', { desc = "Clear quickfix list" })
