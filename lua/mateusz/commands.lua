vim.opt.grepprg = "rg --vimgrep"


vim.api.nvim_create_user_command("Run", function(opts)
	local cmd = opts.args

	vim.cmd("set splitright")
	vim.cmd("vsplit")
	vim.cmd("terminal " .. cmd)
end, { nargs = "+" })


vim.api.nvim_create_user_command("RP", function(opts)
	local idx = tonumber(opts.args)
	if not idx then
		print("Error: Please provide a valid line number")
		return
	end
	
	local presets_file = vim.fn.getcwd() .. "/RunPresets.txt"
	
	if vim.fn.filereadable(presets_file) == 0 then
		print("Error: RunPresets.txt not found in current directory")
		return
	end
	
	local lines = vim.fn.readfile(presets_file)
	
	if idx < 1 or idx > #lines then
		print("Error: Line " .. idx .. " not found (file has " .. #lines .. " lines)")
		return
	end
	
	local cmd = lines[idx]
	
	vim.cmd("set splitright")
	vim.cmd("vsplit")
	vim.cmd("terminal " .. cmd)
end, { nargs = 1 })


vim.api.nvim_create_user_command("CP", function()
	local path = vim.fn.expand("%:p")
	vim.fn.setreg("+", path)
	print("Copied: " .. path)
end, {})


vim.api.nvim_create_user_command("VSO", function()
	local file = vim.fn.expand("%:p")
	local line = vim.fn.line(".")

	if file == "" then
		print("No file to open")
		return
	end

	local cmd = string.format(
		'start "" "devenv.exe" /edit "%s" /command "Edit.Goto %d"',
		file,
		line
	)

	os.execute(cmd)
end, {})
