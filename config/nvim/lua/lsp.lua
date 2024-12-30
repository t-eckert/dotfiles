local navic = require("nvim-navic")

require('mason-lspconfig').setup({
	ensure_installed = {
		"rust_analyzer",
		"tsserver",
	}
})

local on_attach = function(client, bufnr)
	if client.server_capabilities.documentSymbolProvider then
		navic.attach(client, bufnr)
	end

	vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = 0 })
	vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = 0 })
	vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, { buffer = 0 })
	vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { buffer = 0 })
	vim.keymap.set("n", "<leader>dn", vim.diagnostic.goto_next, { buffer = 0 })
	vim.keymap.set("n", "<leader>dp", vim.diagnostic.goto_prev, { buffer = 0 })
	vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, { buffer = 0 })
end
local capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())

local lspconfig = require('lspconfig')
require('mason-lspconfig').setup_handlers({
	function(server_name)
		lspconfig[server_name].setup({
			on_attach = on_attach,
			capabilities = capabilities,
		})
	end,
})

require("lspconfig")["lua_ls"].setup {
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim" }
			}
		}
	}
}

vim.api.nvim_create_user_command("GoEnt", function()
	require("lspconfig")["gopls"].setup {
		settings = {
			gopls = {
				buildFlags = { "-tags=enterprise" }
			}
		}
	}
end, {})
