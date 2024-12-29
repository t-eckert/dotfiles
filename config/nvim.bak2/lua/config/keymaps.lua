-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local cmd = vim.cmd
local g = vim.g
local fn = vim.fn
local api = vim.api
local utils = {}

_GlobalCallbacks = _GlobalCallbacks or {}
_G.globals = { _store = _GlobalCallbacks }

function globals._create(f)
  table.insert(globals._store, f)
  return #globals._store
end

function globals._execute(id, args)
  globals._store[id](args)
end

_G.completion_nvim = {}

function _G.completion_nvim.smart_pumvisible(vis_seq, not_vis_seq)
  if vim.fn.pumvisible() == 1 then
    return utils.termcodes(vis_seq)
  else
    return utils.termcodes(not_vis_seq)
  end
end

-- Useful for debugging.
function _G.put(...)
  local objects = {}
  for i = 1, select("#", ...) do
    local v = select(i, ...)
    table.insert(objects, vim.inspect(v))
  end

  print(table.concat(objects, "\n"))
  return ...
end

local function make_keymap_fn(mode, o)
  local parent_opts = vim.deepcopy(o)
  return function(combo, mapping, opts)
    assert(combo ~= mode, string.format("The combo should not be the same as the mode for %s", combo))
    local _opts = opts and vim.deepcopy(opts) or {}

    if type(mapping) == "function" then
      local fn_id = globals._create(mapping)
      mapping = string.format("<cmd>lua globals._execute(%s)<cr>", fn_id)
    end

    if _opts.bufnr then
      local bufnr = _opts.bufnr
      _opts.bufnr = nil
      _opts = vim.tbl_extend("keep", _opts, parent_opts)
      api.nvim_buf_set_keymap(bufnr, mode, combo, mapping, _opts)
    else
      api.nvim_set_keymap(mode, combo, mapping, vim.tbl_extend("keep", _opts, parent_opts))
    end
  end
end

local map_opts = { noremap = false, silent = true }
utils.nmap = make_keymap_fn("n", map_opts)
utils.xmap = make_keymap_fn("x", map_opts)
utils.imap = make_keymap_fn("i", map_opts)
utils.vmap = make_keymap_fn("v", map_opts)
utils.omap = make_keymap_fn("o", map_opts)
utils.tmap = make_keymap_fn("t", map_opts)
utils.smap = make_keymap_fn("s", map_opts)
utils.cmap = make_keymap_fn("c", map_opts)

local noremap_opts = { noremap = true, silent = true }
utils.nnoremap = make_keymap_fn("n", noremap_opts)
utils.xnoremap = make_keymap_fn("x", noremap_opts)
utils.vnoremap = make_keymap_fn("v", noremap_opts)
utils.inoremap = make_keymap_fn("i", noremap_opts)
utils.onoremap = make_keymap_fn("o", noremap_opts)
utils.tnoremap = make_keymap_fn("t", noremap_opts)
utils.cnoremap = make_keymap_fn("c", noremap_opts)

function utils.has_map(map, mode)
  mode = mode or "n"
  return fn.maparg(map, mode) ~= ""
end

function utils.has_module(name)
  if pcall(function()
    require(name)
  end) then
    return true
  else
    return false
  end
end

function utils.termcodes(str)
  return api.nvim_replace_termcodes(str, true, true, true)
end

function utils.file_exists(name)
  local f = io.open(name, "r")
  return f ~= nil and io.close(f)
end

local nmap = utils.nmap
local vmap = utils.vmap
local xmap = utils.xmap
local omap = utils.omap
local nnoremap = utils.nnoremap
local inoremap = utils.inoremap
local vnoremap = utils.vnoremap

--------------------------------------------------------------------------------
-- General Mappings ------------------------------------------------------------
--------------------------------------------------------------------------------
-- Indent/unindent
vmap("<", "<gv")
vmap(">", ">gv")

-- Repeat last command even in visual mode
vmap(".", ":normal .<cr>")

-- Save with CTRL+S
nnoremap("<silent> <C-S>", ":update<CR>")
vnoremap("<silent> <C-S>", "<C-C>:update<CR>")
inoremap("<silent> <C-S>", "<C-O>:update<CR>")

-- Move panes with CTRL+direction
nnoremap("<C-J>", "<C-W>j")
nnoremap("<C-K>", "<C-W>k")
nnoremap("<C-L>", "<C-W>l")
nnoremap("<C-H>", "<C-W>h")

-- Change tabs with tab
nnoremap("<TAB>", "gt")
nnoremap("<S-TAB>", "gT")

-- Scroll the viewport faster
nnoremap("<C-e>", "6<c-e>")
nnoremap("<C-y>", "6<c-y>")

-- Moving up and down work as you would expect
nnoremap("j", 'v:count == 0 ? "gj" : "j"', { expr = true })
nnoremap("k", 'v:count == 0 ? "gk" : "k"', { expr = true })
nnoremap("^", 'v:count == 0 ? "g^" :  "^"', { expr = true })
nnoremap("$", 'v:count == 0 ? "g$" : "$"', { expr = true })

-- Custom text objects
xmap("il", ":<c-u>normal! g_v^<cr>") --inner-line
omap("il", ":<c-u>normal! g_v^<cr>")
vmap("al", ":<c-u>normal! $v0<cr>") -- around line
omap("al", ":<c-u>normal! $v0<cr>")

-- LSP navigation
nnoremap("K", vim.lsp.buf.hover)
nnoremap("gd", vim.lsp.buf.definition)
nnoremap("gt", vim.lsp.buf.type_definition)
nnoremap("gi", vim.lsp.buf.implementation)

nnoremap("Q", "<nop>") -- Normal Mode: Unset Shift-Q

nnoremap("K", vim.lsp.buf.hover)
nnoremap("gd", vim.lsp.buf.definition)
nnoremap("gt", vim.lsp.buf.type_definition)
nnoremap("gi", vim.lsp.buf.implementation)

if utils.file_exists(fn.expand("~/.vimrc_background")) then
  g.base16colorspace = 256
  cmd([[source ~/.vimrc_background]])
end

-- Debugging
nnoremap("<F5>", ":lua require'dap'.continue()<CR>")
nnoremap("<F10>", ":lua require'dap'.step_over()<CR>")
nnoremap("<F11>", ":lua require'dap'.step_into()<CR>")
nnoremap("<F12>", ":lua require'dap'.step_out()<CR>")

--------------------------------------------------------------------------------
-- Leader Mappings -------------------------------------------------------------
--------------------------------------------------------------------------------
g.mapleader = " "
g.maplocalleader = " "

nnoremap("<leader>v", ":vsplit<CR>") -- Vertical split
nnoremap("<leader>h", ":split<CR>") -- Horizontal split

nnoremap("<leader>w", ":w<CR>") -- Save
nnoremap("<leader>q", ":q<CR>") -- Quit buffer
nnoremap("<leader>Q", ":wqall<CR>") -- Write all buffers and quit

nmap("<leader>t", ":tab sb<CR>") -- Open current buffer in a new tab

nnoremap("<leader>n", "o<esc>I- [ ] <esc>") -- Create task
nnoremap("<leader>x", "^elrx<ESC>") -- Cross off a task

nnoremap("<leader>a", ":nohl<CR>") -- Clear search highlight

nmap("<leader>p", ":Telescope find_files<CR>") -- Search files
nmap("<leader>f", ":Telescope live_grep<CR>") -- Grep files
nmap("<leader>g", ":Telescope git_branches<CR>") -- Change branches

nnoremap("<leader>dn", vim.diagnostic.goto_next) -- Goto next diagnostic
nnoremap("<leader>dp", vim.diagnostic.goto_prev) -- Goto previous diagnostic

nnoremap("<leader>b", ":lua require'dap'.toggle_breakpoint()<CR>") -- Toggle breakpoint
nnoremap("<leader>B", ":lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint Condition |> '))<CR>") -- Set breakpoint with condition

nnoremap("<leader>r", vim.lsp.buf.rename) -- Rename current token

nnoremap("<leader>s", ":so %<CR>") -- Source the current file
nnoremap("<leader>o", ":ToggleColumnColor<CR>") -- Toggle highlighting columns 80 and 120
