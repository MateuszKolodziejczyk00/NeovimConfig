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

local function save_window_view(win)
	return vim.api.nvim_win_call(win, function()
		return vim.fn.winsaveview()
	end)
end

local function restore_window_view(win, view)
	vim.api.nvim_win_call(win, function()
		vim.fn.winrestview(view)
	end)
end

local function swap_with_direction(direction)
	local current_win = vim.api.nvim_get_current_win()
	local target_winnr = vim.fn.winnr(direction)
	local current_winnr = vim.fn.winnr()

	if target_winnr == current_winnr then
		vim.notify("No window in that direction", vim.log.levels.INFO)
		return
	end

	local target_win = vim.fn.win_getid(target_winnr)
	local current_buf = vim.api.nvim_win_get_buf(current_win)
	local target_buf = vim.api.nvim_win_get_buf(target_win)
	local current_view = save_window_view(current_win)
	local target_view = save_window_view(target_win)

	vim.api.nvim_win_set_buf(current_win, target_buf)
	vim.api.nvim_win_set_buf(target_win, current_buf)
	restore_window_view(current_win, target_view)
	restore_window_view(target_win, current_view)
	vim.api.nvim_set_current_win(target_win)
end

vim.keymap.set("n", "<M-H>", function() swap_with_direction("h") end, { desc = "Move current window left" })
vim.keymap.set("n", "<M-J>", function() swap_with_direction("j") end, { desc = "Move current window below" })
vim.keymap.set("n", "<M-K>", function() swap_with_direction("k") end, { desc = "Move current window above" })
vim.keymap.set("n", "<M-L>", function() swap_with_direction("l") end, { desc = "Move current window right" })

vim.keymap.set("n", "<M-v>", "<cmd>vsplit<CR>", { desc = "Vertical Split" })
vim.keymap.set("n", "<leader>]", "<cmd>copen25<CR>zz", { desc = "Open quickfix" })

vim.keymap.set("n", "<leader>[", "<cmd>cclose<CR>zz", { desc = "Close quickfix" })
vim.keymap.set("n", "<C-]>", "<cmd>cnext<CR>zz", { desc = "Next quickfix" })
vim.keymap.set("n", "<C-[>", "<cmd>cprev<CR>zz", { desc = "Previous quickfix" })

vim.keymap.set("n", "m", "<Plug>(easymotion-prefix)")

vim.keymap.set("n", "<leader>y", function() require("yazi").yazi() end)

vim.keymap.set("n", "<leader>w", '<cmd>:w<CR>', { desc = "Save file" })

vim.keymap.set("n", "<leader>q", '<cmd>:cexpr []<CR>', { desc = "Clear quickfix list" })

local _99 = require("99")

vim.keymap.set("v", "<leader>h", function() _99.visual() end)
vim.keymap.set("v", "<leader>j", function() _99.stop_all_requests() end)

vim.keymap.set({ 'n', 'x', 'o' }, 's', function() require("leap").leap{ target_windows = { vim.fn.win_getid() } } end)
vim.keymap.set('n',               'S', function() require("leap").leap{ target_windows = { vim.fn.win_getid() }, from_windows = true } end)

-- Recording (from 'q' to 'Q')
vim.keymap.set("n", "Q", "q", { noremap = true, desc = "Record macro" })
vim.keymap.set("n", "q", "<Nop>", { noremap = true })
