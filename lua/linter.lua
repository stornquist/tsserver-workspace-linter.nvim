local M = {}

---@alias ListOptions "quickfix"|"trouble"

---@class PluginOptions
---@field auto_open? boolean
---@field list? ListOptions

---@type PluginOptions
local default_options = {
	auto_open = true,
	list = "quickfix",
}

---@param opts PluginOptions
M.setup = function(opts)
	local status, lspconfig = pcall(require, "lspconfig")
	if not status then
		print("lspconfig not found")
	end

	if not lspconfig["tsserver"] then
		print("make sure tsserver is installed and setup before loading tsserver-workspace-lint")
	else
		local options = vim.tbl_deep_extend("force", default_options, opts or {})

		lspconfig["tsserver"].setup({
			on_attach = function(client, bufnr)
				local original = lspconfig["tsserver"].manager.config.capabilities.on_attach
				vim.api.nvim_buf_create_user_command(0, "Tsc", function()
					local workspaceRoot =
						vim.lsp.get_active_clients({ bufnr = 0, name = "tsserver" })[1].config.root_dir

					-- since tsc gives relative paths, we need to change the cwd to the workspace root
					local oldCwd = vim.fn.getcwd()
					vim.fn.chdir(workspaceRoot)

					vim.api.nvim_command(":compiler tsc | setlocal makeprg=npx\\ tsc")
					vim.api.nvim_command(":make")

					-- change back to old cwd
					vim.fn.chdir(oldCwd)

					if not options.auto_open then
						return
					end

					local quckfixEntries = vim.fn.getqflist()
					if #quckfixEntries == 0 then
						print("No typescript errors found")
						return
					end

					for i = #quckfixEntries, 1, -1 do
						if not quckfixEntries[i].valid then
							table.remove(quckfixEntries, i)
						end
					end

					if options.list == "quickfix" then
						vim.api.nvim_command(":copen")
					end

					if options.list == "trouble" and require("trouble") then
						require("trouble").open({ mode = "quickfix" })
					end
				end, { nargs = 0 })
				original(client, bufnr)
			end,
		})
	end
end

return M
