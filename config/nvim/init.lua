-- ======================================================================================
-- NEOVIM CONFIGURATION
-- ======================================================================================

-- ======================================================================================
-- UTILITY FUNCTIONS
-- ======================================================================================

-- Returns true if a file exists
function FileExists(file)
	local f = io.open(file, "rb")
	if f then
		f:close()
	end
	return f ~= nil
end

-- Get the value of the module name from go.mod in PWD
function GetGoModuleName()
	if not FileExists("go.mod") then
		return nil
	end
	for line in io.lines("go.mod") do
		if vim.startswith(line, "module") then
			local items = vim.split(line, " ")
			local module_name = vim.trim(items[2])
			return module_name
		end
	end
	return nil
end

-- ======================================================================================
-- AUTOCOMMANDS
-- ======================================================================================

-- Highlight when yanking text
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking text",
	group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- Auto-reload files when they change externally (if no unsaved changes)
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
	pattern = "*",
	callback = function()
		if vim.fn.mode() ~= "c" then -- Don't check when in command mode
			vim.cmd("checktime")
		end
	end,
	desc = "Check for external file changes",
})

-- Notify when file is automatically reloaded
vim.api.nvim_create_autocmd("FileChangedShellPost", {
	pattern = "*",
	callback = function()
		vim.notify("File changed on disk. Buffer reloaded!", vim.log.levels.INFO, { title = "File Reload" })
	end,
	desc = "Notify when file is reloaded from disk",
})

-- Handle save attempts in Neo-tree (treat as :wall)
vim.api.nvim_create_autocmd("FileType", {
	pattern = "neo-tree",
	callback = function()
		vim.keymap.set("n", "<leader>w", "<cmd>wall<cr>", { buffer = true, desc = "Save all files" })
	end,
	desc = "Override save in Neo-tree to save all files",
})

-- Set conceal level for Obsidian markdown files
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
	pattern = vim.fn.expand("~") .. "/Notebook/*.md",
	callback = function()
		vim.opt_local.conceallevel = 2
	end,
	desc = "Set conceal level to 2 for Obsidian notes",
})

-- ======================================================================================
-- CORE VIM OPTIONS
-- ======================================================================================

-- Leader keys
vim.g.mapleader = " " -- Set leader key to space
vim.g.maplocalleader = " " -- Set local leader key to space

-- Schedule a sync of the OS clipboard after `UiEnter`
vim.schedule(function()
	vim.opt.clipboard = "unnamedplus"
end)

-- File handling
vim.opt.backup = false -- Don't make a backup before overwriting a file
vim.opt.writebackup = false -- Don't backup file while editing
vim.opt.swapfile = false -- Don't write swap files for new buffers
vim.opt.updatecount = 0 -- Don't write swap files after some number of updates
vim.opt.undofile = true -- Save undo history
vim.opt.autoread = true -- Enable automatic reading of files changed outside Vim
vim.opt.exrc = true -- Enable project-specific .nvim.lua configuration files

-- Backup and temporary directories
vim.opt.backupdir = {
	"~/.vim-tmp",
	"~/.tmp",
	"~/tmp",
	"/var/tmp",
	"/tmp",
}
vim.opt.directory = {
	"~/.vim-tmp",
	"~/.tmp",
	"~/tmp",
	"/var/tmp",
	"/tmp",
}

-- History and memory
vim.opt.history = 1000 -- Store the last 1000 commands entered
vim.opt.updatetime = 300 -- Timeout to write to swap file

-- Input and navigation
vim.opt.backspace = { "indent", "eol", "start" } -- Make backspace behave as expected
vim.opt.mouse = "a" -- Set mouse mode to all modes

-- Search behavior
vim.opt.ignorecase = true -- Ignore case in searching unless \C or capitals found
vim.opt.smartcase = true
vim.opt.hlsearch = true -- Highlight search results
vim.opt.incsearch = true -- Incremental search
vim.opt.lazyredraw = false -- Don't redraw while executing macros
vim.opt.magic = true -- Use magic for regex

-- Use ripgrep for searching if available
if vim.fn.executable("rg") then
	vim.opt.grepprg = "rg --vimgrep --noheading"
	vim.opt.grepformat = "%f:%l:%c:%m,%f:%l:%m"
end

-- ======================================================================================
-- PLUGIN MANAGER (LAZY.NVIM)
-- ======================================================================================

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

-- ======================================================================================
-- PLUGINS
-- ======================================================================================

require("lazy").setup({
	spec = {
		-- =============================================================================
		-- LANGUAGE SUPPORT
		-- =============================================================================

		-- Treesitter - Syntax highlighting and parsing
		{ "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },

		-- Language-specific plugins
		"evanleck/vim-svelte", -- Svelte support
		"wuelnerdotexe/vim-astro", -- Astro support
		"tpope/vim-sleuth", -- Detect tabstop and shiftwidth automatically

		-- =============================================================================
		-- LSP AND COMPLETION
		-- =============================================================================

		-- LSP Configuration
		{
			"neovim/nvim-lspconfig",
			dependencies = {
				{ "williamboman/mason.nvim", config = true },
				"williamboman/mason-lspconfig.nvim",
				"whoissethdaniel/mason-tool-installer.nvim",
				{ "j-hui/fidget.nvim", opts = {} }, -- LSP status updates
				"hrsh7th/cmp-nvim-lsp", -- LSP capabilities for nvim-cmp
			},
			config = function()
				-- LSP attach function
				vim.api.nvim_create_autocmd("LspAttach", {
					group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
					callback = function(event)
						local map = function(keys, func, desc, mode)
							mode = mode or "n"
							vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
						end

						-- Navigation
						map("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
						map("gr", vim.lsp.buf.references, "[G]oto [R]eferences")
						map("gi", vim.lsp.buf.implementation, "[G]oto [I]mplementation")
						map("gt", vim.lsp.buf.type_definition, "[G]oto [T]ype definition")

						-- Telescope integration
						map("<Leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
						map(
							"<Leader>ws",
							require("telescope.builtin").lsp_dynamic_workspace_symbols,
							"[W]orkspace [S]ymbols"
						)

						-- Actions
						map("K", vim.lsp.buf.hover, "[H]over Documentation")
						map("<Leader>r", vim.lsp.buf.rename, "[R]ename")
						map("<Leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction", { "n", "x" })
					end,
				})

				-- Diagnostic configuration with Nerd Font icons
				vim.g.have_nerd_font = true
				if vim.g.have_nerd_font then
					local signs = { error = "󰅚", warn = "󰀪", info = "󰋽", hint = "󰌶" }
					local diagnostic_signs = {}
					for type, icon in pairs(signs) do
						diagnostic_signs[vim.diagnostic.severity[type:upper()]] = icon
					end
					vim.diagnostic.config({
						signs = { text = diagnostic_signs },
						virtual_text = {
							prefix = "●",
							spacing = 4,
						},
						float = {
							focusable = false,
							style = "minimal",
							border = "rounded",
							source = true,
							header = "",
							prefix = "",
						},
						severity_sort = true,
						update_in_insert = false,
					})
				end

				-- LSP server capabilities
				local capabilities = vim.lsp.protocol.make_client_capabilities()
				capabilities =
					vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

				-- Language servers configuration
				local servers = {
					lua_ls = {
						settings = {
							Lua = {
								completion = {
									callSnippet = "Replace",
								},
							},
						},
					},
				}

				-- Mason setup
				require("mason").setup()

				local ensure_installed = vim.tbl_keys(servers or {})
				vim.list_extend(ensure_installed, { "stylua" })
				require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

				require("mason-lspconfig").setup({
					ensure_installed = { "lua_ls", "rust_analyzer", "denols", "ts_ls" },
					automatic_installation = true,
					handlers = {
						function(server_name)
							local server = servers[server_name] or {}
							server.capabilities =
								vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
							require("lspconfig")[server_name].setup(server)
						end,
					},
				})

				-- TypeScript/Deno LSP configuration
				local lspconfig = require("lspconfig")

				lspconfig.denols.setup({
					root_dir = lspconfig.util.root_pattern("deno.json", "deno.jsonc"),
					init_options = {
						enable = true,
						lint = true,
						unstable = true,
					},
				})

				lspconfig.ts_ls.setup({
					root_dir = lspconfig.util.root_pattern("package.json"),
					on_attach = function(client, bufnr)
						local buffer_path = vim.api.nvim_buf_get_name(bufnr)
						if lspconfig.util.root_pattern("deno.json", "deno.jsonc")(buffer_path) then
							client.stop()
							return
						end
					end,
				})

				-- TailwindCSS with CVA support
				require("lspconfig").tailwindcss.setup({
					settings = {
						tailwindCSS = {
							experimental = {
								classRegex = {
									{ "cva\\(((?:[^()]|\\([^()]*\\))*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]" },
									{ "cx\\(((?:[^()]|\\([^()]*\\))*)\\)", "(?:'|\"|`)([^']*)(?:'|\"|`)" },
								},
							},
						},
					},
				})
			end,
		},

		-- Completion engine
		{
			"hrsh7th/nvim-cmp",
			event = "InsertEnter",
			dependencies = {
				{
					"L3MON4D3/LuaSnip",
					build = (function()
						if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
							return
						end
						return "make install_jsregexp"
					end)(),
					dependencies = {
						{
							"rafamadriz/friendly-snippets",
							config = function()
								require("luasnip.loaders.from_vscode").lazy_load()
							end,
						},
					},
				},
				"saadparwaiz1/cmp_luasnip",
				"hrsh7th/cmp-nvim-lsp",
				"hrsh7th/cmp-path",
			},
			config = function()
				local cmp = require("cmp")
				local luasnip = require("luasnip")
				luasnip.config.setup({})

				cmp.setup({
					snippet = {
						expand = function(args)
							luasnip.lsp_expand(args.body)
						end,
					},
					completion = { completeopt = "menu,menuone,noinsert" },
					mapping = cmp.mapping.preset.insert({
						["<Tab>"] = cmp.mapping.confirm({ select = true }),
						["<S-Tab>"] = cmp.mapping.select_prev_item(),
						["<CR>"] = cmp.mapping.confirm({ select = true }),
						["<C-Space>"] = cmp.mapping.complete({}),
						["<C-l>"] = cmp.mapping(function()
							if luasnip.expand_or_locally_jumpable() then
								luasnip.expand_or_jump()
							end
						end, { "i", "s" }),
						["<C-h>"] = cmp.mapping(function()
							if luasnip.locally_jumpable(-1) then
								luasnip.jump(-1)
							end
						end, { "i", "s" }),
					}),
					sources = {
						{ name = "lazydev", group_index = 0 },
						{ name = "nvim_lsp" },
						{ name = "luasnip" },
						{ name = "path" },
					},
				})

				-- Command line completion
				cmp.setup.cmdline("/", {
					mapping = cmp.mapping.preset.cmdline(),
					sources = { { name = "buffer" } },
				})

				cmp.setup.cmdline(":", {
					mapping = cmp.mapping.preset.cmdline(),
					sources = cmp.config.sources({
						{ name = "path" },
					}, {
						{ name = "cmdline" },
					}),
				})
			end,
		},

		-- Lua development support
		{
			"folke/lazydev.nvim",
			ft = "lua",
			opts = {
				library = {
					{ path = "luvit-meta/library", words = { "vim%.uv" } },
				},
			},
		},
		{ "bilal2453/luvit-meta", lazy = true },

		-- =============================================================================
		-- AI ASSISTANCE
		-- =============================================================================

		-- GitHub Copilot
		{
			"zbirenbaum/copilot.lua",
			dependencies = { "zbirenbaum/copilot-cmp" },
			opts = {
				suggestion = {
					enabled = true,
					auto_trigger = true,
					keymap = {
						accept = "<Right>",
						accept_word = false,
						accept_line = false,
						next = "<M-]>",
						prev = "<M-[>",
						dismiss = "<C-]>",
					},
				},
				panel = { enabled = false },
			},
		},

		-- =============================================================================
		-- FILE MANAGEMENT AND NAVIGATION
		-- =============================================================================

		-- File explorer
		{
			"nvim-neo-tree/neo-tree.nvim",
			branch = "v3.x",
			dependencies = {
				"nvim-lua/plenary.nvim",
				"nvim-tree/nvim-web-devicons",
				"MunifTanjim/nui.nvim",
			},
		},

		-- Fuzzy finder
		{
			"nvim-telescope/telescope.nvim",
			event = "VimEnter",
			branch = "0.1.x",
			dependencies = {
				"nvim-lua/plenary.nvim",
				{
					"nvim-telescope/telescope-fzf-native.nvim",
					build = "make",
					cond = function()
						return vim.fn.executable("make") == 1
					end,
				},
				{ "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
			},
			config = function()
				require("telescope").setup({
					extensions = {},
				})

				-- Enable telescope extensions
				pcall(require("telescope").load_extension, "fzf")

				-- Keybindings
				local builtin = require("telescope.builtin")
				vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "[S]earch [H]elp" })
				vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "[S]earch [K]eymaps" })
				vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "[S]earch [F]iles" })
				vim.keymap.set("n", "<leader>ss", builtin.builtin, { desc = "[S]earch [S]elect Telescope" })
				vim.keymap.set("n", "<leader>sw", builtin.grep_string, { desc = "[S]earch current [W]ord" })
				vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "[S]earch by [G]rep" })
				vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
				vim.keymap.set("n", "<leader>sr", builtin.resume, { desc = "[S]earch [R]esume" })
				vim.keymap.set("n", "<leader>s.", builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
				vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "[ ] Find existing buffers" })

				-- Advanced search functions
				vim.keymap.set("n", "<leader>/", function()
					builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
						winblend = 10,
						previewer = false,
					}))
				end, { desc = "[/] Fuzzily search in current buffer" })

				vim.keymap.set("n", "<leader>s/", function()
					builtin.live_grep({
						grep_open_files = true,
						prompt_title = "Live Grep in Open Files",
					})
				end, { desc = "[S]earch [/] in Open Files" })

				vim.keymap.set("n", "<leader>sn", function()
					builtin.find_files({ cwd = vim.fn.stdpath("config") })
				end, { desc = "[S]earch [N]eovim files" })
			end,
		},

		-- Enhanced navigation
		{
			"folke/flash.nvim",
			event = "VeryLazy",
			opts = {
				search = {
					multi_window = true,
					forward = true,
					wrap = true,
					incremental = false,
				},
				jump = {
					jumplist = true,
					pos = "start",
					history = false,
					register = false,
					nohlsearch = false,
					autojump = false,
				},
				label = {
					uppercase = true,
					exclude = "",
					current = true,
					after = true,
					before = false,
					style = "overlay",
					reuse = "lowercase",
					distance = true,
					min_pattern_length = 0,
					rainbow = {
						enabled = false,
						shade = 5,
					},
				},
				highlight = {
					backdrop = true,
					matches = true,
					priority = 5000,
					groups = {
						match = "FlashMatch",
						current = "FlashCurrent",
						backdrop = "FlashBackdrop",
						label = "FlashLabel",
					},
				},
				prompt = {
					enabled = true,
					prefix = { { "⚡", "FlashPromptIcon" } },
					win_config = {
						relative = "editor",
						width = 1,
						height = 1,
						row = -1,
						col = 0,
						zindex = 1000,
					},
				},
			},
			keys = {
				{
					"<leader>j",
					mode = { "n", "x", "o" },
					function()
						require("flash").jump()
					end,
					desc = "Flash Jump",
				},
				{
					"<leader>J",
					mode = { "n", "o", "x" },
					function()
						require("flash").treesitter()
					end,
					desc = "Flash Treesitter",
				},
				{
					"r",
					mode = "o",
					function()
						require("flash").remote()
					end,
					desc = "Remote Flash",
				},
				{
					"R",
					mode = { "o", "x" },
					function()
						require("flash").treesitter_search()
					end,
					desc = "Treesitter Search",
				},
				{
					"<c-s>",
					mode = { "c" },
					function()
						require("flash").toggle()
					end,
					desc = "Toggle Flash Search",
				},
			},
		},

		-- =============================================================================
		-- GIT INTEGRATION
		-- =============================================================================

		-- Git signs and hunk management
		{
			"lewis6991/gitsigns.nvim",
			opts = {
				signs = {
					add = { text = "│" },
					change = { text = "│" },
					delete = { text = "_" },
					topdelete = { text = "-" },
					changedelete = { text = ">" },
				},
				signs_staged = {
					add = { text = "┃" },
					change = { text = "┃" },
					delete = { text = "▁" },
					topdelete = { text = "▔" },
					changedelete = { text = "▌" },
				},
				signs_staged_enable = true,
				on_attach = function(bufnr)
					local gitsigns = require("gitsigns")

					local function map(mode, l, r, opts)
						opts = opts or {}
						opts.buffer = bufnr
						vim.keymap.set(mode, l, r, opts)
					end

					-- Navigation
					map("n", "]c", function()
						if vim.wo.diff then
							vim.cmd.normal({ "]c", bang = true })
						else
							gitsigns.nav_hunk("next")
						end
					end, { desc = "Next hunk" })

					map("n", "[c", function()
						if vim.wo.diff then
							vim.cmd.normal({ "[c", bang = true })
						else
							gitsigns.nav_hunk("prev")
						end
					end, { desc = "Previous hunk" })

					-- Navigate specifically to unstaged hunks
					map("n", "]h", function()
						gitsigns.nav_hunk("next", { target = "unstaged" })
					end, { desc = "Next unstaged hunk" })

					map("n", "[h", function()
						gitsigns.nav_hunk("prev", { target = "unstaged" })
					end, { desc = "Previous unstaged hunk" })

					-- Navigate specifically to staged hunks
					map("n", "]H", function()
						gitsigns.nav_hunk("next", { target = "staged" })
					end, { desc = "Next staged hunk" })

					map("n", "[H", function()
						gitsigns.nav_hunk("prev", { target = "staged" })
					end, { desc = "Previous staged hunk" })

					-- Actions
					map("n", "<leader>Hs", gitsigns.stage_hunk, { desc = "Stage hunk" })
					map("n", "<leader>Hr", gitsigns.reset_hunk, { desc = "Reset hunk" })
					map("v", "<leader>Hs", function()
						gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
					end, { desc = "Stage hunk" })
					map("v", "<leader>Hr", function()
						gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
					end, { desc = "Reset hunk" })
					map("n", "<leader>HS", gitsigns.stage_buffer, { desc = "Stage buffer" })
					map("n", "<leader>Hu", function()
						gitsigns.stage_hunk({ staged = true })
					end, { desc = "Undo stage hunk" })
					map("n", "<leader>HR", gitsigns.reset_buffer, { desc = "Reset buffer" })
					map("n", "<leader>Hp", gitsigns.preview_hunk, { desc = "Preview hunk" })
					map("n", "<leader>Hb", function()
						gitsigns.blame_line({ full = true })
					end, { desc = "Blame line" })
					map("n", "<leader>Htb", gitsigns.toggle_current_line_blame, { desc = "Toggle line blame" })
					map("n", "<leader>Hd", gitsigns.diffthis, { desc = "Diff this" })
					map("n", "<leader>HD", function()
						gitsigns.diffthis("~")
					end, { desc = "Diff this ~" })
					map("n", "<leader>Htd", gitsigns.preview_hunk_inline, { desc = "Preview hunk inline" })

					-- Text object
					map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "Select hunk" })
				end,
			},
		},

		-- Git commands
		"tpope/vim-fugitive",

		-- Git conflict resolution
		{ "akinsho/git-conflict.nvim", version = "*", config = true },

		-- =============================================================================
		-- DEBUGGING
		-- =============================================================================

		-- Debug Adapter Protocol
		{
			"mfussenegger/nvim-dap",
			dependencies = {
				"rcarriga/nvim-dap-ui",
				"nvim-neotest/nvim-nio",
				"williamboman/mason.nvim",
				"jay-babu/mason-nvim-dap.nvim",
				"leoluz/nvim-dap-go",
			},
			keys = {
				{
					"<F5>",
					function()
						require("dap").continue()
					end,
					desc = "Debug: Start/Continue",
				},
				{
					"<F1>",
					function()
						require("dap").step_into()
					end,
					desc = "Debug: Step Into",
				},
				{
					"<F2>",
					function()
						require("dap").step_over()
					end,
					desc = "Debug: Step Over",
				},
				{
					"<F3>",
					function()
						require("dap").step_out()
					end,
					desc = "Debug: Step Out",
				},
				{
					"<leader>b",
					function()
						require("dap").toggle_breakpoint()
					end,
					desc = "Debug: Toggle Breakpoint",
				},
				{
					"<leader>B",
					function()
						require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
					end,
					desc = "Debug: Set Breakpoint",
				},
			},
			config = function()
				local dap = require("dap")
				local dapui = require("dapui")

				require("mason-nvim-dap").setup({
					automatic_installation = true,
					handlers = {},
					ensure_installed = { "delve" },
				})

				vim.keymap.set("n", "<F7>", dapui.toggle, { desc = "Debug: See last session result." })

				dapui.setup({
					icons = { expanded = "▾", collapsed = "▸", current_frame = "*" },
					controls = {
						enabled = true,
						element = "repl",
						icons = {
							pause = "⏸",
							play = "▶",
							step_into = "⏎",
							step_over = "⏭",
							step_out = "⏮",
							step_back = "b",
							run_last = "▶▶",
							terminate = "⏹",
							disconnect = "⏏",
						},
					},
					mappings = {},
					element_mappings = {},
					expand_lines = true,
					force_buffers = true,
					layouts = {
						{
							elements = {
								{ id = "scopes", size = 0.25 },
								{ id = "breakpoints", size = 0.25 },
								{ id = "stacks", size = 0.25 },
								{ id = "watches", size = 0.25 },
							},
							size = 40,
							position = "left",
						},
						{
							elements = {
								{ id = "repl", size = 0.5 },
								{ id = "console", size = 0.5 },
							},
							size = 10,
							position = "bottom",
						},
					},
					floating = {
						max_height = nil,
						max_width = nil,
						border = "single",
						mappings = {
							close = { "q", "<Esc>" },
						},
					},
					render = {
						max_type_length = nil,
						max_value_lines = 100,
						indent = 2,
					},
				})

				dap.listeners.after.event_initialized["dapui_config"] = dapui.open
				dap.listeners.before.event_terminated["dapui_config"] = dapui.close
				dap.listeners.before.event_exited["dapui_config"] = dapui.close

				require("dap-go").setup({
					delve = {
						detached = vim.fn.has("win32") == 0,
					},
				})
			end,
		},

		-- =============================================================================
		-- DIAGNOSTICS AND TROUBLE
		-- =============================================================================

		-- Better diagnostics list
		{
			"folke/trouble.nvim",
			dependencies = { "nvim-tree/nvim-web-devicons" },
			opts = {
				auto_close = true,
				auto_preview = true,
				auto_refresh = true,
				focus = true,
			},
		},

		-- =============================================================================
		-- FORMATTING AND LINTING
		-- =============================================================================

		-- Auto-formatting
		{
			"stevearc/conform.nvim",
			event = { "BufWritePre" },
			cmd = { "ConformInfo" },
			keys = {
				{
					"<leader>cf",
					function()
						require("conform").format({ async = true, lsp_format = "fallback" })
					end,
					mode = "",
					desc = "[C]onform [F]ormat buffer",
				},
			},
			opts = {
				notify_on_error = false,
				format_on_save = function(bufnr)
					local disable_filetypes = { c = true, cpp = true }
					local lsp_format_opt
					if disable_filetypes[vim.bo[bufnr].filetype] then
						lsp_format_opt = "never"
					else
						lsp_format_opt = "fallback"
					end
					return {
						timeout_ms = 500,
						lsp_format = lsp_format_opt,
					}
				end,
				formatters_by_ft = {
					lua = { "stylua" },
					python = { "isort", "black" },
					javascript = { "prettierd", "prettier", stop_after_first = true },
				},
			},
		},

		-- =============================================================================
		-- UI ENHANCEMENTS
		-- =============================================================================

		-- Color scheme
		{ "catppuccin/nvim", name = "catppuccin", priority = 1000 },

		-- Indent guides
		{
			"lukas-reineke/indent-blankline.nvim",
			main = "ibl",
			opts = {},
		},

		-- Enhanced status line and UI components
		{
			"echasnovski/mini.nvim",
			config = function()
				require("mini.ai").setup({ n_lines = 500 })
				require("mini.surround").setup()
				require("mini.align").setup()

				local statusline = require("mini.statusline")
				statusline.setup({
					use_icons = vim.g.have_nerd_font,
					content = {
						active = function()
							local mode, mode_hl = statusline.section_mode({ trunc_width = 120 })
							local git = statusline.section_git({ trunc_width = 40 })
							local diff = statusline.section_diff({ trunc_width = 75 })
							local diagnostics = statusline.section_diagnostics({ trunc_width = 75 })
							local lsp = statusline.section_lsp({ trunc_width = 75 })
							local filename = statusline.section_filename({ trunc_width = 140 })
							local fileinfo = statusline.section_fileinfo({ trunc_width = 120 })
							local location = "%2l:%-2v"
							local search = statusline.section_searchcount({ trunc_width = 75 })

							return statusline.combine_groups({
								{ hl = mode_hl, strings = { mode } },
								{ hl = "MiniStatuslineDevinfo", strings = { git, diff, diagnostics, lsp } },
								"%<", -- Mark general truncate point
								{ hl = "MiniStatuslineFilename", strings = { filename } },
								"%=", -- End left alignment
								{ hl = "MiniStatuslineFileinfo", strings = { fileinfo } },
								{ hl = mode_hl, strings = { search, location } },
							})
						end,
					},
				})
			end,
		},

		-- =============================================================================
		-- PRODUCTIVITY TOOLS
		-- =============================================================================

		-- Auto-pairs
		{
			"windwp/nvim-autopairs",
			event = "InsertEnter",
			config = true,
		},

		-- Text wrapping
		{
			"andrewferrier/wrapping.nvim",
			config = function()
				require("wrapping").setup({
					set_nvim_opt_defaults = true,
					softener = { text = true, comment = true, default = 0 },
					create_commands = true,
					create_keymaps = true,
					auto_set_mode_heuristically = true,
					auto_set_mode_filetype_allowlist = { "markdown" },
					auto_set_mode_filetype_denylist = {},
					buftype_allowlist = {},
					excluded_treesitter_queries = {},
					notify_on_switch = false,
					log_path = vim.fn.stdpath("data") .. "/wrapping.log",
				})
			end,
		},

		-- Todo comments highlighting
		{
			"folke/todo-comments.nvim",
			event = "VimEnter",
			dependencies = { "nvim-lua/plenary.nvim" },
			opts = { signs = false },
		},

		-- =============================================================================
		-- DOCUMENTATION AND NOTES
		-- =============================================================================

		-- Obsidian integration
		{
			"t-eckert/obsidian.nvim",
			branch = "t-eckert/add-set-checkbox",
			lazy = true,
			ft = "markdown",
			event = {
				"BufReadPre " .. vim.fn.expand("~") .. "/Notebook/**.md",
				"BufNewFile " .. vim.fn.expand("~") .. "/Notebook/**.md",
			},
			dependencies = { "nvim-lua/plenary.nvim" },
			opts = {
				workspaces = {
					{
						name = "Notebook",
						path = "~/Notebook",
					},
				},
				daily_notes = {
					folder = "Log",
				},
				templates = {
					folder = "./+Templates",
				},
			ui = {
				enable = true,
				update_debounce = 200,
				max_file_length = 5000,
				checkboxes = {
					[" "] = { char = "󰄱", hl_group = "ObsidianTodo" },
					["x"] = { char = "", hl_group = "ObsidianDone" },
					[">"] = { char = "", hl_group = "ObsidianRightArrow" },
					["~"] = { char = "󰰱", hl_group = "ObsidianTilde" },
					["!"] = { char = "", hl_group = "ObsidianImportant" },
				},
				external_link_icon = { char = "", hl_group = "ObsidianExtLinkIcon" },
				reference_text = { hl_group = "ObsidianRefText" },
				highlight_text = { hl_group = "ObsidianHighlightText" },
				tags = { hl_group = "ObsidianTag" },
				block_ids = { hl_group = "ObsidianBlockID" },
				hl_groups = {
					ObsidianTodo = { bold = true, fg = "#f78c6c" },
					ObsidianDone = { bold = true, fg = "#89ddff" },
					ObsidianRightArrow = { bold = true, fg = "#f78c6c" },
					ObsidianTilde = { bold = true, fg = "#ff5370" },
					ObsidianImportant = { bold = true, fg = "#d73128" },
					ObsidianBullet = { bold = true, fg = "#89ddff" },
					ObsidianRefText = { underline = true, fg = "#c792ea" },
					ObsidianExtLinkIcon = { fg = "#c792ea" },
					ObsidianTag = { italic = true, fg = "#89ddff" },
					ObsidianBlockID = { italic = true, fg = "#89ddff" },
					ObsidianHighlightText = { bg = "#75662e" },
				},
			},
			},
		},

		-- Markdown table formatting
		{
			"Kicamon/markdown-table-mode.nvim",
			config = function()
				require("markdown-table-mode").setup()
			end,
		},

		-- Helper functions for Lua
		"nvim-lua/plenary.nvim",
	},

	-- Lazy.nvim configuration
	checker = {
		enabled = true,
		notify = false,
		frequency = 3600,
	},
	change_detection = {
		enabled = true,
		notify = false,
	},
	install = {
		missing = true,
		colorscheme = { "catppuccin" },
	},
	ui = {
		size = { width = 0.8, height = 0.8 },
		wrap = true,
		border = "rounded",
		backdrop = 60,
		title = "Lazy",
		title_pos = "center",
		pills = true,
		icons = {
			cmd = "⌘",
			config = "🛠",
			event = "📅",
			ft = "📂",
			init = "⚙",
			keys = "🗝",
			plugin = "🔌",
			runtime = "💻",
			require = "🌙",
			source = "📄",
			start = "🚀",
			task = "📌",
			lazy = "💤 ",
		},
	},
	performance = {
		cache = {
			enabled = true,
		},
		reset_packpath = true,
		rtp = {
			reset = true,
			paths = {},
			disabled_plugins = {
				"gzip",
				"matchit",
				"matchparen",
				"netrwPlugin",
				"tarPlugin",
				"tohtml",
				"tutor",
				"zipPlugin",
			},
		},
	},
	lockfile = "~/Repos/github.com/t-eckert/dotfiles/config/nvim/lazy-lock.json",
})

-- ======================================================================================
-- APPEARANCE AND COLORSCHEME
-- ======================================================================================

-- Catppuccin setup
require("catppuccin").setup({
	flavour = "mocha",
	background = {
		light = "latte",
		dark = "mocha",
	},
	transparent_background = true,
	show_end_of_buffer = false,
	term_colors = false,
	dim_inactive = {
		enabled = false,
		shade = "dark",
		percentage = 0.15,
	},
	no_italic = false,
	no_bold = false,
	no_underline = false,
	styles = {
		comments = { "italic" },
		conditionals = { "italic" },
		loops = {},
		functions = {},
		keywords = {},
		strings = {},
		variables = {},
		numbers = {},
		booleans = {},
		properties = {},
		types = {},
		operators = {},
	},
	color_overrides = {},
	custom_highlights = {},
	default_integrations = true,
	integrations = {
		cmp = true,
		gitsigns = true,
		nvimtree = true,
		treesitter = true,
		notify = false,
		mini = {
			enabled = true,
			indentscope_color = "",
		},
	},
})

vim.cmd.colorscheme("catppuccin")

-- Custom gitsigns highlight groups for staged vs unstaged
vim.api.nvim_create_autocmd("ColorScheme", {
	pattern = "*",
	callback = function()
		-- Unstaged changes (bright colors)
		vim.api.nvim_set_hl(0, "GitSignsAdd", { fg = "#a6e3a1" })
		vim.api.nvim_set_hl(0, "GitSignsChange", { fg = "#f9e2af" })
		vim.api.nvim_set_hl(0, "GitSignsDelete", { fg = "#f38ba8" })

		-- Staged changes (dimmer colors)
		vim.api.nvim_set_hl(0, "GitSignsAddStaged", { fg = "#74c7ec" })
		vim.api.nvim_set_hl(0, "GitSignsChangeStaged", { fg = "#fab387" })
		vim.api.nvim_set_hl(0, "GitSignsDeleteStaged", { fg = "#eba0ac" })
		vim.api.nvim_set_hl(0, "GitSignsTopDeleteStaged", { fg = "#eba0ac" })
		vim.api.nvim_set_hl(0, "GitSignsChangeDeleteStaged", { fg = "#eba0ac" })
	end,
	desc = "Set custom gitsigns colors for staged vs unstaged",
})

vim.cmd("doautocmd ColorScheme")

-- ======================================================================================
-- UI OPTIONS
-- ======================================================================================

-- Line numbers and display
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.wrap = false
vim.opt.autoindent = true
vim.opt.ttyfast = true
vim.opt.splitright = true

-- Status and command line
vim.opt.laststatus = 3 -- Global statusline
vim.opt.scrolloff = 7
vim.opt.wildmenu = true
vim.opt.wildmode = { "list", "longest" }
vim.opt.hidden = true
vim.opt.showcmd = true
vim.opt.showmode = false
vim.opt.title = true
vim.opt.showmatch = true
vim.opt.mat = 2
vim.opt.signcolumn = "yes"
vim.opt.shortmess = "atToOFcW" -- Suppress written messages
vim.opt.conceallevel = 0
vim.opt.cmdheight = 0 -- Hide command bar
vim.opt.breakindent = true
vim.opt.inccommand = "split"

-- Diff settings
vim.opt.diffopt:append({ "vertical", "iwhite", "internal", "algorithm:patience", "hiddenoff" })

-- Tab and indentation
vim.opt.smarttab = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.shiftround = true

-- Code folding
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldlevelstart = 99
vim.opt.foldnestmax = 10
vim.opt.foldenable = false
vim.opt.foldlevel = 1

-- Hide end-of-buffer characters
vim.opt.fillchars = { eob = " " }

-- ======================================================================================
-- KEYMAPS
-- ======================================================================================

-- Window navigation
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to bottom window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to top window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Better up/down for wrapped lines
vim.keymap.set("n", "j", "gj", { desc = "Move down (visual line)" })
vim.keymap.set("n", "k", "gk", { desc = "Move up (visual line)" })

-- Indentation
vim.keymap.set("v", "<", "<gv", { desc = "Indent left and reselect" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right and reselect" })

-- Repeat in visual mode
vim.keymap.set("v", ".", ":normal .<cr>", { desc = "Repeat last command" })

-- Tab management
vim.keymap.set("n", "<Leader>t", ":tabnew<CR>", { desc = "New tab" })
vim.keymap.set("n", "<Tab>", "gt", { desc = "Next tab" })
vim.keymap.set("n", "<S-Tab>", "gT", { desc = "Previous tab" })

-- Faster scrolling
vim.keymap.set("n", "<C-E>", "6<C-E>", { desc = "Scroll down faster" })
vim.keymap.set("n", "<C-Y>", "6<C-Y>", { desc = "Scroll up faster" })

-- Clear search highlights
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlights" })

-- ======================================================================================
-- LEADER KEY MAPPINGS
-- ======================================================================================

-- File operations
vim.keymap.set("n", "<Leader>w", ":w<CR>", { desc = "Save file" })
vim.keymap.set("n", "<Leader>W", ":wall<CR>", { desc = "Save all files" })
vim.keymap.set("n", "<Leader>q", ":q<CR>", { desc = "Quit" })
vim.keymap.set("n", "<Leader>Q", ":qall<CR>", { desc = "Quit all" })

-- Window splits
vim.keymap.set("n", "<Leader>v", ":vsplit<CR>", { desc = "Vertical split" })
vim.keymap.set("n", "<Leader>h", ":split<CR>", { desc = "Horizontal split" })

-- Telescope
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<Leader>p", builtin.find_files, { desc = "Find files" })
vim.keymap.set("n", "<Leader>f", builtin.live_grep, { desc = "Live grep" })
vim.keymap.set("n", "<Leader>b", builtin.buffers, { desc = "Find buffers" })
vim.keymap.set("n", "<Leader>gb", builtin.git_branches, { desc = "Git branches" })
vim.keymap.set("n", "<Leader>gc", builtin.git_commits, { desc = "Git commits" })
vim.keymap.set("n", "<Leader>gs", builtin.git_stash, { desc = "Git stash" })

-- File explorer
vim.keymap.set("n", "<Leader>e", ":Neotree<CR>", { desc = "File explorer" })

-- Diagnostics
vim.keymap.set("n", "<Leader>dn", function()
	vim.diagnostic.jump({ count = 1 })
end, { desc = "Next diagnostic" })
vim.keymap.set("n", "<Leader>dp", function()
	vim.diagnostic.jump({ count = -1 })
end, { desc = "Previous diagnostic" })
vim.keymap.set("n", "<Leader>dt", ":Trouble diagnostics toggle<CR>", { desc = "Toggle trouble diagnostics" })
vim.keymap.set("n", "<Leader>dd", ":Trouble diagnostics toggle filter.buf=0<CR>", { desc = "Buffer diagnostics" })

-- Obsidian
vim.keymap.set("n", "<Leader>x", ":ObsidianToggleCheckbox<CR>", { desc = "Toggle checkbox" })
vim.keymap.set("n", "<Leader>ot", ":ObsidianToday<CR>", { desc = "Today's note" })
vim.keymap.set("n", "<Leader>om", ":ObsidianTomorrow<CR>", { desc = "Tomorrow's note" })
vim.keymap.set("n", "<Leader>oy", ":ObsidianYesterday<CR>", { desc = "Yesterday's note" })
vim.keymap.set("n", "<Leader>oh", ":ObsidianTOC<CR>", { desc = "Table of contents" })
vim.keymap.set("n", "<Leader>or", ":ObsidianRename", { desc = "Rename note" })
vim.keymap.set("n", "<Leader>os", ":ObsidianSearch<CR>", { desc = "Search notes" })
vim.keymap.set("n", "<Leader>opi", ":ObsidianPasteImage<CR>", { desc = "Paste image" })
vim.keymap.set("n", "<Leader>on", ":ObsidianNew<CR>", { desc = "New note" })

-- Claude Code integration
vim.keymap.set("n", "<Leader>cc", ":ClaudeCodeDiagnostic<CR>", { desc = "Send diagnostic to Claude Code" })

-- ======================================================================================
-- FILETYPE EXTENSIONS
-- ======================================================================================

vim.g.do_filetype_lua = 1
vim.filetype.add({
	extension = {
		svx = "markdown",
		mdx = "markdown",
	},
})

-- ======================================================================================
-- ABBREVIATIONS
-- ======================================================================================

vim.cmd([[abbr funciton function]])
vim.cmd([[abbr teh the]])
vim.cmd([[abbr dockert docker]])

-- ======================================================================================
-- CUSTOM MODULES
-- ======================================================================================

require("testrunner")
require("claude-code")

-- ======================================================================================
-- CLAUDE CODE INTEGRATION
-- ======================================================================================

-- Create user command for Claude Code diagnostic integration
vim.api.nvim_create_user_command("ClaudeCodeDiagnostic", function()
	require("claude-code").send_diagnostic_to_claude()
end, {
	desc = "Send diagnostic at cursor to Claude Code for fixing suggestions",
})

-- Short alias for convenience
vim.api.nvim_create_user_command("CCDiagnostic", function()
	require("claude-code").send_diagnostic_to_claude()
end, {
	desc = "Send diagnostic at cursor to Claude Code for fixing suggestions",
})
