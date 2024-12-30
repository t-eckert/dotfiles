vim.opt.ignorecase = true       -- case insensitive searching
vim.opt.smartcase = true        -- case-sensitive if expression contains a capital letter
vim.opt.hlsearch = true         -- highlight search results
vim.opt.incsearch = true        -- incremental search
vim.opt.lazyredraw = false      -- don't redraw while executing macros
vim.opt.magic = true            -- use magic for regex

if vim.fn.executable("rg") then -- if ripgrep is installed
	vim.opt.grepprg = "rg --vimgrep --noheading"
	vim.opt.grepformat = "%f:%l:%c:%m,%f:%l:%m"
end
