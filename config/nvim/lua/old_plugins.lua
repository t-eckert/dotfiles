local fn = vim.fn
local plugLoad = fn["functions#PlugLoad"]
local plugBegin = fn["plug#begin"]
local plugEnd = fn["plug#end"]
local Plug = fn["plug#"]

plugLoad()
plugBegin("~/.config/nvim/plugged")

Plug("nvim-lualine/lualine.nvim") -- Status line
Plug("nanozuki/tabby.nvim") -- Tabline
Plug("SmiteshP/nvim-navic") -- Breadcrumbs
Plug("ray-x/guihua.lua") -- GUI management

-- Debugging
Plug("mfussenegger/nvim-dap") -- DAP
Plug("rcarriga/nvim-dap-ui") -- DAP UI
Plug("leoluz/nvim-dap-go") -- Go support
Plug("theHamsta/nvim-dap-virtual-text")
Plug("nvim-telescope/telescope-dap.nvim")

-- Snippets
Plug("github/copilot.vim") -- Copilot
Plug("hrsh7th/nvim-cmp") -- Completion
Plug("hrsh7th/cmp-nvim-lsp") -- Completion LSP
Plug("hrsh7th/cmp-buffer") -- Completion buffer
Plug("hrsh7th/cmp-path") -- Path for CMP
Plug("hrsh7th/cmp-cmdline") -- Command line for CMP
Plug("L3MON4D3/LuaSnip") -- Snippet engine
Plug("saadparwaiz1/cmp_luasnip") -- Engine plugin for CMP
Plug("aca/emmet-ls") -- Emmet completion

-- Formatting and code visuals
Plug("gpanders/editorconfig.nvim") -- Editorconfig
Plug("norcalli/nvim-colorizer.lua") -- Show hex colors

Plug("psf/black") -- Python formatter
Plug("fatih/vim-go") -- Go support
Plug("ray-x/go.nvim") -- More Go support
Plug("simrat39/rust-tools.nvim") -- Rust support
Plug("JulesWang/css.vim") -- CSS support
Plug("alexlafroscia/postcss-syntax.vim") -- PostCSS syntax highlighting
Plug("stephenway/postcss.vim") -- PostCSS support
Plug("JoosepAlviste/nvim-ts-context-commentstring") -- TS comment context
Plug("gregsexton/MatchTag", { ["for"] = "html" }) -- match tags in html
Plug("othree/html5.vim", { ["for"] = "html" }) -- html5 support
Plug("pangloss/vim-javascript") -- Javascript support
Plug("mzlogin/vim-markdown-toc") -- Markdown table of contents
Plug("HerringtonDarkholme/yats.vim") -- Typescript support

plugEnd()

-- Initialize the one-liner setups
require("nvim-autopairs").setup()
require("mason").setup()
require("go").setup()
vim.g.rustfmt_autosave = 1
require("dap-go").setup({
	delve = { path = "/usr/local/bin/dlv" },
})
require("nvim-navic").setup()
require("gitsigns").setup()
require("colorizer").setup()

-- Rust tools
local rt = require("rust-tools")

rt.setup({
	server = {
		on_attach = function(_, bufnr)
			-- Hover actions
			vim.keymap.set("n", "<C-space>", rt.hover_actions.hover_actions, { buffer = bufnr })
			-- Code action groups
			vim.keymap.set("n", "<Leader>a", rt.code_action_group.code_action_group, { buffer = bufnr })
		end,
	},
})
