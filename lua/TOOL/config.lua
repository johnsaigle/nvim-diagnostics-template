local M = {}
local namespace = vim.api.nvim_create_namespace("TOOL-nvim")

-- Defaults
M.enabled = true
M.severity_map = {
	ERROR = vim.diagnostic.severity.ERROR,
	WARNING = vim.diagnostic.severity.WARN,
	INFO = vim.diagnostic.severity.INFO,
	HINT = vim.diagnostic.severity.HINT,
}
M.default_severity = vim.diagnostic.severity.WARN
M.extra_args = {}
M.filetypes = {}

function M.print_config()
	local config_lines = { "Current TOOL Configuration:" }
	for k, v in pairs(M) do
		if type(v) == "table" and type(k) == "string" then
			table.insert(config_lines, string.format("%s: %s", k, vim.inspect(v)))
		elseif type(k) == "string" then
			table.insert(config_lines, string.format("%s: %s", k, tostring(v)))
		end
	end
	vim.notify(table.concat(config_lines, "\n"), vim.log.levels.INFO)
end

function M.toggle()
	-- Toggle the enabled state
	M.enabled = not M.enabled
	if not M.enabled then
		-- Clear all diagnostics when disabling
		local bufs = vim.api.nvim_list_bufs()
		for _, buf in ipairs(bufs) do
			if vim.api.nvim_buf_is_valid(buf) then
				vim.diagnostic.reset(namespace, buf)
			end
		end
		vim.notify("TOOL diagnostics disabled", vim.log.levels.INFO)
	else
		vim.notify("TOOL diagnostics enabled", vim.log.levels.INFO)
		require('TOOL-diagnostics.scan').scan()
	end
end

-- Helper function to convert TOOL_config to a table if it's a string
function M.normalize_config(config)
	if type(config) == "string" then
		return { config }
	end
	return config
end

function M.on_attach(bufnr)
	local opts = { buffer = bufnr }

	-- TODO: Update keymaps for the new tool
	vim.keymap.set("n", "<leader>tt", function() M.toggle() end,
		vim.tbl_extend("force", opts, { desc = "[T]oggle TOOL diagnostics" }))

	vim.keymap.set("n", "<leader>tc", function() M.print_config() end,
		vim.tbl_extend("force", opts, { desc = "Print TOOL diagnostics [C]onfig" }))

	local TOOL = require('TOOL.scan')

	vim.keymap.set('n', '<leader>ts', function() TOOL.scan() end,
		vim.tbl_extend("force", opts, { desc = 'Run TOOL scan' }))

	vim.keymap.set('n', '<leader>tv', function()
		vim.ui.select(
			{ "ERROR", "WARN", "INFO", "HINT" },
			{
				prompt = "Select minimum severity level:",
				format_item = function(item)
					return string.format("%s (%d)", item, vim.diagnostic.severity[item])
				end,
			},
			function(choice)
				if choice then
					local severity = vim.diagnostic.severity[choice]
					M.set_minimum_severity(severity)
				end
			end
		)
	end, vim.tbl_extend("force", opts, { desc = "Set [s]emgrep minimum se[v]erity" }))
end

function M.set_minimum_severity(level)
	if not vim.tbl_contains(vim.tbl_values(vim.diagnostic.severity), level) then
		vim.notify("Invalid severity level", vim.log.levels.ERROR)
		return
	end
	M.config.default_severity = level
	vim.notify(string.format("Minimum severity set to: %s", level), vim.log.levels.INFO)
end

function M.setup(opts)
    if opts then
        local updated = vim.tbl_deep_extend("force", M, opts)
        for k, v in pairs(updated) do
            M[k] = v
        end
    end
end

return M
