-- Neovim Configuration

-- =====================================================================================================================
-- Functions and Autocommands
-- =====================================================================================================================

-- Schedule a sync of the OS clipboard after `UiEnter`.
vim.schedule(function()
	vim.opt.clipboard = "unnamedplus"
end)

-- Returns true if a file exists.
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

-- Highlight when yanking text.
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking text",
	group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- =====================================================================================================================
-- Options
-- =====================================================================================================================

-- Turn off some configuration I don't generally need.
vim.opt.backup = false -- Don't make a backup before overwriting a file.
vim.opt.writebackup = false -- Don't backup file while editing.
vim.opt.swapfile = false -- Don't write swap files for new buffers.
vim.opt.updatecount = 0 -- Don't write swap files after some number of updates.

vim.opt.undofile = true -- Save undo history.

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

vim.opt.history = 1000 -- store the last 1000 commands entered

vim.opt.backspace = { "indent", "eol,start" } -- make backspace behave like I want
vim.opt.clipboard = { "unnamed", "unnamedplus" } -- use the system clipboard
vim.opt.mouse = "a" -- set mouse mode to all modes

-- Ignore case in searching unless \C or one of more capital letters is found in the search term.
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true -- highlight search results
vim.opt.incsearch = true -- incremental search
vim.opt.lazyredraw = false -- don't redraw while executing macros
vim.opt.magic = true -- use magic for regex

if vim.fn.executable("rg") then -- if ripgrep is installed
	vim.opt.grepprg = "rg --vimgrep --noheading" -- use RG for searching
	vim.opt.grepformat = "%f:%l:%c:%m,%f:%l:%m"
end

-- =====================================================================================================================
-- Plugins
-- =====================================================================================================================

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

require("lazy").setup({
	spec = {
		-- Language Support
		{ "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
		-- Neotree
		{
			"nvim-neo-tree/neo-tree.nvim",
			branch = "v3.x",
			dependencies = {
				"nvim-lua/plenary.nvim",
				"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
				"MunifTanjim/nui.nvim",
				-- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
			},
		},
		-- Helper functions for Lua
		"nvim-lua/plenary.nvim",
		-- Vertical indent lines
		{
			"lukas-reineke/indent-blankline.nvim",
			main = "ibl",
			---@module "ibl"
			---@type ibl.config
			opts = {},
		},
		-- Autocompletion
		{
			"hrsh7th/nvim-cmp",
			event = "InsertEnter",
			dependencies = {
				-- Snippet Engine & its associated nvim-cmp source
				{
					"L3MON4D3/LuaSnip",
					build = (function()
						-- Build Step is needed for regex support in snippets.
						-- This step is not supported in many windows environments.
						-- Remove the below condition to re-enable on windows.
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
						-- Select the next item
						["<TAB>"] = cmp.mapping.select_next_item(),
						-- Select the previous item
						["<S-TAB>"] = cmp.mapping.select_prev_item(),

						-- Accept the completion.
						--  This will auto-import if your LSP supports it.
						--  This will expand snippets if the LSP sent a snippet.
						["<CR>"] = cmp.mapping.confirm({ select = true }),

						-- Manually trigger a completion from nvim-cmp.
						--  Generally you don't need this, because nvim-cmp will display
						--  completions whenever it has completion options available.
						["<C-Space>"] = cmp.mapping.complete({}),

						-- Think of <c-l> as moving to the right of your snippet expansion.
						--  So if you have a snippet that's like:
						--  function $name($args)
						--    $body
						--  end
						--
						-- <c-l> will move you to the right of each of the expansion locations.
						-- <c-h> is similar, except moving you backwards.
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
						{
							name = "lazydev",
							-- set group index to 0 to skip loading LuaLS completions as lazydev recommends it
							group_index = 0,
						},
						{ name = "nvim_lsp" },
						{ name = "luasnip" },
						{ name = "path" },
					},
				})

				-- Set configuration for specific filetype.
				cmp.setup.filetype("gitcommit", {
					sources = cmp.config.sources({
						{ name = "cmp_git" },
					}, {
						{ name = "buffer" },
					}),
				})

				-- Use buffer source for `/`.
				cmp.setup.cmdline("/", {
					mapping = cmp.mapping.preset.cmdline(),
					sources = {
						{ name = "buffer" },
					},
				})

				-- Use cmdline & path source for ':'.
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
		-- `lazydev` configures lua lsp for your neovim config, runtime and plugins
		-- used for completion, annotations and signatures of neovim apis
		{
			"folke/lazydev.nvim",
			ft = "lua",
			opts = {
				library = {
					-- load luvit types when the `vim.uv` word is found
					{ path = "luvit-meta/library", words = { "vim%.uv" } },
				},
			},
		},
		-- LSP for Lua
		{ "bilal2453/luvit-meta", lazy = true },
		-- LSP
		{
			"neovim/nvim-lspconfig",
			dependencies = {
				-- Automatically install lsps and related tools to stdpath for neovim
				{ "williamboman/mason.nvim", config = true }, -- note: must be loaded before dependants
				"williamboman/mason-lspconfig.nvim",
				"whoissethdaniel/mason-tool-installer.nvim",

				-- useful status updates for lsp.
				-- note: `opts = {}` is the same as calling `require('fidget').setup({})`
				{ "j-hui/fidget.nvim", opts = {} },

				-- allows extra capabilities provided by nvim-cmp
				"hrsh7th/cmp-nvim-lsp",
			},
			config = function()
				-- brief aside: **what is lsp?**
				--
				-- lsp is an initialism you've probably heard, but might not understand what it is.
				--
				-- lsp stands for language server protocol. it's a protocol that helps editors
				-- and language tooling communicate in a standardized fashion.
				--
				-- in general, you have a "server" which is some tool built to understand a particular
				-- language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). these language servers
				-- (sometimes called lsp servers, but that's kind of like atm machine) are standalone
				-- processes that communicate with some "client" - in this case, neovim!
				--
				-- lsp provides neovim with features like:
				--  - go to definition
				--  - find references
				--  - autocompletion
				--  - symbol search
				--  - and more!
				--
				-- thus, language servers are external tools that must be installed separately from
				-- neovim. this is where `mason` and related plugins come into play.
				--
				-- if you're wondering about lsp vs treesitter, you can check out the wonderfully
				-- and elegantly composed help section, `:help lsp-vs-treesitter`

				--  this function gets run when an lsp attaches to a particular buffer.
				--    that is to say, every time a new file is opened that is associated with
				--    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
				--    function will be executed to configure the current buffer
				vim.api.nvim_create_autocmd("lspattach", {
					group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
					callback = function(event)
						-- note: remember that lua is a real programming language, and as such it is possible
						-- to define small helper and utility functions so you don't have to repeat yourself.
						--
						-- in this case, we create a function that lets us more easily define mappings specific
						-- for lsp related items. it sets the mode, buffer and description for us each time.
						local map = function(keys, func, desc, mode)
							mode = mode or "n"
							vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "lsp: " .. desc })
						end

						-- jump to the definition of the word under your cursor.
						--  this is where a variable was first declared, or where a function is defined, etc.
						--  to jump back, press <c-t>.
						map("gd", vim.lsp.buf.definition, "[g]oto [d]efinition")

						-- find references for the word under your cursor.
						map("gr", vim.lsp.buf.references, "[g]oto [r]eferences")

						-- jump to the implementation of the word under your cursor.
						--  useful when your language has ways of declaring types without an actual implementation.
						map("gi", vim.lsp.buf.implementation, "[g]oto [i]mplementation")

						-- jump to the type of the word under your cursor.
						--  useful when you're not sure what type a variable is and you want to see
						--  the definition of its *type*, not where it was *defined*.
						map("gt", vim.lsp.buf.type_definition, "[g]oto [t]ype definition")

						-- fuzzy find all the symbols in your current document.
						--  symbols are things like variables, functions, types, etc.
						map("<Leader>ds", require("telescope.builtin").lsp_document_symbols, "[d]ocument [s]ymbols")

						-- fuzzy find all the symbols in your current workspace.
						--  similar to document symbols, except searches over your entire project.
						map(
							"<Leader>ws",
							require("telescope.builtin").lsp_dynamic_workspace_symbols,
							"[w]orkspace [s]ymbols"
						)

						-- rename the variable under your cursor.
						--  most language servers support renaming across files, etc.
						map("<Leader>r", vim.lsp.buf.rename, "[r]ename")

						-- execute a code action, usually your cursor needs to be on top of an error
						-- or a suggestion from your lsp for this to activate.
						map("<Leader>ca", vim.lsp.buf.code_action, "[c]ode [a]ction", { "n", "x" })
					end,
				})

				-- change diagnostic symbols in the sign column (gutter)
				-- if vim.g.have_nerd_font then
				--   local signs = { error = '', warn = '', info = '', hint = '' }
				--   local diagnostic_signs = {}
				--   for type, icon in pairs(signs) do
				--     diagnostic_signs[vim.diagnostic.severity[type]] = icon
				--   end
				--   vim.diagnostic.config { signs = { text = diagnostic_signs } }
				-- end

				-- lsp servers and clients are able to communicate to each other what features they support.
				--  by default, neovim doesn't support everything that is in the lsp specification.
				--  when you add nvim-cmp, luasnip, etc. neovim now has *more* capabilities.
				--  so, we create new capabilities with nvim cmp, and then broadcast that to the servers.
				local capabilities = vim.lsp.protocol.make_client_capabilities()
				capabilities =
					vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

				-- enable the following language servers
				--  feel free to add/remove any lsps that you want here. they will automatically be installed.
				--
				--  add any additional override configuration in the following tables. available keys are:
				--  - cmd (table): override the default command used to start the server
				--  - filetypes (table): override the default list of associated filetypes for the server
				--  - capabilities (table): override fields in capabilities. can be used to disable certain lsp features.
				--  - settings (table): override the default settings passed when initializing the server.
				--        for example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
				local servers = {
					-- clangd = {},
					-- gopls = {},
					-- pyright = {},
					-- rust_analyzer = {},
					-- ... etc. see `:help lspconfig-all` for a list of all the pre-configured lsps
					--
					-- some languages (like typescript) have entire language plugins that can be useful:
					--    https://github.com/pmizio/typescript-tools.nvim
					--
					-- but for many setups, the lsp (`ts_ls`) will work just fine
					-- ts_ls = {},
					--

					lua_ls = {
						-- cmd = { ... },
						-- filetypes = { ... },
						-- capabilities = {},
						settings = {
							lua = {
								completion = {
									callsnippet = "replace",
								},
								-- you can toggle below to ignore lua_ls's noisy `missing-fields` warnings
								-- diagnostics = { disable = { 'missing-fields' } },
							},
						},
					},
				}

				-- ensure the servers and tools above are installed
				--  to check the current status of installed tools and/or manually install
				--  other tools, you can run
				--    :mason
				--
				--  you can press `g?` for help in this menu.
				require("mason").setup()

				-- you can add other tools here that you want mason to install
				-- for you, so that they are available from within neovim.
				local ensure_installed = vim.tbl_keys(servers or {})
				vim.list_extend(ensure_installed, {
					"stylua", -- used to format lua code
				})
				require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

				require("mason-lspconfig").setup({
					ensure_installed = { "lua_ls", "rust_analyzer" },
					automatic_installation = true,
					handlers = {
						function(server_name)
							local server = servers[server_name] or {}
							-- this handles overriding only values explicitly passed
							-- by the server configuration above. useful when disabling
							-- certain features of an lsp (for example, turning off formatting for ts_ls)
							server.capabilities =
								vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
							require("lspconfig")[server_name].setup(server)
						end,
					},
				})
			end,
		},
		-- Fuzzy finder (files, lsp, etc)
		{
			"nvim-telescope/telescope.nvim",
			event = "vimenter",
			branch = "0.1.x",
			dependencies = {
				"nvim-lua/plenary.nvim",
				{ -- if encountering errors, see telescope-fzf-native readme for installation instructions
					"nvim-telescope/telescope-fzf-native.nvim",

					-- `build` is used to run some command when the plugin is installed/updated.
					-- this is only run then, not every time neovim starts up.
					build = "make",

					-- `cond` is a condition used to determine whether this plugin should be
					-- installed and loaded.
					cond = function()
						return vim.fn.executable("make") == 1
					end,
				},
				{ "nvim-telescope/telescope-ui-select.nvim" },

				-- useful for getting pretty icons, but requires a nerd font.
				{ "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
			},
			config = function()
				-- telescope is a fuzzy finder that comes with a lot of different things that
				-- it can fuzzy find! it's more than just a "file finder", it can search
				-- many different aspects of neovim, your workspace, lsp, and more!
				--
				-- the easiest way to use telescope, is to start by doing something like:
				--  :telescope help_tags
				--
				-- after running this command, a window will open up and you're able to
				-- type in the prompt window. you'll see a list of `help_tags` options and
				-- a corresponding preview of the help.
				--
				-- two important keymaps to use while in telescope are:
				--  - insert mode: <c-/>
				--  - normal mode: ?
				--
				-- this opens a window that shows you all of the keymaps for the current
				-- telescope picker. this is really useful to discover what telescope can
				-- do as well as how to actually do it!

				-- [[ Configure Telescope ]]
				-- See `:help telescope` and `:help telescope.setup()`
				require("telescope").setup({
					-- You can put your default mappings / updates / etc. in here
					--  All the info you're looking for is in `:help telescope.setup()`
					--
					-- defaults = {
					--   mappings = {
					--     i = { ['<c-enter>'] = 'to_fuzzy_refine' },
					--   },
					-- },
					-- pickers = {}
					extensions = {
						["ui-select"] = {
							require("telescope.themes").get_dropdown(),
						},
					},
				})

				-- Enable Telescope extensions if they are installed
				pcall(require("telescope").load_extension, "fzf")
				pcall(require("telescope").load_extension, "ui-select")

				-- See `:help telescope.builtin`
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

				-- Slightly advanced example of overriding default behavior and theme
				vim.keymap.set("n", "<leader>/", function()
					-- You can pass additional configuration to Telescope to change the theme, layout, etc.
					builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
						winblend = 10,
						previewer = false,
					}))
				end, { desc = "[/] Fuzzily search in current buffer" })

				-- It's also possible to pass additional configuration options.
				--  See `:help telescope.builtin.live_grep()` for information about particular keys
				vim.keymap.set("n", "<leader>s/", function()
					builtin.live_grep({
						grep_open_files = true,
						prompt_title = "Live Grep in Open Files",
					})
				end, { desc = "[S]earch [/] in Open Files" })

				-- Shortcut for searching your Neovim configuration files
				vim.keymap.set("n", "<leader>sn", function()
					builtin.find_files({ cwd = vim.fn.stdpath("config") })
				end, { desc = "[S]earch [N]eovim files" })
			end,
		},
		-- Colorscheme
		{ "catppuccin/nvim", name = "catppuccin", priority = 1000 },
		-- Detect tabstop and shiftwidth automatically
		"tpope/vim-sleuth",
		-- Svelte
		"evanleck/vim-svelte",
		-- Astro
		"wuelnerdotexe/vim-astro",
		-- Better Git Support
		"tpope/vim-fugitive",
		-- Highlighting for Git Merge Conflics
		{ "akinsho/git-conflict.nvim", version = "*", config = true },
		-- Automatically pair braces
		{
			"windwp/nvim-autopairs",
			event = "InsertEnter",
			config = true,
			-- use opts = {} for passing setup options
			-- this is equivalent to setup({}) function
		},
		-- Adds git related signs to the gutter, as well as utilities for managing changes
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
			},
		},
		-- Autoformat
		{
			"stevearc/conform.nvim",
			event = { "BufWritePre" },
			cmd = { "ConformInfo" },
			keys = {
				{
					"<leader>f",
					function()
						require("conform").format({ async = true, lsp_format = "fallback" })
					end,
					mode = "",
					desc = "[F]ormat buffer",
				},
			},
			opts = {
				notify_on_error = false,
				format_on_save = function(bufnr)
					-- Disable "format_on_save lsp_fallback" for languages that don't
					-- have a well standardized coding style. You can add additional
					-- languages here or re-enable it for the disabled ones.
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
		-- Highlight todo, notes, etc in comments
		{
			"folke/todo-comments.nvim",
			event = "VimEnter",
			dependencies = { "nvim-lua/plenary.nvim" },
			opts = { signs = false },
		},
		{ -- Collection of various small independent plugins/modules
			"echasnovski/mini.nvim",
			config = function()
				-- Better Around/Inside textobjects
				--
				-- Examples:
				--  - va)  - [V]isually select [A]round [)]paren
				--  - yinq - [Y]ank [I]nside [N]ext [Q]uote
				--  - ci'  - [C]hange [I]nside [']quote
				require("mini.ai").setup({ n_lines = 500 })

				-- Add/delete/replace surroundings (brackets, quotes, etc.)
				--
				-- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
				-- - sd'   - [S]urround [D]elete [']quotes
				-- - sr)'  - [S]urround [R]eplace [)] [']
				require("mini.surround").setup()

				-- Simple and easy statusline.
				--  You could remove this setup call if you don't like it,
				--  and try some other statusline plugin
				local statusline = require("mini.statusline")
				-- set use_icons to true if you have a Nerd Font
				statusline.setup({ use_icons = vim.g.have_nerd_font })

				-- You can configure sections in the statusline by overriding their
				-- default behavior. For example, here we set the section for
				-- cursor location to LINE:COLUMN
				---@diagnostic disable-next-line: duplicate-set-field
				statusline.section_location = function()
					return "%2l:%-2v"
				end

				-- ... and there is more!
				--  Check out: https://github.com/echasnovski/mini.nvim
			end,
		},
		-- Oil file manager
		{
			"stevearc/oil.nvim",
			---@module 'oil'
			---@type oil.SetupOpts
			opts = {},
			-- Optional dependencies
			dependencies = { { "echasnovski/mini.icons", opts = {} } },
		},
		-- Obsidian
		{
			"t-eckert/obsidian.nvim",
			branch = "t-eckert/add-set-checkbox",
			lazy = true,
			ft = "markdown",
			dependencies = {
				"nvim-lua/plenary.nvim",
			},
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
					folder = "./~Templates",
				},
			},
		},
	},
	checker = { enabled = true },
	lockfile = "~/Repos/github.com/t-eckert/dotfiles/config/nvim/lazy-lock.json",
})

-- =====================================================================================================================
-- Appearance
-- =====================================================================================================================

require("catppuccin").setup({
	flavour = "mocha", -- latte, frappe, macchiato, mocha
	background = { -- :h background
		light = "latte",
		dark = "mocha",
	},
	transparent_background = true, -- disables setting the background color.
	show_end_of_buffer = false, -- shows the '~' characters after the end of buffers
	term_colors = false, -- sets terminal colors (e.g. `g:terminal_color_0`)
	dim_inactive = {
		enabled = false, -- dims the background color of inactive window
		shade = "dark",
		percentage = 0.15, -- percentage of the shade to apply to the inactive window
	},
	no_italic = false, -- Force no italic
	no_bold = false, -- Force no bold
	no_underline = false, -- Force no underline
	styles = { -- Handles the styles of general hi groups (see `:h highlight-args`):
		comments = { "italic" }, -- Change the style of comments
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
		-- miscs = {}, -- Uncomment to turn off hard-coded styles
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
		-- For more plugins integrations please scroll down (https://github.com/catppuccin/nvim#integrations)
	},
})

-- setup must be called before loading
vim.cmd.colorscheme("catppuccin")

vim.opt.number = true -- show line numbers
vim.opt.relativenumber = true -- use relative line numbers
vim.opt.wrap = false -- don't use line wrapping
vim.opt.autoindent = true -- automatically set the indent of new lines
vim.opt.ttyfast = true -- faster redrawing
vim.opt.splitright = true -- new windows will split right

vim.opt.laststatus = 3 -- show the global statusline all the time
vim.opt.scrolloff = 7 -- set 7 lines to the cursors - when moving vertically
vim.opt.wildmenu = true -- enhanced command line completion
vim.opt.wildmode = { "list", "longest" } -- complete files like a shell
vim.opt.hidden = true -- current buffer can be put into background
vim.opt.showcmd = true -- show incomplete commands
vim.opt.showmode = false -- don't show mode
vim.opt.title = true -- set terminal title
vim.opt.showmatch = true -- show matching braces
vim.opt.mat = 2 -- how many tenths of a second to blink
vim.opt.updatetime = 300 -- timeout to write to swap file
vim.opt.signcolumn = "yes" -- add a sign column to the left
vim.opt.shortmess = "atToOFc" -- prompt message options
vim.opt.conceallevel = 0 -- show text that has been concealed
vim.opt.cmdheight = 0 -- Hide the command bar
vim.opt.breakindent = true -- Preserve horizontal blocks of text.
vim.opt.inccommand = "split" -- Preview substitutions live.

-- Diff settings
table.insert(vim.opt.diffopt, "vertical")
table.insert(vim.opt.diffopt, "iwhite")
table.insert(vim.opt.diffopt, "internal")
table.insert(vim.opt.diffopt, "algorithm:patience")
table.insert(vim.opt.diffopt, "hiddenoff")

-- tab control
vim.opt.smarttab = true -- tab respects 'tabstop', 'shiftwidth', and 'softtabstop'
vim.opt.tabstop = 4 -- the visible width of tabs
vim.opt.softtabstop = 4 -- edit as if the tabs are 4 characters wide
vim.opt.shiftwidth = 4 -- number of spaces to use for indent and unindent
vim.opt.shiftround = true -- round indent to a multiple of 'shiftwidth'

-- code folding settings
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldlevelstart = 99
vim.opt.foldnestmax = 10 -- deepest fold is 10 levelsz
vim.opt.foldenable = false -- don't fold by default
vim.opt.foldlevel = 1

vim.opt.fcs = "eob: " -- hide the ~ character on empty lines at end of buffer

-- =====================================================================================================================
-- Keymaps
-- =====================================================================================================================

-- Move between panes with CTRL+<dir>.
vim.api.nvim_set_keymap("n", "<C-h>", "<C-w>h", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<C-j>", "<C-w>j", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<C-k>", "<C-w>k", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<C-l>", "<C-w>l", { noremap = true, silent = true })

-- Indent and unindent can be chained.
vim.api.nvim_set_keymap("v", "<", "<gv", { silent = true })
vim.api.nvim_set_keymap("v", ">", ">gv", { silent = true })

-- Repeat last command even in visual mode.
vim.api.nvim_set_keymap("v", ".", ":normal .<cr>", { silent = true })

-- Change tabs with <TAB>.
vim.api.nvim_set_keymap("n", "<TAB>", "gt", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<S-TAB>", "gT", { noremap = true, silent = true })

-- Scroll the viewport faster
vim.api.nvim_set_keymap("n", "<C-E>", "6<C-E>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<C-Y>", "6<C-Y>", { noremap = true, silent = true })

-- Clear search highlights on <ESC>.
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Leader shortcuts
vim.g.mapleader = " " -- Set leader key to space.
vim.g.maplocalleader = " " -- Set local leader key to space.
-- Write file with _+w.
vim.api.nvim_set_keymap("n", "<Leader>w", ":w<CR>", { noremap = true, silent = true })
-- Write all files with _+W.
vim.api.nvim_set_keymap("n", "<Leader>W", ":wall<CR>", { noremap = true, silent = true })
-- Close a file with _+q.
vim.api.nvim_set_keymap("n", "<Leader>q", ":q<CR>", { noremap = true, silent = true })
-- Close all files with _+Q.
vim.api.nvim_set_keymap("n", "<Leader>Q", ":qall<CR>", { noremap = true, silent = true })
-- Split with _+v and _+h.
vim.api.nvim_set_keymap("n", "<Leader>v", ":vsplit<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<Leader>h", ":split<CR>", { noremap = true, silent = true })
-- Telescope
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<Leader>p", builtin.find_files, { desc = "Telescope find files", noremap = true, silent = true })
vim.keymap.set("n", "<Leader>f", builtin.live_grep, { desc = "Telescope live grep", noremap = true, silent = true })
vim.keymap.set("n", "<Leader>b", builtin.buffers, { desc = "Telescope buffers", noremap = true, silent = true })
vim.keymap.set(
	"n",
	"<Leader>gb",
	builtin.git_branches,
	{ desc = "Telescope Git Branches", noremap = true, silent = true }
)
vim.keymap.set(
	"n",
	"<Leader>gc",
	builtin.git_commits,
	{ desc = "Telescope Git Commits", noremap = true, silent = true }
)
vim.keymap.set("n", "<Leader>gs", builtin.git_stash, { desc = "Telescope Git Stash", noremap = true, silent = true })
-- Neotree
vim.keymap.set("n", "<Leader>e", ":Neotree<CR>", { noremap = true, silent = true })
-- Diagnostics
vim.keymap.set("n", "<Leader>dn", vim.diagnostic.goto_next, { buffer = 0 })
vim.keymap.set("n", "<Leader>dp", vim.diagnostic.goto_prev, { buffer = 0 })
-- Obsidian
vim.keymap.set("n", "<Leader>x", ":ObsidianToggleCheckbox<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<Leader>o", ":<Nop>", { noremap = true, silent = true })
vim.keymap.set("n", "<Leader>ot", ":ObsidianToday<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<Leader>om", ":ObsidianTomorrow<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<Leader>oy", ":ObsidianYesterday<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<Leader>oh", ":ObsidianTOC<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<Leader>or", ":ObsidianRename", { noremap = true, silent = true })
vim.keymap.set("n", "<Leader>os", ":ObsidianSearch<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<Leader>opi", ":ObsidianPasteImage<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<Leader>on", ":ObsidianNew<CR>", { noremap = true, silent = true })

-- =====================================================================================================================
-- Extend Filetypes
-- =====================================================================================================================

vim.g.do_filetype_lua = 1
vim.filetype.add({
	extension = {
		svx = "markdown",
		mdx = "markdown",
	},
})

-- =====================================================================================================================
-- Completion
-- =====================================================================================================================

local cmp = require("cmp")

cmp.setup({
	mapping = {
		-- Accept currently selected item with <Tab>
		-- Set `select = true` to confirm even if there's no explicit selection
		["<Tab>"] = cmp.mapping.confirm({ select = true }),

		-- Optional: If you want Shift+Tab to navigate backward in the list
		["<S-Tab>"] = cmp.mapping.select_prev_item(),
	},
})

-- =====================================================================================================================
-- Autoreplace
-- =====================================================================================================================
vim.cmd([[abbr funciton function]])
vim.cmd([[abbr teh the]])
vim.cmd([[abbr dockert docker]])

-- =====================================================================================================================
-- Imports
-- =====================================================================================================================

require("testrunner")

-- =====================================================================================================================
-- CVA
-- =====================================================================================================================

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
