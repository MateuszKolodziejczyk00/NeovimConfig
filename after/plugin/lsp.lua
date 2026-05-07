vim.filetype.add({
	extension = {
		hlsl  = "cpp",
		hlsli = "cpp",
		mat   = "cpp",
		mt    = "cpp",
		mth   = "cpp",
		ppfx  = "cpp",
		scr   = "cpp",
	}
})


local cmp = require('cmp')
cmp.setup({
	sources = {
		{name = 'nvim_lsp'},
		{name = 'buffer'},
	},
	mapping = cmp.mapping.preset.insert({
		['<C-Space>'] = cmp.mapping.complete(),
		['<CR>'] = cmp.mapping.confirm({select = false}),
		['<C-e>'] = cmp.mapping.abort(),
		['<C-n>'] = cmp.mapping.select_next_item(),
		['<C-p>'] = cmp.mapping.select_prev_item(),
	}),
	snippet = {
		expand = function(args)
			require('luasnip').lsp_expand(args.body)
		end,
	},
})

local function set_lsp_keymaps()
	vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, { desc = "LSP definitions" })
	vim.keymap.set("n", "gi", function() vim.lsp.buf.implementation() end, { desc = "LSP definitions" })
	vim.keymap.set("n", "gy", function() vim.lsp.buf.type_definition() end, { desc = "LSP definitions" })
	vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, { desc = "LSP hover" })
	vim.keymap.set("n", "<leader>ks", function() vim.lsp.buf.workspace_symbol() end, { desc = "LSP workspace symbols" })
	vim.keymap.set("n", "<leader>kd", function() vim.diagnostic.open_float() end, { desc = "LSP diagnostics" })
	vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, { desc = "Next diagnostic" })
	vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, { desc = "Previous diagnostic" })
	vim.keymap.set("n", "<leader>ka", function() vim.lsp.buf.code_action() end, { desc = "LSP code action" })
	vim.keymap.set("n", "<leader>kr", function() vim.lsp.buf.rename() end, { desc = "LSP rename" })
	vim.keymap.set("i", "<C-k>", function() vim.lsp.buf.signature_help() end, { desc = "LSP signature help" })
end

local active_cwd = nil
local clangd_enabled = false

local function current_cwd()
	return vim.fn.fnamemodify(vim.fn.getcwd(), ":p"):gsub("[/\\]$", "")
end

local function clangd_config()
	local cwd = current_cwd()
	return {
		name = "clangd",
		cmd = {
			"clangd",
			"--compile-commands-dir=" .. cwd,
			"--background-index",
			"--clang-tidy",
			"--completion-style=detailed",
			"--header-insertion=never",
			"--pch-storage=memory",
			"--limit-results=1000",
		},
		filetypes = nil,
		root_dir = cwd,
		single_file_support = true,
	}
end

local function stop_clangd_clients()
	for _, client in ipairs(vim.lsp.get_clients({ name = "clangd" })) do
		client.stop(true)
	end
end

local function ensure_clangd(force_restart)
	local cwd = current_cwd()
	local compile_commands = cwd .. "\\compile_commands.json"

	if vim.fn.filereadable(compile_commands) == 0 then
		if active_cwd ~= nil then
			stop_clangd_clients()
			active_cwd = nil
		end
		return
	end

	if force_restart or active_cwd ~= cwd then
		stop_clangd_clients()
		active_cwd = cwd
	end

	local config = clangd_config()
	vim.lsp.config.clangd = config
	if not clangd_enabled then
		vim.lsp.enable("clangd")
		clangd_enabled = true
	end
	vim.lsp.start(config, { bufnr = vim.api.nvim_get_current_buf() })
end

set_lsp_keymaps()
ensure_clangd(false)

vim.api.nvim_create_user_command("UseCompileCommands", function()
	ensure_clangd(true)
end, { nargs = 0 })

vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		ensure_clangd(false)
	end,
})

vim.api.nvim_create_autocmd({ "BufEnter", "DirChanged" }, {
	callback = function()
		ensure_clangd(false)
	end,
})
