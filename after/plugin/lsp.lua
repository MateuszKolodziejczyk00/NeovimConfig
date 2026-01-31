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


vim.lsp.enable('clangd')


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

local function use_compile_commands(json_path)
	local cwd = vim.fn.getcwd()
	local absolute_path = vim.fn.fnamemodify(cwd .. "/" .. json_path, ":p")
	local dir = vim.fn.fnamemodify(absolute_path, ":h")
	
	if vim.fn.filereadable(absolute_path) == 0 then
		print("compile_commands.json not found: " .. absolute_path)
		return
	end
	
	for _, client in ipairs(vim.lsp.get_clients()) do
		if client.name == "clangd" then
			client.stop(true)
		end
	end
	
	vim.lsp.config.clangd = {
		cmd = { 
			"clangd",
			"--compile-commands-dir=" .. dir,
			"--background-index",
			"--clang-tidy",
			"--completion-style=detailed",
			"--header-insertion=never",
			"--pch-storage=memory",
			"--limit-results=1000"
		},
		filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto", "hlsl", "hlsli", "ppfx", "mat", "mt", "mth", "scr" },
		root_dir = vim.fs.root(0, {".git", "compile_commands.json"}),
		on_attach = function(client, bufnr)
			-- LSP keybindings
			local opts = {buffer = bufnr, remap = false}
			vim.keymap.set("n", "gd", function() require('telescope.builtin').lsp_definitions() end, opts)
			vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
			vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end, opts)
			vim.keymap.set("n", "<leader>vd", function() vim.diagnostic.open_float() end, opts)
			vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, opts)
			vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, opts)
			vim.keymap.set("n", "<leader>vca", function() vim.lsp.buf.code_action() end, opts)
			vim.keymap.set("n", "<leader>vrn", function() vim.lsp.buf.rename() end, opts)
			vim.keymap.set("i", "<C-k>", function() vim.lsp.buf.signature_help() end, opts)
		end,
	}
	
	vim.lsp.enable('clangd')
	
	vim.defer_fn(function()
		local bufname = vim.api.nvim_buf_get_name(0)
		if bufname ~= "" and vim.fn.filereadable(bufname) == 1 then
			vim.cmd("edit")
		else
			print("clangd reconfigured, open a source file to attach.")
		end
	end, 200)
end

vim.api.nvim_create_user_command("UseCompileCommands", function(opts)
	use_compile_commands(opts.args)
end, { nargs = 1, complete = "file" })

vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		local cwd = vim.fn.getcwd()
		local search_paths = {
			"compile_commands.json",
			"build/compile_commands.json",
			"Build/compile_commands.json",
			"out/compile_commands.json",
			"cmake-build-debug/compile_commands.json",
			"cmake-build-release/compile_commands.json",
		}
		
		for _, path in ipairs(search_paths) do
			local full_path = cwd .. "/" .. path
			if vim.fn.filereadable(full_path) == 1 then
				use_compile_commands(path)
				return
			end
		end
	end,
})
