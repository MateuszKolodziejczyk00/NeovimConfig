---@alias TextDocumentFunction fun(client: lsp.Client): lsp.TextDocumentPositionParams

-- this code is adapted from vim.lsp.util and telescope's lsp_workspace_symbols.lua
-- with modifications to support symbol type filtering and multi-word queries
local uv = vim.uv
local api = vim.api
local lsp = vim.lsp
local protocol = require('vim.lsp.protocol')

local channel = require("plenary.async.control").channel
local actions = require "telescope.actions"
local sorters = require "telescope.sorters"
local conf = require("telescope.config").values
local finders = require "telescope.finders"
--local make_entry = require "telescope.make_entry"
local make_entry = require "mateusz.telescope.make_entry"
local pickers = require "telescope.pickers"
local utils = require "telescope.utils"


local M = {}

local nvim011 = utils.nvim011


local symbols_sorter = function(symbols)
  if vim.tbl_isempty(symbols) then
    return symbols
  end

  local current_buf = api.nvim_get_current_buf()

  -- sort adequately for workspace symbols
  local filename_to_bufnr = {}
  for _, symbol in ipairs(symbols) do
    if filename_to_bufnr[symbol.filename] == nil then
      filename_to_bufnr[symbol.filename] = vim.uri_to_bufnr(vim.uri_from_fname(symbol.filename))
    end
    symbol.bufnr = filename_to_bufnr[symbol.filename]
  end

  table.sort(symbols, function(a, b)
    if a.bufnr == b.bufnr then
      return a.lnum < b.lnum
    end
    if a.bufnr == current_buf then
      return true
    end
    if b.bufnr == current_buf then
      return false
    end
    return a.bufnr < b.bufnr
  end)

  return symbols
end


--- @param border string|(string|[string,string])[]
local function border_error(border)
  error(
    string.format(
      'invalid floating preview border: %s. :help vim.api.nvim_open_win()',
      vim.inspect(border)
    ),
    2
  )
end

local border_size = {
  none = { 0, 0 },
  single = { 2, 2 },
  double = { 2, 2 },
  rounded = { 2, 2 },
  solid = { 2, 2 },
  shadow = { 1, 1 },
  bold = { 2, 2 },
}

--- Check the border given by opts or the default border for the additional
--- size it adds to a float.
--- @param opts? {border:string|(string|[string,string])[]}
--- @return integer height
--- @return integer width
local function get_border_size(opts)
  local border = opts and opts.border or vim.o.winborder

  if border == '' then
    border = 'none'
  end

  if type(border) == 'string' then
    if not border_size[border] then
      border_error(border)
    end
    local r = border_size[border]
    return r[1], r[2]
  end

  if 8 % #border ~= 0 then
    border_error(border)
  end

  --- @param id integer
  --- @return string
  local function elem(id)
    id = (id - 1) % #border + 1
    local e = border[id]
    if type(e) == 'table' then
      -- border specified as a table of <character, highlight group>
      return e[1]
    elseif type(e) == 'string' then
      -- border specified as a list of border characters
      return e
    end
    --- @diagnostic disable-next-line:missing-return
    border_error(border)
  end

  --- @param e string
  local function border_height(e)
    return #e > 0 and 1 or 0
  end

  local top, bottom = elem(2), elem(6)
  local height = border_height(top) + border_height(bottom)

  local right, left = elem(4), elem(8)
  local width = vim.fn.strdisplaywidth(right) + vim.fn.strdisplaywidth(left)

  return height, width
end

--- Splits string at newlines, optionally removing unwanted blank lines.
---
--- @param s string Multiline string
--- @param no_blank boolean? Drop blank lines for each @param/@return (except one empty line
--- separating each). Workaround for https://github.com/LuaLS/lua-language-server/issues/2333
local function split_lines(s, no_blank)
  s = string.gsub(s, '\r\n?', '\n')
  local lines = {}
  local in_desc = true -- Main description block, before seeing any @foo.
  for line in vim.gsplit(s, '\n', { plain = true, trimempty = true }) do
    local start_annotation = not not line:find('^ ?%@.?[pr]')
    in_desc = (not start_annotation) and in_desc or false
    if start_annotation and no_blank and not (lines[#lines] or ''):find('^%s*$') then
      table.insert(lines, '') -- Separate each @foo with a blank line.
    end
    if in_desc or not no_blank or not line:find('^%s*$') then
      table.insert(lines, line)
    end
  end
  return lines
end

local function create_window_without_focus()
  local prev = api.nvim_get_current_win()
  vim.cmd.new()
  local new = api.nvim_get_current_win()
  api.nvim_set_current_win(prev)
  return new
end

--- Replaces text in a range with new text.
---
--- CAUTION: Changes in-place!
---
---@deprecated
---@param lines string[] Original list of strings
---@param A [integer, integer] Start position; a 2-tuple of {line,col} numbers
---@param B [integer, integer] End position; a 2-tuple {line,col} numbers
---@param new_lines string[] list of strings to replace the original
---@return string[] The modified {lines} object
function M.set_lines(lines, A, B, new_lines)
  vim.deprecate('vim.lsp.util.set_lines()', 'nil', '0.12')
  -- 0-indexing to 1-indexing
  local i_0 = A[1] + 1
  -- If it extends past the end, truncate it to the end. This is because the
  -- way the LSP describes the range including the last newline is by
  -- specifying a line number after what we would call the last line.
  local i_n = math.min(B[1] + 1, #lines)
  if not (i_0 >= 1 and i_0 <= #lines + 1 and i_n >= 1 and i_n <= #lines) then
    error('Invalid range: ' .. vim.inspect({ A = A, B = B, #lines, new_lines }))
  end
  local prefix = ''
  local suffix = lines[i_n]:sub(B[2] + 1)
  if A[2] > 0 then
    prefix = lines[i_0]:sub(1, A[2])
  end
  local n = i_n - i_0 + 1
  if n ~= #new_lines then
    for _ = 1, n - #new_lines do
      table.remove(lines, i_0)
    end
    for _ = 1, #new_lines - n do
      table.insert(lines, i_0, '')
    end
  end
  for i = 1, #new_lines do
    lines[i - 1 + i_0] = new_lines[i]
  end
  if #suffix > 0 then
    local i = i_0 + #new_lines - 1
    lines[i] = lines[i] .. suffix
  end
  if #prefix > 0 then
    lines[i_0] = prefix .. lines[i_0]
  end
  return lines
end

--- @param fn fun(x:any):any[]
--- @return function
local function sort_by_key(fn)
  return function(a, b)
    local ka, kb = fn(a), fn(b)
    assert(#ka == #kb)
    for i = 1, #ka do
      if ka[i] ~= kb[i] then
        return ka[i] < kb[i]
      end
    end
    -- every value must have been equal here, which means it's not less than.
    return false
  end
end

--- Gets the zero-indexed lines from the given buffer.
--- Works on unloaded buffers by reading the file using libuv to bypass buf reading events.
--- Falls back to loading the buffer and nvim_buf_get_lines for buffers with non-file URI.
---
---@param bufnr integer bufnr to get the lines from
---@param rows integer[] zero-indexed line numbers
---@return table<integer, string>|string a table mapping rows to lines
local function get_lines(bufnr, rows)
  --- @type integer[]
  rows = type(rows) == 'table' and rows or { rows }

  -- This is needed for bufload and bufloaded
  bufnr = vim._resolve_bufnr(bufnr)

  local function buf_lines()
    local lines = {} --- @type table<integer,string>
    for _, row in ipairs(rows) do
      lines[row] = (api.nvim_buf_get_lines(bufnr, row, row + 1, false) or { '' })[1]
    end
    return lines
  end

  -- use loaded buffers if available
  if vim.fn.bufloaded(bufnr) == 1 then
    return buf_lines()
  end

  local uri = vim.uri_from_bufnr(bufnr)

  -- load the buffer if this is not a file uri
  -- Custom language server protocol extensions can result in servers sending URIs with custom schemes. Plugins are able to load these via `BufReadCmd` autocmds.
  if uri:sub(1, 4) ~= 'file' then
    vim.fn.bufload(bufnr)
    return buf_lines()
  end

  local filename = api.nvim_buf_get_name(bufnr)
  if vim.fn.isdirectory(filename) ~= 0 then
    return {}
  end

  -- get the data from the file
  local fd = uv.fs_open(filename, 'r', 438)
  if not fd then
    return ''
  end
  local stat = assert(uv.fs_fstat(fd))
  local data = assert(uv.fs_read(fd, stat.size, 0))
  uv.fs_close(fd)

  local lines = {} --- @type table<integer,true|string> rows we need to retrieve
  local need = 0 -- keep track of how many unique rows we need
  for _, row in pairs(rows) do
    if not lines[row] then
      need = need + 1
    end
    lines[row] = true
  end

  local found = 0
  local lnum = 0

  for line in string.gmatch(data, '([^\n]*)\n?') do
    if lines[lnum] == true then
      lines[lnum] = line
      found = found + 1
      if found == need then
        break
      end
    end
    lnum = lnum + 1
  end

  -- change any lines we didn't find to the empty string
  for i, line in pairs(lines) do
    if line == true then
      lines[i] = ''
    end
  end
  return lines --[[@as table<integer,string>]]
end

--- Gets the zero-indexed line from the given buffer.
--- Works on unloaded buffers by reading the file using libuv to bypass buf reading events.
--- Falls back to loading the buffer and nvim_buf_get_lines for buffers with non-file URI.
---
---@param bufnr integer
---@param row integer zero-indexed line number
---@return string the line at row in filename
local function get_line(bufnr, row)
  return get_lines(bufnr, { row })[row]
end

--- Position is a https://microsoft.github.io/language-server-protocol/specifications/specification-current/#position
---@param position lsp.Position
---@param position_encoding 'utf-8'|'utf-16'|'utf-32'
---@return integer
local function get_line_byte_from_position(bufnr, position, position_encoding)
  -- LSP's line and characters are 0-indexed
  -- Vim's line and columns are 1-indexed
  local col = position.character
  -- When on the first character, we can ignore the difference between byte and
  -- character
  if col > 0 then
    local line = get_line(bufnr, position.line) or ''
    return vim.str_byteindex(line, position_encoding, col, false)
  end
  return col
end


local function custom_symbols_to_items(symbols, bufnr, position_encoding)
  bufnr = vim._resolve_bufnr(bufnr)
  if position_encoding == nil then
    vim.notify_once(
      'symbols_to_items must be called with valid position encoding',
      vim.log.levels.WARN
    )
    position_encoding = vim.lsp.get_clients({ bufnr = bufnr })[1].offset_encoding
  end

  local items = {} --- @type vim.quickfix.entry[]
  for _, symbol in ipairs(symbols) do
    --- @type string?, lsp.Range?
    local filename, range

    if symbol.location then
      --- @cast symbol lsp.SymbolInformation
      filename = vim.uri_to_fname(symbol.location.uri)
      range = symbol.location.range
    elseif symbol.selectionRange then
      --- @cast symbol lsp.DocumentSymbol
      filename = api.nvim_buf_get_name(bufnr)
      range = symbol.selectionRange
    end

    if filename and range then
      local kind = protocol.SymbolKind[symbol.kind] or 'Unknown'

      local lnum = range['start'].line + 1
      local col = get_line_byte_from_position(bufnr, range['start'], position_encoding) + 1
      local end_lnum = range['end'].line + 1
      local end_col = get_line_byte_from_position(bufnr, range['end'], position_encoding) + 1

      local display_name = symbol.name
      if symbol.containerName and symbol.containerName ~= '' then
        display_name = symbol.containerName .. '::' .. symbol.name
      end

      items[#items + 1] = {
        filename = filename,
        lnum = lnum,
        col = col,
        end_lnum = end_lnum,
        end_col = end_col,
        kind = kind,
        text = '[' .. kind .. '] ' .. display_name,
      }
    end

    if symbol.children then
      vim.list_extend(items, custom_symbols_to_items(symbol.children, bufnr, position_encoding))
    end
  end

  return items
end


local function has_symbol_type_query(words)
	return  words[1] and (words[1]:sub(1,2) == ":f" or words[1]:sub(1,2) == ":m" or words[1]:sub(1,2) == ":t")
end


local function custom_get_workspace_symbols_requester(bufnr, opts)
  local cancel = function() end

  return function(prompt)
    local tx, rx = channel.oneshot()
    cancel()

    -- Split prompt into words, send only first word to LSP
    local words = vim.split(prompt, "%s+", { trimempty = true })
	local symbol_types = nil

	if #words > 1 then
		if has_symbol_type_query(words) then
			if words[1]:sub(1,2) == ":f" then
				symbol_types = { "function","method" }
			elseif words[1]:sub(1,2) == ":t" then
				symbol_types = { "type", "class", "struct" }
			elseif words[1]:sub(1,2) == ":m" then
				symbol_types = { "field" }
			end
			table.remove(words, 1)
		end
	end

	local lsp_query = words[1] or ""

    cancel = lsp.buf_request_all(bufnr, "workspace/symbol", { query = lsp_query }, tx)

    local results = rx() ---@type table<integer, {error: lsp.ResponseError?, result: lsp.WorkspaceSymbol?}>
    local locations = {} ---@type vim.quickfix.entry[]

    for client_id, client_res in pairs(results) do
      if client_res.error then
        utils.notify("lsp.workspace_symbols", { msg = client_res.error.message, level = "ERROR" })
      elseif client_res.result ~= nil then
        if nvim011 then
          local client = assert(lsp.get_client_by_id(client_id))
          --vim.list_extend(locations, lsp.util.symbols_to_items(client_res.result, bufnr, client.offset_encoding))
          vim.list_extend(locations, custom_symbols_to_items(client_res.result, bufnr, client.offset_encoding))
        else
          --vim.list_extend(locations, lsp.util.symbols_to_items(client_res.result, bufnr))
          vim.list_extend(locations, custom_symbols_to_items(client_res.result, bufnr))
        end
      end
    end

    if not vim.tbl_isempty(locations) then

	if #words > 1 or symbol_types then
		local filtered = {}
		for _, entry in ipairs(locations) do
			local ordinal_lower = entry.text:lower()

			local matches_type = true

			if symbol_types then
				local type = entry.kind:lower()
				matches_type = false
				for _, t in ipairs(symbol_types) do
					if type == t:lower() then
						matches_type = true
						break
					end
				end
			end

			if matches_type then
				local matches_all = true

				for i = 2, #words do
					local word = words[i]
					if not ordinal_lower:find(word:lower(), 1, true) then
						matches_all = false
						break
					end
				end

				if matches_all then
					table.insert(filtered, entry)
				end
			end
		end
		locations = filtered
	end

    end
    return locations
  end
end


local function first_word_sorter(opts)
	return sorters.Sorter:new {
		discard = true,
		scoring_function = function(_, prompt, entry)
			local words = vim.split(prompt, "%s+", { trimempty = true })
			if has_symbol_type_query(words) then
				table.remove(words, 1)
			end
			return opts.sorter:scoring_function(words[1], entry)
		end
	}
end


local custom_dynamic_workspace_symbols = function(opts)
  pickers
    .new(opts, {
      prompt_title = "LSP Dynamic Workspace Symbols",
      finder = finders.new_dynamic {
        entry_maker = opts.entry_maker or make_entry.gen_from_lsp_symbols(opts),
        fn = custom_get_workspace_symbols_requester(opts.bufnr, opts),
      },
      previewer = conf.qflist_previewer(opts),
      sorter = opts.sorter or sorters.highlighter_only(opts),
      attach_mappings = function(_, map)
        map("i", "<c-space>", actions.to_fuzzy_refine)
        return true
      end,
    })
    :find()
end

M.setup = function(config)
	vim.keymap.set('n', '<leader>os', function()
		custom_dynamic_workspace_symbols({
			bufnr = vim.api.nvim_get_current_buf(),
			symbols = {"struct","class","function","method","type"},
			sorter = first_word_sorter({
				sorter = require('telescope.sorters').get_fzy_sorter(),
			}),
			fname_width = 0.5,
			symbol_width=0.4,
			symbol_type_width = 0.1,
		})
		end, { desc = 'Grep word under cursor' })
	
	vim.keymap.set('n', '<leader>ox', function()
		local word = vim.fn.expand('<cword>')
		custom_dynamic_workspace_symbols({
			default_text = word,
			bufnr = vim.api.nvim_get_current_buf(),
			symbols = {"struct","class","function","method","type"},
			sorter = first_word_sorter({
				sorter = require('telescope.sorters').get_fzy_sorter(),
			}),
			fname_width = 0.5,
			symbol_width=0.4,
			symbol_type_width = 0.1,
		})
	end, { desc = 'Search symbol under cursor' })
end

return M
