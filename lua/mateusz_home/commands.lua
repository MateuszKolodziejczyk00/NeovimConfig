vim.api.nvim_create_user_command("BL", function(opts)
	local args = vim.split(opts.args, ",", { trimempty = true })

	for i, arg in ipairs(args) do
		args[i] = vim.trim(arg)
	end

	local solution = args[1] or "Sculptor"
	local config = args[2] or "Development"
	local platform = args[3] or "x64"
	
	local cmd = string.format("msbuild %s.sln /p:Configuration=%s /p:Platform=%s /m", solution, config, platform)
	
	vim.cmd("set splitright")
	vim.cmd("vsplit")
	vim.cmd("terminal " .. cmd)
end, { nargs = "*" })

-- Rebuild command for MSBuild
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

	vim.cmd("set splitright")
	vim.cmd("vsplit")
	vim.cmd("terminal " .. cmd)
end, { nargs = "*" })
