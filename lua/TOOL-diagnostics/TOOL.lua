local M = {}

local namespace = nil
local config = require('TOOL.config')

-- Check for necessary fields from the JSON response.
local function is_valid_diagnostic(result)
end

-- Scan and populate diagnostics with the results.
function M.scan()
	local null_ls_ok, null_ls = pcall(require, "null-ls")
	if not null_ls_ok then
		vim.notify("null-ls is required for TOOL", vim.log.levels.ERROR)
		return
	end

	local TOOL_generator = {
		method = null_ls.methods.DIAGNOSTICS,
		filetypes = config.filetypes,
		generator = {
			-- Configure when to run the diagnostics
			runtime_condition = function()
				return config.enabled
			end,
			fn = function(params)
				-- Get executable path
				local cmd = ""
				local tool_path = vim.fn.exepath("TOOL")
				if tool_path == "" then
					vim.notify("TOOL executable not found in PATH", vim.log.levels.ERROR)
				else
					cmd = "TOOL"
				end

				local filepath = vim.api.nvim_buf_get_name(params.bufnr)

				-- Build command arguments.
				local args = {
					-- "--json",
					-- "--quiet",
				}

				-- Add filepath
				table.insert(args, filepath)

				-- Add any extra arguments
				for _, arg in ipairs(config.extra_args) do
					table.insert(args, arg)
				end

				-- Create async system command
				local full_cmd = vim.list_extend({ cmd }, args)

				-- Debugging
				-- TODO check nil when creating the file handle
				local f = io.open("/tmp/nvim_debug_TOOL.log", "a")
				f:write(vim.inspect(vim.fn.join(full_cmd, " ")) .. "\n")
				f:close()

				vim.system(
					full_cmd,
					{
						text = true,
						cwd = vim.fn.getcwd(),
						env = vim.env,
					},
					function(obj)
						local diags = {}
						-- Parse JSON output
						local ok, parsed = pcall(vim.json.decode, obj.stdout)
						if ok and parsed then
							-- Debugging
							local f = io.open("/tmp/nvim_debug.log", "a")
							f:write(vim.inspect(parsed) .. "\n")
							f:close()

							-- Convert results to diagnostics
							for _, result in ipairs(parsed.results) do
								if is_valid_diagnostic(result) then
									-- TODO update for the severity level in the source JSON
									local severity = result.extra.severity and
									    config.severity_map[result.extra.severity] or
									    config.default_severity

									-- Build the diagnostic message with rule information
									local message = result.extra.message
									if result.check_id then
										message = string.format("%s [%s]",
											message,
											result.check_id
										)
									end

									local diag = {
										lnum = result.start.line - 1,
										col = result.start.col - 1,
										end_lnum = result["end"].line - 1,
										end_col = result["end"].col - 1,
										source = "TOOL",
										message = message,
										severity = severity,
										-- Store additional metadata in user_data
										user_data = {
											-- rule_id = result.check_id,
											-- -- this will show which config file contained the rule
											-- rule_source = result.path,
											-- rule_details = {
											-- 	category = result.extra.metadata and
											-- 	    result.extra.metadata
											-- 	    .category,
											-- 	technology = result.extra
											-- 	    .metadata and
											-- 	    result.extra.metadata
											-- 	    .technology,
											-- 	confidence = result.extra
											-- 	    .metadata and
											-- 	    result.extra.metadata
											-- 	    .confidence,
											-- 	references = result.extra
											-- 	    .metadata and
											-- 	    result.extra.metadata
											-- 	    .references
											-- }
										}
									}
									table.insert(diags, diag)
								end
							end

							-- Schedule the diagnostic updates
							vim.schedule(function()
								namespace = vim.api.nvim_create_namespace(
									"TOOL-nvim")
								vim.diagnostic.set(namespace, params.bufnr, diags)
							end)
						end
					end
				)

				return {}
			end
		}
	}

	null_ls.register(TOOL_generator)
end

return M
