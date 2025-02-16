local M = {}

local TOOL = require('TOOL.scan')
local config = require('TOOL.config')

-- TODO
function M.setup(opts)
	config.setup(opts)

	local group = vim.api.nvim_create_augroup("TOOLDiagnostics", { clear = true })
	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		pattern = config.filetypes,
		callback = function(args)
			config.on_attach(args.buf)
		end,
	})

	if config.enabled then
		TOOL.scan()
	end
end

-- Re-export the config for other modules to use
M.config = config

return M
