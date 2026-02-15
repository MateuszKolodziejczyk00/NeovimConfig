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

	use({
		"stevearc/oil.nvim",
		config = function()
			require("oil").setup()
		end,
	})

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

	use 'motiongorilla/p4nvim'

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
		'github/copilot.vim',
		config = function()
			require('copilot').setup({
				copilot_model = 'gpt-4o'
			})
		end
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
end)
