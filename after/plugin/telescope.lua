local builtin = require('telescope.builtin')
local telescope = require('telescope')

-- Read search directories from SearchDirs.txt or use cwd
local function get_search_dirs()
  local search_dirs_file = vim.fn.getcwd() .. "/SearchDirs.txt"
  if vim.fn.filereadable(search_dirs_file) == 1 then
    local dirs = {}
    for line in io.lines(search_dirs_file) do
      local trimmed = line:match("^%s*(.-)%s*$")
      if trimmed ~= "" then
        table.insert(dirs, trimmed)
      end
    end
    return dirs
  else
    return { vim.fn.getcwd() }
  end
end

local search_dirs = get_search_dirs()

local trouble = require("trouble.sources.telescope")


telescope.setup({
	defaults = {
		file_ignore_patterns = { 
			"node_modules", 
			".git/", 
			"compile_commands.json",
		},
		theme = 'dropdown',
		layout_strategy = 'vertical',
		layout_config = { height = 0.95, width = 1000.0 },
		vimgrep_arguments = {
			'rg',
			'--no-heading',
			'--with-filename',
			'--line-number',
			'--column',
			'--smart-case',
		},
		lsp_dynamic_workspace_symbols = {
			sorter = require('telescope.sorters').get_fzy_sorter(),
			fname_width = 0.5,
			symbol_width = 0.4,
			symbol_type_width = 0.1,
			show_line   = true
		},
		layout_config = {
			preview_cutoff = 5
		},
		find_files = {
			fname_width = 0.5
		}
	},
	pickers = {
		find_files = {
			search_dirs = search_dirs,
		},
		live_grep = {
			search_dirs = search_dirs,
		}
	},
	extensions = {
		fzf = {
			fuzzy = true,                    -- false will only do exact matching
			override_generic_sorter = true,  -- override the generic sorter
			override_file_sorter = true,     -- override the file sorter
			case_mode = "smart_case",        -- or "ignore_case" or "respect_case"
			                                 -- the default case_mode is "smart_case"
		}
	}
})


require('telescope').load_extension('fzf')

require "mateusz.telescope.multigrep".setup({
	search_dirs = search_dirs
})

vim.keymap.set('n', '<leader>of', function()
	builtin.find_files({ sorter = require('telescope.sorters').get_fzy_sorter() })
end, { desc = 'Telescope find files' })

-- Search file under cursor
vim.keymap.set('n', '<leader>ov', function()
	local word = vim.fn.expand('<cword>')
	builtin.find_files({ default_text = word, sorter = require('telescope.sorters').get_fzy_sorter() })
end, { desc = 'Search symbol under cursor' })

vim.keymap.set('n', '<leader>ow', function()
	builtin.live_grep({
		additional_args = function()
			return { "--no-ignore-parent", "--one-file-system" }
		end
	})
end, { desc = 'Live Grep' })


require "mateusz.telescope.lsp_workspace_symbols".setup()


vim.keymap.set('n', '<leader>f', builtin.lsp_references, { desc = 'Find LSP references' })
vim.keymap.set('n', '<leader>m', function() builtin.lsp_document_symbols({ sorter = require('telescope.sorters').get_fzy_sorter(), fname_width = 0.5,symbol_width=0.4, symbol_type_width = 0.1 }) end, { desc = 'Document LSP symbols' })

vim.keymap.set('n', '<leader>or', function() require('telescope.builtin').buffers({ sort_lastused = true, ignore_current_buffer = true }) end, { desc = 'Find recent buffer' })

local notes_dir = vim.g.notes_dir

if notes_dir then
	vim.keymap.set('n', '<leader>on', function()
		builtin.find_files({ search_dirs = { notes_dir } })
	end, { desc = 'Find notes' })

	vim.keymap.set('n', '<leader>oh', function()
		builtin.live_grep({ search_dirs = { notes_dir } })
	end, { desc = 'Grep in Notes' })
end
