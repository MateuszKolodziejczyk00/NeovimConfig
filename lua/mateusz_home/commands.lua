local function open_build_terminal(cmd)
	vim.cmd("set splitright")
	vim.cmd("vsplit")
	vim.cmd("terminal " .. cmd)
end

vim.api.nvim_create_user_command("BL", function(opts)
	local args = vim.split(opts.args, ",", { trimempty = true })

	for i, arg in ipairs(args) do
		args[i] = vim.trim(arg)
	end

	local solution = args[1] or "Sculptor"
	local config = args[2] or "Development"
	local platform = args[3] or "x64"
	
	local cmd = string.format("msbuild %s.sln /p:Configuration=%s /p:Platform=%s /m", solution, config, platform)
	open_build_terminal(cmd)
end, { nargs = "*" })



vim.api.nvim_create_user_command("RBL", function(opts)
	local args = vim.split(opts.args, ",", { trimempty = true })

	-- Trim whitespace from each argument
	for i, arg in ipairs(args) do
		args[i] = vim.trim(arg)
	end

	local solution = args[1] or "Sculptor"
	local config = args[2] or "Development"
	local platform = args[3] or "x64"

	local cmd = string.format("msbuild %s.sln /t:Rebuild /p:Configuration=%s /p:Platform=%s /m", solution, config, platform)
	open_build_terminal(cmd)
end, { nargs = "*" })


vim.api.nvim_create_user_command("BLM", function(opts)
	local args = vim.split(opts.args, ",", { trimempty = true })

	for i, arg in ipairs(args) do
		args[i] = vim.trim(arg)
	end

	if #args < 1 then
		print("Usage: :BLM <project>, [solution], [config], [platform]")
		return
	end

	local project = args[1]
	local solution = args[2] or "Sculptor"
	local config = args[3] or "Development"
	local platform = args[4] or "x64"
	
	local cmd = string.format("msbuild %s.sln /t:%s /p:Configuration=%s /p:Platform=%s /m /p:BuildProjectReferences=false", solution, project, config, platform)
	open_build_terminal(cmd)
end, { nargs = "*" })
