local theme = {
	fill = { fg = '#f2e9de', bg = '#000000', style = 'italic' },
	head = 'TabLine',
	current_tab = { fg = '#569fba', bg = '#000000' },
	tab = { fg = '#F8FBF6', bg = '#000000', style = 'italic' },
	win = 'TabLine',
	tail = 'TabLine',
}

require('tabby.tabline').set(function(line)
	return {
		line.tabs().foreach(function(tab)
			local hl = tab.is_current() and theme.current_tab or theme.tab
			return {
				line.sep('', hl, theme.fill),
				tab.name(),
				line.sep('', hl, theme.fill),
				hl = hl,
				margin = ' ',
			}
		end),
		hl = theme.fill,
	}
end)
