local theme = {
  fill = { fg = "#f2e9de", bg = "#000000" },
  head = "TabLine",
  current_tab = { fg = "#569fba", bg = "#000000" },
  tab = { fg = "#374151", bg = "#000000" },
  win = "TabLine",
  tail = "TabLine",
}

return {
  "nanozuki/tabby.nvim",
  event = "VimEnter",
  config = function()
    require("tabby.tabline").set(function(line)
      return {
        line.tabs().foreach(function(tab)
          local hl = tab.is_current() and theme.current_tab or theme.tab
          return {
            line.sep("", hl, theme.fill),
            tab.name(),
            line.sep("", hl, theme.fill),
            hl = hl,
            margin = " ",
          }
        end),
        hl = theme.fill,
      }
    end)
  end,
}
