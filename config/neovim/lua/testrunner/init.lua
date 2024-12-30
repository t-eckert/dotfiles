local test_ns = vim.api.nvim_create_namespace("testrunner")

-- Generic function to attach a test running command to an environment.
-- The attached command will run everytime a save event happens.
local attach_testrunner = function(buffer_number, pattern, test_command, options)
	local state = {
		buffer_number = buffer_number,
		tests = {}
	}

	local run_tests = function()
		vim.api.nvim_buf_clear_namespace(buffer_number, test_ns, 0, -1)

		state = {
			buffer_number = buffer_number,
			tests = {}
		}

		vim.fn.jobstart(test_command, options(state))
	end

	-- Run the tests once to start off.
	run_tests()

	-- Create the autocommand.
	vim.api.nvim_create_autocmd("BufWritePost", {
		group = vim.api.nvim_create_augroup(string.format("testrunner-%s", buffer_number), { clear=true }),
		pattern = pattern,
		callback = run_tests,
	})
end

-----------------------------------------------------------------------------------------------------------------------
-- Go -----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------

-- Use treesitter to find the line in the buffer matching the given test name.
local go_find_line = function(buffer_number, name)
	local query = vim.treesitter.parse_query("go", string.format([[
		(
			(function_declaration
				name: (identifier) @name
				parameters: (parameter_list (parameter_declaration 
					name: (identifier) 
					type: (pointer_type(qualified_type
						package: (package_identifier) @_package_name
						name: (type_identifier) @_type_name)))))

			(#eq? @_package_name "testing")
			(#eq? @_type_name "T")
			(#eq? @name "%s")	
		)
	]], name))
	local parser = vim.treesitter.get_parser(buffer_number, "go", {})
	local tree = parser:parse()[1]
	local root = tree:root()

	for id, node in query:iter_captures(root, buffer_number, 0, -1) do
		if id == 1 then
			local range = { node:range() }
			return range[1]
		end
	end
end

local go_buffer_number = 0
local go_pattern = "*.go"
local go_test_command = {"go", "test", "./...", "-v", "-json"}
local go_options = function(state)
	return {
		stdout_buffered = true,
		on_stdout = function(_, data)
			if not data then
				return
			end

			for _, line in ipairs(data) do
				local parsable, test_metadata = pcall(vim.json.decode, line)
				if parsable and test_metadata.Test then
					local test = {
						Package = test_metadata.Package,
						Name = test_metadata.Test,
						Action = test_metadata.Action,
						Line = go_find_line(state.buffer_number, test_metadata.Test),
					}

					if test.Action == "pass" then
						if test.Line then
							vim.api.nvim_buf_set_extmark(state.buffer_number, test_ns, test.Line, 0, {
								virt_text = {{ "✅" }}
							})
						end
					elseif test.Action == "fail" then
						if test.Line then
							vim.api.nvim_buf_set_extmark(state.buffer_number, test_ns, test.Line, 0, {
								virt_text = {{ "🟥" }}
							})
						end
					end
				end
			end
		end,
		on_exit = function()
			local failed = {}
			for _, test in pairs(state.tests) do
				if test.line then
					if not test.success then
						table.insert(failed, {
							bufnr = state.buffer_number,
							lnum = test.line,
							col = 0,
							severity = vim.diagnostic.severity.ERROR,
							source = "go-test",
							message = "Test Failed",
							user_data = {},
						})
					end
				end
			end

			vim.diagnostic.set(test_ns, state.buffer_number, failed, {})
		end,
	}
end

vim.api.nvim_create_user_command("AttachTestrunner", function ()
	attach_testrunner(go_buffer_number, go_pattern, go_test_command, go_options)
end, {})

