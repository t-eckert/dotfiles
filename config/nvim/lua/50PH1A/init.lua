local M = {}


local options = {
	is_transparent = true,
	use_dim_inactive = true,
}

local colors = {
	none = "NONE",
	neutral_0 = "#FFFFFF",
	neutral_1 = "#FAFAFA",
	neutral_2 = "#F3F4F6",
	neutral_3 = "#D4D4D8",
	neutral_4 = "#a3a3a3",
	neutral_5 = "#737373",
	neutral_6 = "#525252",
	neutral_7 = "#262626",
	neutral_8 = "#18181B",
	neutral_9 = "#000000",
	red_light = "#ef4444",
	red_medium = "#dc2626",
	red_dark = "#450a0a",
	yellow_light = "#fbbf24",
	yellow_medium = "#f59e0b",
	yellow_dark = "#d97706",
	green_light = "#a7f3d0",
	green_medium = "#10b981",
	green_dark = "#052e16",
	blue_light = "#7dd3fc",
	blue_medium = "#38bdf8",
	blue_dark = "#0284c7",
	purple_light = "#c084fc",
	purple_medium = "#a855f7",
	purple_dark = "#9333ea",
}

local semantic_colors = {
	fg = colors.neutral_0,
	mg = colors.neutral_5,
	bg = colors.neutral_9,
	border = colors.neutral_7,
}

local c = colors
local sc = semantic_colors

local theme = {
	Cursor                     = { fg = sc.fg, bg = sc.bg },
	LineNr                     = { fg = sc.mg },
	SignColumn                 = { fg = c.neutral_7, bg = options.is_transparent and c.none or c.neutral_9 },
	Function                   = { fg = c.blue_light },
	Comment                    = { fg = c.neutral_4 },                                         -- any comment
	ColorColumn                = { bg = c.neutral_6 },                                         -- used for the columns set with 'colorcolumn'
	Conceal                    = { fg = c.neutral_6 },                                         -- placeholder characters substituted for concealed text (see 'conceallevel')
	lCursor                    = { fg = c.bg, bg = c.fg },                                     -- the character under the cursor when |language-mapping| is used (see 'guicursor')
	CursorIM                   = { fg = c.bg, bg = c.fg },                                     -- like Cursor, but used when in IME mode |CursorIM|
	CursorColumn               = { bg = c.neutral_8 },                                         -- Screen-column at the cursor, when 'cursorcolumn' is set.
	CursorLine                 = { bg = c.bg_highlight },                                      -- Screen-line at the cursor, when 'cursorline' is set.  Low-priority if foreground (ctermfg OR guifg) is not set.
	Directory                  = { fg = c.blue_light },                                        -- directory names (and other special names in listings)
	DiffAdd                    = { fg = c.green_light },                                       -- diff mode: Added line |diff.txt|
	DiffChange                 = { fg = c.yellow_light },                                      -- diff mode: Changed line |diff.txt|
	DiffDelete                 = { fg = c.red_light },                                         -- diff mode: Deleted line |diff.txt|
	DiffText                   = { fg = c.blue_light },                                        -- diff mode: Changed text within a changed line |diff.txt|
	EndOfBuffer                = { fg = sc.bg },                                               -- filler lines (~) after the end of the buffer.  By default, this is highlighted like |hl-NonText|.
	TermCursor                 = {},                                                           -- cursor in a focused terminal
	TermCursorNC               = {},                                                           -- cursor in an unfocused terminal
	ErrorMsg                   = { fg = c.red_medium },                                        -- error messages on the command line
	VertSplit                  = { fg = sc.border },                                           -- the column separating vertically split windows
	WinSeparator               = { fg = sc.border, bold = true },                              -- the column separating vertically split windows
	Folded                     = { fg = c.blue, bg = c.fg_gutter },                            -- line used for closed folds
	FoldColumn                 = { bg = options.transparent and c.none or c.bg, fg = c.comment }, -- 'foldcolumn'
	SignColumnSB               = { bg = c.bg_sidebar, fg = c.fg_gutter },                      -- column where |signs| are displayed
	Substitute                 = { bg = c.red, fg = c.black },                                 -- |:substitute| replacement text highlighting
	CursorLineNr               = { fg = sc.fg },                                               -- Like LineNr when 'cursorline' or 'relativenumber' is set for the cursor line.
	MatchParen                 = { fg = c.yellow_light, bold = true },                         -- The character under the cursor or just before it, if it is a paired bracket, and its match. |pi_paren.txt|
	ModeMsg                    = { fg = sc.fg, bold = true },                                  -- 'showmode' message (e.g., "-- INSERT -- ")
	MsgArea                    = { fg = sc.fg },                                               -- Area for messages and cmdline
	MsgSeparator               = {},                                                           -- Separator for scrolled messages, `msgsep` flag of 'display'
	MoreMsg                    = { fg = c.blue },                                              -- |more-prompt|
	NonText                    = { fg = c.dark3 },                                             -- '@' at the end of the window, characters from 'showbreak' and other characters that do not really exist in the text (e.g., ">" displayed when a double-wide character doesn't fit at the end of the line). See also |hl-EndOfBuffer|.
	Normal                     = { fg = sc.fg, bg = options.is_transparent and c.none or sc.bg }, -- normal text
	NormalNC                   = {
		fg = options.use_dim_inactive and c.neutral_2 or sc.fg,
		bg = options.is_transparent and c.none or sc.bg
	},                                                                                               -- normal text in non-current windows
	NormalSB                   = { fg = sc.fg, bg = sc.bg },                                         -- normal text in sidebar
	NormalFloat                = { fg = c.fg_float, bg = c.bg_float },                               -- Normal text in floating windows.
	FloatBorder                = { fg = c.border_highlight, bg = c.bg_float },
	Pmenu                      = { bg = c.bg_popup, fg = c.fg },                                     -- Popup menu: normal item.
	PmenuSel                   = { bg = sc.fg },                                                     -- Popup menu: selected item.
	PmenuSbar                  = { bg = c.bg_popup },                                                -- Popup menu: scrollbar.
	PmenuThumb                 = { bg = c.fg_gutter },                                               -- Popup menu: Thumb of the scrollbar.
	Question                   = { fg = c.blue },                                                    -- |hit-enter| prompt and yes/no questions
	QuickFixLine               = { bg = c.bg_visual, bold = true },                                  -- Current |quickfix| item in the quickfix window. Combined with |hl-CursorLine| when the cursor is there.
	Search                     = { bg = c.bg_search, fg = c.fg },                                    -- Last search pattern highlighting (see 'hlsearch').  Also used for similar items that need to stand out.
	IncSearch                  = { bg = c.orange, fg = c.black },                                    -- 'incsearch' highlighting; also used for the text replaced with ":s///c"
	CurSearch                  = { link = "IncSearch" },
	SpecialKey                 = { fg = c.dark3 },                                                   -- Unprintable characters: text displayed differently from what it really is.  But not 'listchars' whitespace. |hl-Whitespace|
	SpellBad                   = { sp = c.error, undercurl = true },                                 -- Word that is not recognized by the spellchecker. |spell| Combined with the highlighting used otherwise.
	SpellCap                   = { sp = c.warning, undercurl = true },                               -- Word that should start with a capital. |spell| Combined with the highlighting used otherwise.
	SpellLocal                 = { sp = c.info, undercurl = true },                                  -- Word that is recognized by the spellchecker as one that is used in another region. |spell| Combined with the highlighting used otherwise.
	SpellRare                  = { sp = c.hint, undercurl = true },                                  -- Word that is recognized by the spellchecker as one that is hardly ever used.  |spell| Combined with the highlighting used otherwise.
	StatusLine                 = { fg = sc.fg, bg = options.is_transparent and c.none or c.neutral_9 }, -- status line of current window
	StatusLineNC               = { fg = sc.fg, bg = sc.bg },                                         -- status lines of not-current windows Note: if this is equal to "StatusLine" Vim will use "^^^" in the status line of the current window.
	TabLine                    = { bg = sc.bg, fg = c.fg_gutter },                                   -- tab pages line, not active tab page label
	TabLineFill                = { bg = c.black },                                                   -- tab pages line, where there are no labels
	TabLineSel                 = { fg = c.black, bg = c.blue },                                      -- tab pages line, active tab page label
	Title                      = { fg = c.blue, bold = true },                                       -- titles for output from ":set all", ":autocmd" etc.
	Visual                     = { fg = c.neutral_9, bg = c.neutral_1 },                             -- Visual mode selection
	VisualNOS                  = { bg = c.neutral_6 },                                               -- Visual mode selection when vim is "Not Owning the Selection".
	WarningMsg                 = { fg = c.red_medium, bold = true },                                 -- warning messages
	Whitespace                 = { fg = c.neutral_3 },                                               -- "nbsp", "space", "tab" and "trail" in 'listchars'
	WildMenu                   = { bg = c.neutral_6, bold = true },                                  -- current match in 'wildmenu' completion

	-- These groups are not listed as default vim groups,
	-- but they are defacto standard group names for syntax highlighting.
	-- commented out groups should chain up to their "preferred" group by
	-- default,
	-- Uncomment and edit if you want more specific syntax highlighting.
	Constant                   = { fg = c.yellow_light, bold = true }, -- (preferred) any constant
	String                     = { fg = c.green_medium },           --   a string constant: "this is a string"
	Character                  = { fg = c.green_medium },           --  a character constant: 'c', '\n'
	Number                     = { fg = c.red_medium },             --   a number constant: 234, 0xff
	Boolean                    = { fg = c.yellow_light, bold = true }, --  a boolean constant: TRUE, false

	Identifier                 = { fg = sc.fg },                    -- (preferred) any variable name
	Statement                  = { fg = c.purple_light },           -- (preferred) any statement
	Conditional                = { fg = c.purple_light },           -- if, then, else, endif, switch, etc.
	Repeat                     = { fg = c.purple_light },           -- for, do, while, etc.
	Label                      = { fg = c.purple_light },           -- case, default, etc.
	Operator                   = { fg = c.blue_medium },            -- "sizeof", "+", "*", etc.
	Keyword                    = { fg = c.purple_light },           -- any other keyword
	Exception                  = { fg = c.red_medium },             -- try, catch, throw

	PreProc                    = { fg = sc.mg },                    -- (preferred) generic Preprocessor

	Type                       = { fg = c.purple_light },           -- (preferred) int, long, char, etc.
	StorageClass               = {},                                -- static, register, volatile, etc.
	Structure                  = { fg = c.purple_light },           -- struct, union, enum, etc.
	Typedef                    = { fg = c.purple_light },           -- A typedef

	Special                    = { fg = c.purple_medium },          -- (preferred) any special symbol
	SpecialChar                = {},                                -- special character in a constant
	Tag                        = {},                                -- you can use CTRL-] on this
	Delimiter                  = {},                                -- character that needs attention
	SpecialComment             = {},                                -- special things inside a comment
	Debug                      = {},                                -- debugging statements

	Underlined                 = { underline = true },              -- (preferred) text that stands out, HTML links
	Bold                       = { bold = true },
	Italic                     = { italic = true },

	Ignore                     = {},                                                                 -- (preferred) left blank, hidden  |hl-Ignore|

	Error                      = { fg = sc.fg, bg = c.red_medium },                                  -- (preferred) any erroneous construct
	Todo                       = { bg = c.yellow_light, fg = c.neutral_9, italic = true, bold = true }, -- (preferred) anything that needs extra attention; mostly the keywords TODO FIXME and XXX
	qfLineNr                   = { fg = c.dark5 },
	qfFileName                 = { fg = c.blue },
	htmlH1                     = { fg = c.magenta, bold = true },
	htmlH2                     = { fg = c.blue, bold = true },
	mkdHeading                 = { fg = c.orange, bold = true },
	mkdCode                    = { bg = c.terminal_black, fg = c.fg },
	mkdCodeDelimiter           = { bg = c.terminal_black, fg = c.fg },
	mkdCodeStart               = { fg = c.teal, bold = true },
	mkdCodeEnd                 = { fg = c.teal, bold = true },
	mkdLink                    = { fg = c.blue, underline = true },

	-- nvim-tree colors
	GitDirty                   = { bg = c.yellow_light },
	FolderIcon                 = { fg = c.red_medium },

	IndentBlanklineChar        = { fg = c.neutral_6 },
	IndentBlanklineContextChar = { fg = c.neutral_2 },

	-- markdownHeadingDelimiter = { fg = c.orange, bold = true },
	-- markdownCode = { fg = c.teal },
	-- markdownCodeBlock = { fg = c.teal },
	-- markdownH1 = { fg = c.magenta, bold = true },
	-- markdownH2 = { fg = c.blue, bold = true },
	-- markdownLinkText = { fg = c.blue, underline = true },
	-- ["helpCommand"] = { bg = c.terminal_black, fg = c.blue },
	-- debugPC = { bg = c.bg_sidebar },                                  -- used for highlighting the current line in terminal-debug
	-- debugBreakpoint = { bg = util.darken(c.info, 0.1), fg = c.info }, -- used for breakpoint colors in terminal-debug
	-- -- These groups are for the native LSP client. Some other LSP clients may
	-- -- use these groups, or use their own. Consult your LSP client's
	-- -- documentation.
	-- LspReferenceText = { bg = c.fg_gutter },                                          -- used for highlighting "text" references
	-- LspReferenceRead = { bg = c.fg_gutter },                                          -- used for highlighting "read" references
	-- LspReferenceWrite = { bg = c.fg_gutter },                                         -- used for highlighting "write" references
	-- DiagnosticError = { fg = c.error },                                               -- Used as the base highlight group. Other Diagnostic highlights link to this by default
	-- DiagnosticWarn = { fg = c.warning },                                              -- Used as the base highlight group. Other Diagnostic highlights link to this by default
	-- DiagnosticInfo = { fg = c.info },                                                 -- Used as the base highlight group. Other Diagnostic highlights link to this by default
	-- DiagnosticHint = { fg = c.hint },                                                 -- Used as the base highlight group. Other Diagnostic highlights link to this by default
	-- DiagnosticVirtualTextError = { bg = util.darken(c.error, 0.1), fg = c.error },    -- Used for "Error" diagnostic virtual text
	-- DiagnosticVirtualTextWarn = { bg = util.darken(c.warning, 0.1), fg = c.warning }, -- Used for "Warning" diagnostic virtual text
	-- DiagnosticVirtualTextInfo = { bg = util.darken(c.info, 0.1), fg = c.info },       -- Used for "Information" diagnostic virtual text
	-- DiagnosticVirtualTextHint = { bg = util.darken(c.hint, 0.1), fg = c.hint },       -- Used for "Hint" diagnostic virtual text
	-- DiagnosticUnderlineError = { undercurl = true, sp = c.error },                    -- Used to underline "Error" diagnostics
	-- DiagnosticUnderlineWarn = { undercurl = true, sp = c.warning },                   -- Used to underline "Warning" diagnostics
	-- DiagnosticUnderlineInfo = { undercurl = true, sp = c.info },                      -- Used to underline "Information" diagnostics
	-- DiagnosticUnderlineHint = { undercurl = true, sp = c.hint },                      -- Used to underline "Hint" diagnostics
	-- LspSignatureActiveParameter = { bg = util.darken(c.bg_visual, 0.4), bold = true },
	-- LspCodeLens = { fg = c.comment },
	-- LspInfoBorder = { fg = c.border_highlight, bg = c.bg_float },
	-- ALEErrorSign = { fg = c.error },
	-- ALEWarningSign = { fg = c.warning },
}

local function load()
	if vim.g.colors_name then
		vim.cmd("hi clear")
	end

	vim.o.termguicolors = true
	vim.g.colors_name = "50PH1A"

	for group, hl in pairs(theme) do
		vim.api.nvim_set_hl(0, group, hl)
	end
end

function M.setup()
	load()
end

load()

return M
