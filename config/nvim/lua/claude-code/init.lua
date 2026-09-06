local M = {}

-- Get diagnostic at cursor position or current line
function M.get_diagnostic_at_cursor()
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local line_num = cursor_pos[1] - 1 -- Convert to 0-indexed
	local col_num = cursor_pos[2]

	-- Get diagnostics for current buffer at current line
	local diagnostics = vim.diagnostic.get(0, { lnum = line_num })

	if #diagnostics == 0 then
		-- No diagnostics on current line, try to get any diagnostic in buffer
		local all_diagnostics = vim.diagnostic.get(0)
		if #all_diagnostics == 0 then
			return nil, "No diagnostics found in current buffer"
		end
		-- Return the first diagnostic as fallback
		return all_diagnostics[1], nil
	end

	-- If multiple diagnostics on line, prefer the one closest to cursor column
	local best_diagnostic = diagnostics[1]
	local min_distance = math.abs(diagnostics[1].col - col_num)

	for _, diagnostic in ipairs(diagnostics) do
		local distance = math.abs(diagnostic.col - col_num)
		if distance < min_distance then
			min_distance = distance
			best_diagnostic = diagnostic
		end
	end

	return best_diagnostic, nil
end

-- Get code context around a specific line
function M.get_code_context(line_num, context_lines)
	context_lines = context_lines or 5
	local buf = vim.api.nvim_get_current_buf()
	local total_lines = vim.api.nvim_buf_line_count(buf)

	-- Calculate start and end lines (convert to 0-indexed)
	local start_line = math.max(0, line_num - context_lines)
	local end_line = math.min(total_lines, line_num + context_lines + 1)

	-- Get the lines
	local lines = vim.api.nvim_buf_get_lines(buf, start_line, end_line, false)

	return {
		lines = lines,
		start_line = start_line + 1, -- Convert back to 1-indexed for display
		end_line = end_line,
		diagnostic_line = line_num + 1, -- Convert to 1-indexed
	}
end

-- ======================================================================================
-- HEADLESS FIX
--
-- <leader>cc hands the diagnostic to a headless `claude -p` run, which edits the
-- files itself. The report pane only opens when there is something worth reading:
-- a fix that was not trivial, a diagnostic that could not be fixed, or a run that
-- fell over. An obvious fix reports itself in one notify line and nothing else.
--
-- The verdict comes back as JSON so that call is the model's to make, rather than
-- something guessed at from the size of the diff.
-- ======================================================================================

-- Where the report lands when there is one. A stable path, not a tempname, so a
-- Claude Code session on this machine can also just read it — the editor runs
-- behind zellij and mosh, where an OSC 52 clipboard write does not survive the
-- trip out to the Mac.
M.output_path = vim.fn.expand("~/.claude/nvim-diagnostic.md")

M.opts = {
	cmd = "claude",
	timeout_ms = 5 * 60 * 1000,
	context_lines = 7,
}

M._running = false

local function notify(msg, level)
	vim.notify(msg, level or vim.log.levels.INFO, { title = "Claude Code" })
end

-- Format the diagnostic block that gets handed to the model
function M.format_diagnostic(diagnostic, context, file_info)
	local severity_names = {
		[vim.diagnostic.severity.ERROR] = "ERROR",
		[vim.diagnostic.severity.WARN] = "WARNING",
		[vim.diagnostic.severity.INFO] = "INFO",
		[vim.diagnostic.severity.HINT] = "HINT",
	}

	local parts = {
		string.format("**File**: %s", file_info.path),
		string.format("**Line**: %d", context.diagnostic_line),
		string.format("**Severity**: %s", severity_names[diagnostic.severity] or "UNKNOWN"),
		string.format("**Source**: %s", diagnostic.source or "LSP"),
		string.format("**Message**: %s", diagnostic.message),
		"",
		"**Code Context**:",
		"```" .. (file_info.filetype or ""),
	}

	for i, line in ipairs(context.lines) do
		local n = context.start_line + i - 1
		local marker = (n == context.diagnostic_line) and " <-- DIAGNOSTIC HERE" or ""
		table.insert(parts, string.format("%d: %s%s", n, line, marker))
	end

	table.insert(parts, "```")
	return table.concat(parts, "\n")
end

local FIX_INSTRUCTIONS = [[

Fix this diagnostic. Read whatever else you need in order to understand it first.

Constraints:
- Change only what this diagnostic requires. No unrelated edits, no reformatting
  of untouched code, no drive-by cleanup.
- If the diagnostic is a false positive, or a limitation of the tooling rather
  than a defect in the code, change nothing and say so.
- If fixing it properly needs a decision that is not yours to make, change
  nothing and explain what the choice is.

Then reply with ONLY a JSON object, with no prose around it:

{
  "outcome":  "fixed" | "not-fixed" | "false-positive",
  "trivial":  true | false,
  "summary":  "one line, under 100 characters",
  "detail":   "markdown: what you changed and why, or why you did not",
  "files":    ["paths you edited, relative to the project root"]
}

Set "trivial" to true only when the fix was small, obvious and certainly
correct. It suppresses the report entirely and the summary line is all I will
see, so anything I would want to check afterwards is not trivial.
]]

-- Pull the verdict object out of the reply, which arrives fenced more often than not
local function parse_verdict(text)
	if not text or text == "" then
		return nil
	end

	local body = text:match("```%s*json%s*\n(.-)```") or text:match("```%s*\n(.-)```") or text

	local ok, decoded = pcall(vim.json.decode, body)
	if not ok then
		local first = body:find("{")
		local from_end = body:reverse():find("}")
		if not first or not from_end then
			return nil
		end
		ok, decoded = pcall(vim.json.decode, body:sub(first, #body - from_end + 1))
	end

	if ok and type(decoded) == "table" and decoded.outcome then
		return decoded
	end
	return nil
end

local function write_report(verdict, raw, file_info)
	local parts = {
		"# Claude Code fix attempt",
		"",
		string.format("**File**: `%s`", file_info.path),
	}

	if verdict then
		table.insert(parts, string.format("**Outcome**: %s", verdict.outcome))
		if verdict.summary then
			table.insert(parts, string.format("**Summary**: %s", verdict.summary))
		end
		if type(verdict.files) == "table" and #verdict.files > 0 then
			table.insert(parts, "")
			table.insert(parts, "**Files changed**:")
			for _, f in ipairs(verdict.files) do
				table.insert(parts, "- `" .. f .. "`")
			end
		end
		table.insert(parts, "")
		table.insert(parts, verdict.detail or "")
	else
		-- Unparseable reply: show it verbatim rather than swallowing it
		table.insert(parts, "**Outcome**: could not parse the reply")
		table.insert(parts, "")
		table.insert(parts, raw or "(no output)")
	end

	local out = M.output_path
	vim.fn.mkdir(vim.fn.fnamemodify(out, ":h"), "p")
	vim.fn.writefile(vim.split(table.concat(parts, "\n"), "\n"), out)
	return out
end

local function open_report(path)
	vim.cmd("vsplit " .. vim.fn.fnameescape(path))
	vim.bo.filetype = "markdown"
end

local function on_finished(result, file_info)
	M._running = false

	-- Claude edited files on disk; pull those changes into the open buffers
	vim.cmd("checktime")

	if result.code ~= 0 then
		local err = (result.stderr ~= "" and result.stderr) or result.stdout or "no output"
		local body = "The `claude` run failed (exit " .. tostring(result.code) .. "):\n\n```\n" .. err .. "\n```"
		write_report(nil, body, file_info)
		notify("Fix run failed — see the report", vim.log.levels.ERROR)
		open_report(M.output_path)
		return
	end

	local decoded_ok, envelope = pcall(vim.json.decode, result.stdout)
	local text = (decoded_ok and type(envelope) == "table" and envelope.result) or result.stdout
	local verdict = parse_verdict(text)

	-- The one case that stays quiet
	if verdict and verdict.outcome == "fixed" and verdict.trivial == true then
		notify("Fixed: " .. (verdict.summary or "done"))
		return
	end

	local path = write_report(verdict, text, file_info)
	if verdict then
		notify(verdict.outcome .. ": " .. (verdict.summary or ""), vim.log.levels.WARN)
	else
		notify("Reply could not be parsed — see the report", vim.log.levels.WARN)
	end
	open_report(path)
end

-- Main entry point: diagnostic at cursor -> headless fix -> report only if useful
function M.send_diagnostic_to_claude()
	if M._running then
		notify("A fix is already running", vim.log.levels.WARN)
		return
	end

	local file_path = vim.fn.expand("%:p")
	if file_path == "" then
		notify("No file open", vim.log.levels.WARN)
		return
	end

	if vim.fn.executable(M.opts.cmd) ~= 1 then
		notify("`" .. M.opts.cmd .. "` is not on PATH", vim.log.levels.ERROR)
		return
	end

	local diagnostic, err = M.get_diagnostic_at_cursor()
	if not diagnostic then
		notify(err or "No diagnostic found", vim.log.levels.WARN)
		return
	end

	local file_info = { path = file_path, filetype = vim.bo.filetype }
	local context = M.get_code_context(diagnostic.lnum, M.opts.context_lines)
	local prompt = M.format_diagnostic(diagnostic, context, file_info) .. "\n" .. FIX_INSTRUCTIONS

	-- Run from the project root, so the model gets the repo's CLAUDE.md and can
	-- reach sibling files
	local root = vim.fs.root(0, { ".git" }) or vim.fn.getcwd()

	M._running = true
	notify("Fixing: " .. diagnostic.message:gsub("\n.*", ""):sub(1, 60) .. "…")

	vim.system({
		M.opts.cmd,
		"-p",
		"--output-format",
		"json",
		"--permission-mode",
		"acceptEdits",
	}, {
		stdin = prompt,
		cwd = root,
		text = true,
		timeout = M.opts.timeout_ms,
	}, function(result)
		vim.schedule(function()
			on_finished(result, file_info)
		end)
	end)
end

-- Write the diagnostic writeup to a file and open it, without calling the model.
-- The escape hatch for handing an error to a Claude Code session by hand.
function M.write_diagnostic()
	local file_path = vim.fn.expand("%:p")
	if file_path == "" then
		notify("No file open", vim.log.levels.WARN)
		return
	end

	local diagnostic, err = M.get_diagnostic_at_cursor()
	if not diagnostic then
		notify(err or "No diagnostic found", vim.log.levels.WARN)
		return
	end

	local file_info = { path = file_path, filetype = vim.bo.filetype }
	local context = M.get_code_context(diagnostic.lnum, M.opts.context_lines)

	local out = M.output_path
	vim.fn.mkdir(vim.fn.fnamemodify(out, ":h"), "p")
	vim.fn.writefile(vim.split(M.format_diagnostic(diagnostic, context, file_info), "\n"), out)
	notify("Diagnostic written to " .. out)
	open_report(out)
end

return M
