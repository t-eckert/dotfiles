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

-- Format diagnostic and context for Claude Code
function M.format_for_claude_code(diagnostic, context, file_info)
	local severity_names = {
		[vim.diagnostic.severity.ERROR] = "ERROR",
		[vim.diagnostic.severity.WARN] = "WARNING",
		[vim.diagnostic.severity.INFO] = "INFO",
		[vim.diagnostic.severity.HINT] = "HINT",
	}

	local severity = severity_names[diagnostic.severity] or "UNKNOWN"
	local source = diagnostic.source or "LSP"

	-- Build the prompt
	local prompt_parts = {
		"I have a diagnostic issue in my code that I need help fixing:",
		"",
		string.format("**File**: %s", file_info.path),
		string.format("**Line**: %d", context.diagnostic_line),
		string.format("**Severity**: %s", severity),
		string.format("**Source**: %s", source),
		string.format("**Message**: %s", diagnostic.message),
		"",
		"**Code Context**:",
		"```" .. (file_info.filetype or ""),
	}

	-- Add line numbers and code
	for i, line in ipairs(context.lines) do
		local line_number = context.start_line + i - 1
		local marker = (line_number == context.diagnostic_line) and " <-- DIAGNOSTIC HERE" or ""
		table.insert(prompt_parts, string.format("%d: %s%s", line_number, line, marker))
	end

	table.insert(prompt_parts, "```")
	table.insert(prompt_parts, "")
	table.insert(
		prompt_parts,
		"Please analyze this diagnostic and suggest how to fix it. If you can provide a specific code fix, please do so."
	)

	return table.concat(prompt_parts, "\n")
end

-- Send formatted prompt to Claude Code
function M.send_to_claude_code(prompt)
	-- Create a temporary file with the prompt
	local temp_file = vim.fn.tempname() .. ".md"
	local lines = vim.split(prompt, "\n")

	-- Write prompt to temp file
	vim.fn.writefile(lines, temp_file)

	-- Open the temp file in a new buffer
	vim.cmd("vsplit " .. temp_file)

	-- Notify user
	vim.notify("Diagnostic context prepared for Claude Code", vim.log.levels.INFO, { title = "Claude Code" })

	-- Optional: Clean up temp file after a delay
	vim.defer_fn(function()
		if vim.fn.filereadable(temp_file) == 1 then
			vim.fn.delete(temp_file)
		end
	end, 30000) -- Clean up after 30 seconds
end

-- Main function to handle diagnostic and send to Claude Code
function M.send_diagnostic_to_claude()
	-- Get current file info
	local file_path = vim.fn.expand("%:p")
	local filetype = vim.bo.filetype

	if file_path == "" then
		vim.notify("No file open", vim.log.levels.WARN, { title = "Claude Code" })
		return
	end

	-- Get diagnostic at cursor
	local diagnostic, error_msg = M.get_diagnostic_at_cursor()
	if not diagnostic then
		vim.notify(error_msg or "No diagnostic found", vim.log.levels.WARN, { title = "Claude Code" })
		return
	end

	-- Get code context
	local context = M.get_code_context(diagnostic.lnum, 7) -- 7 lines before/after

	-- Prepare file info
	local file_info = {
		path = file_path,
		filetype = filetype,
	}

	-- Format and send
	local formatted_prompt = M.format_for_claude_code(diagnostic, context, file_info)
	M.send_to_claude_code(formatted_prompt)
end

return M

