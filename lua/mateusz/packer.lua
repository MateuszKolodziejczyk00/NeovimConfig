vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
	use 'wbthomason/packer.nvim'

	use {
		'nvim-telescope/telescope.nvim',
		branch = 'master',
		requires = { {'nvim-lua/plenary.nvim'} }
	}

	use { 'nvim-telescope/telescope-fzf-native.nvim', run = 'cmake -S. -Bbuild -G "Visual Studio 17 2022" -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release' }

	use {
		"nvim-treesitter/nvim-treesitter",
		tag = "v0.10.0",
		run = ":TSUpdate"
	}
	use('nvim-treesitter/playground')

	-- command Autocompletion
	use {
		'gelguy/wilder.nvim',
		config = function()
			-- config goes here
		end,
	}

	use {
		'numToStr/Comment.nvim',
		config = function()
			require('Comment').setup()
		end
	}

	use {
		'guillemaru/perfnvim',
		opt = false,
		config = function()
			require('perfnvim').setup()

			vim.keymap.set("n", "<leader>pa", function() require("perfnvim").P4add() end, { noremap = true, silent = true, desc = "'p4 add' current buffer" })
			vim.keymap.set("n", "<leader>pe", function() require("perfnvim").P4edit() end, { noremap = true, silent = true, desc = "'p4 edit' current buffer" })
			--vim.keymap.set("n", "<leader>pR", ":!p4 revert -a %<CR>", { noremap = true, silent = true, desc = "Revert if unchanged" })
			vim.keymap.set("n", "<leader>pj", function() require("perfnvim").P4next() end, { noremap = true, silent = true, desc = "Jump to next changed line" })
			vim.keymap.set("n", "<leader>pk", function() require("perfnvim").P4prev() end, { noremap = true, silent = true, desc = "Jump to previous changed line" })
			vim.keymap.set("n", "<leader>pr", function() require("perfnvim").P4opened() end, { noremap = true, silent = true, desc = "'p4 opened' (telescope)" })
			vim.keymap.set("n", "<leader>pg", function() require("perfnvim").P4grep() end, { noremap = true, silent = true, desc = "grep p4 files" })
		end
	}

	use({
		"kylechui/nvim-surround",
		tag = "*", -- Use for stability; omit to use `main` branch for the latest features
		config = function()
			require("nvim-surround").setup({
				-- Configuration here, or leave empty to use defaults
			})
		end
	})

	use {
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = function()
			require("nvim-autopairs").setup {}
		end
	}

	use {
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
	}

	use("mbbill/undotree")

	use {
		'VonHeikemen/lsp-zero.nvim',
		branch = 'v1.x',
		requires = {
			-- LSP Support
			{'neovim/nvim-lspconfig'},
			{'williamboman/mason.nvim'},
			{'williamboman/mason-lspconfig.nvim'},

			-- Autocompletion
			{'hrsh7th/nvim-cmp'},
			{'hrsh7th/cmp-buffer'},
			{'hrsh7th/cmp-path'},
			{'saadparwaiz1/cmp_luasnip'},
			{'hrsh7th/cmp-nvim-lsp'},
			{'hrsh7th/cmp-nvim-lua'},
			-- Snippets
			{'L3MON4D3/LuaSnip'},
			{'rafamadriz/friendly-snippets'},
		}
	}

	use {
		"folke/trouble.nvim",
		requires = "kyazdani42/nvim-web-devicons",
		config = function()
			require("trouble").setup {
				-- your configuration comes here
				-- or leave it empty to use the default settings
				-- refer to the configuration section below
			}
		end
	}

	use {
		'chikko80/error-lens.nvim',
		ft = {"cpp", "h"},
		requires = {'nvim-telescope/telescope.nvim'},
		config = function()
			require("error-lens").setup({
				prefix = 8,
				auto_adjust = {
					enable = true,
					fallback_bg_color = "#000000", -- REQUIRED when enable = true
				}
			})
		end
	}

	use({
		'sainnhe/gruvbox-material',
		config = function()
			vim.cmd[[colorscheme gruvbox-material]]
		end
	})

	use {'kevinhwang91/nvim-bqf'}

	use {'sphamba/smear-cursor.nvim'}

	use {'easymotion/vim-easymotion'}

	use {'mikavilpas/yazi.nvim'}

	use {
		'nvim-lualine/lualine.nvim',
		requires = { 'nvim-tree/nvim-web-devicons', opt = true }
	}

	use { 'tommcdo/vim-lion' }

	use { 'wellle/targets.vim' }

	use {
		'nvimdev/dashboard-nvim',
		event = 'VimEnter',
		config = function()
			require('dashboard').setup{
				-- config
			}
		end,
		requires = {'nvim-tree/nvim-web-devicons'}
	}

	use {
		"mboyov/pane-resizer.nvim",
		config = function()
			require("pane_resizer").setup({
				FOCUSED_WIDTH_PERCENTAGE = 0.7,	-- Optional: focused window width (default: 0.7)
			})
		end,
	}

	use {
		'github/copilot.vim',
		--config = function()
		--	require('copilot').setup({
		--		copilot_model = 'gpt-4o'
		--	})
		--end
	}

	use {
		'CopilotC-Nvim/CopilotChat.nvim',
		--config = function()
		--	require("CopilotChat").setup({
		--		model = 'claude-3.5-sonnet'
		--	})
		--end
	}

	use { "ThePrimeagen/99" }

	use {
		'folke/todo-comments.nvim',
		requires = "nvim-lua/plenary.nvim",
		config = function()
			require("todo-comments").setup()
		end
	}

	use {
		"rmagatti/auto-session",
		config = function()
			require("auto-session").setup()
		end
	}
end)
