-- ======================================================================================
-- HAMMERSPOON CONFIGURATION
-- ======================================================================================

-- Disable animation for faster window management
hs.window.animationDuration = 0

-- ======================================================================================
-- WINDOW MANAGEMENT
-- ======================================================================================

-- Window movement keybindings (Cmd+Ctrl+Arrow)
hs.hotkey.bind({ "cmd", "ctrl" }, "Left", function()
	local win = hs.window.focusedWindow()
	local f = win:frame()
	local screen = win:screen()
	local max = screen:frame()

	f.x = max.x
	f.y = max.y
	f.w = max.w / 2
	f.h = max.h
	win:setFrame(f)
end)

hs.hotkey.bind({ "cmd", "ctrl" }, "Right", function()
	local win = hs.window.focusedWindow()
	local f = win:frame()
	local screen = win:screen()
	local max = screen:frame()

	f.x = max.x + (max.w / 2)
	f.y = max.y
	f.w = max.w / 2
	f.h = max.h
	win:setFrame(f)
end)

hs.hotkey.bind({ "cmd", "ctrl" }, "Up", function()
	local win = hs.window.focusedWindow()
	local f = win:frame()
	local screen = win:screen()
	local max = screen:frame()

	f.x = max.x
	f.y = max.y
	f.w = max.w
	f.h = max.h / 2
	win:setFrame(f)
end)

hs.hotkey.bind({ "cmd", "ctrl" }, "Down", function()
	local win = hs.window.focusedWindow()
	local f = win:frame()
	local screen = win:screen()
	local max = screen:frame()

	f.x = max.x
	f.y = max.y + (max.h / 2)
	f.w = max.w
	f.h = max.h / 2
	win:setFrame(f)
end)

-- Maximize window (Cmd+Ctrl+M)
hs.hotkey.bind({ "cmd", "ctrl" }, "M", function()
	local win = hs.window.focusedWindow()
	win:maximize()
end)

-- Center window (Cmd+Ctrl+C)
hs.hotkey.bind({ "cmd", "ctrl" }, "C", function()
	local win = hs.window.focusedWindow()
	win:centerOnScreen()
end)

-- ======================================================================================
-- APPLICATION LAUNCHER
-- ======================================================================================

-- Quick app launcher (Cmd+Ctrl+Key)
local appHotkeys = {
	T = "Ghostty", -- Terminal
	B = "Arc", -- Browser
	F = "Finder", -- File manager
	S = "Spotify", -- Music
	N = "Obsidian", -- Notes
	V = "Visual Studio Code", -- Code editor (alternative)
}

for key, app in pairs(appHotkeys) do
	hs.hotkey.bind({ "cmd", "ctrl" }, key, function()
		hs.application.launchOrFocus(app)
	end)
end

-- ======================================================================================
-- CONFIGURATION RELOAD
-- ======================================================================================

-- Auto-reload config when file changes
function reloadConfig(files)
	local doReload = false
	for _, file in pairs(files) do
		if file:sub(-4) == ".lua" then
			doReload = true
		end
	end
	if doReload then
		hs.reload()
	end
end

local myWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()
hs.alert.show("Hammerspoon Config Loaded")

-- Reload config manually (Cmd+Ctrl+R)
hs.hotkey.bind({ "cmd", "ctrl" }, "R", function()
	hs.reload()
end)

